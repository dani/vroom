#!/usr/bin/env perl

# This file is part of the VROOM project
# released under the MIT licence
# Copyright 2014 Firewall Services
# Daniel Berteaud <daniel@firewall-services.com>

use lib 'lib';
use Mojolicious::Lite;
use Mojolicious::Plugin::Mail;
use Mojolicious::Plugin::Database;
use Vroom::Constants;
use Crypt::SaltedHash;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64;
use File::stat;
use File::Basename;
use Etherpad::API;
use Session::Token;
use Config::Simple;
use Email::Valid;
use URI;
use Protocol::SocketIO::Handshake;
use Protocol::SocketIO::Message;
use Data::Dumper;

app->log->level('info');
# Read conf file, and set default values
my $cfg = new Config::Simple();
$cfg->read('conf/settings.ini');
our $config = $cfg->vars();

$config->{'database.dsn'}                      ||= 'DBI:mysql:database=vroom;host=localhost';
$config->{'database.user'}                     ||= 'vroom';
$config->{'database.password'}                 ||= 'vroom';
$config->{'signaling.uri'}                     ||= 'https://vroom.example.com/';
$config->{'turn.stun_server'}                  ||= 'stun.l.google.com:19302';
$config->{'turn.turn_server'}                  ||= undef;
$config->{'turn.credentials'}                  ||= 'static';
$config->{'turn.secret_key'}                   ||= '';
$config->{'turn.turn_user'}                    ||= '';
$config->{'turn.turn_password'}                ||= '';
$config->{'video.frame_rate'}                  ||= 15;
$config->{'email.from '}                       ||= 'vroom@example.com';
$config->{'email.contact'}                     ||= 'admin@example.com';
$config->{'email.sendmail'}                    ||= '/sbin/sendmail';
$config->{'interface.powered_by'}              ||= '<a href="http://www.firewall-services.com" target="_blank">Firewall Services</a>';
$config->{'interface.template'}                ||= 'default';
$config->{'interface.chrome_extension_id'}     ||= 'ecicdpoejfllflombfanbhfpgcimjddn';
$config->{'interface.chrome_extension_id'}     ||= 0;
$config->{'cookie.secret'}                     ||= 'secret';
$config->{'cookie.name'}                       ||= 'vroom';
$config->{'rooms.inactivity_timeout'}          ||= 60;
$config->{'rooms.reserved_inactivity_timeout'} ||= 86400;
$config->{'rooms.common_names'}                ||= '';
$config->{'rooms.max_members'}                 ||= 0;
$config->{'log.level'}                         ||= 'info';
$config->{'etherpad.uri'}                      ||= '';
$config->{'etherpad.api_key'}                  ||= '';
$config->{'etherpad.base_domain'}              ||= '';
$config->{'daemon.listen_ip'}                  ||= '127.0.0.1';
$config->{'daemon.listen_port'}                ||= '8090';
$config->{'daemon.backend'}                    ||= 'hypnotoad';
$config->{'daemon.pid_file'}                   ||= '/tmp/vroom.pid';

# Set log level
app->log->level($config->{'log.level'});

# Create etherpad api client if required
our $ec = undef;
if ($config->{'etherpad.uri'} =~ m/https?:\/\/.*/ && $config->{'etherpad.api_key'} ne ''){
  $ec = Etherpad::API->new({
    url => $config->{'etherpad.uri'},
    apikey => $config->{'etherpad.api_key'}
  });
  if (!$ec->check_token){
    app->log->info("Can't connect to Etherpad-Lite API, check your API key and uri");
    $ec = undef;
  }
}

# Global error check
our $error = undef;

# Global client hash
our $peers = {};

# Load I18N, and declare supported languages
plugin I18N => {
  namespace => 'Vroom::I18N',
};
our @supported_lang = qw(en fr);

# Connect to the database
plugin database => {
  dsn      => $config->{'database.dsn'},
  username => $config->{'database.user'},
  password => $config->{'database.password'},
  options  => {
    mysql_enable_utf8    => 1,
    mysql_auto_reconnect => 1,
    RaiseError           => 1,
    PrintError           => 0
  }
};

# Load mail plugin with its default values
plugin mail => {
  from => $config->{'email.from'},
  type => 'text/html',
};

##########################
#  Validation helpers    #
##########################

# take a string as argument and check if it's a valid room name
helper valid_room_name => sub {
  my $self = shift;
  my ($name) = @_;
  my $ret = {};
  # A few names are reserved
  my @reserved = qw(about help feedback feedback_thanks goodbye admin localize api
                    missing dies password kicked invitation js css img fonts snd
                    documentation);
  if ($name !~ m/^[\w\-]{1,49}$/ || grep { $name eq $_ } @reserved){
    return 0;
  }
  return 1;
};

# Check id arg is a valid ID number
helper valid_id => sub {
  my $self = shift;
  my ($id) = @_;
  if ($id !~ m/^\d+$/){
    return 0;
  }
  return 1;
};

# Check email address
helper valid_email => sub {
  my $self = shift;
  my ($email) = @_;
  return Email::Valid->address($email);
};

##########################
#   Various helpers      #
##########################

# Check if the database schema is the one we expect
helper check_db_version => sub {
  my $self = shift;
  my $sth = eval {
    $self->db->prepare('SELECT `value`
                          FROM `config`
                          WHERE `key`=\'schema_version\'');
  };
  $sth->execute;
  my $ver = undef;
  $sth->bind_columns(\$ver);
  $sth->fetch;
  return ($ver eq Vroom::Constants::DB_VERSION) ? '1' : '0';
};

# Create a cookie based session
helper login => sub {
  my $self = shift;
  if ($self->session('name')){
    return 1;
  }
  my $login = $ENV{'REMOTE_USER'} || lc $self->get_random(128);
  my $id = $self->get_random(256);
  my $key = $self->get_random(256);
  my $sth = eval {
    $self->db->prepare('INSERT INTO `api_keys`
                         (`token`,`not_after`)
                         VALUES (?,DATE_ADD(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL 24 HOUR))');
  };
  $sth->execute($key);
  $self->session(
    name    => $login,
    id      => $id,
    ip      => $self->tx->remote_address,
    key     => $key
  );
  $self->app->log->info($self->session('name') . " logged in from " . $self->tx->remote_address);
  return 1;
};

# Expire the cookie
helper logout => sub {
  my $self = shift;
  my ($room) = @_;
  # Logout from etherpad
  if ($ec && $self->session($room) && $self->session($room)->{etherpadSessionId}){
    $ec->delete_session($self->session($room)->{etherpadSessionId});
  }
  if ($self->session('peer_id') && 
      $peers->{$self->session('peer_id')} &&
      $peers->{$self->session('peer_id')}->{socket}){
    $peers->{$self->session('peer_id')}->{socket}->finish;
  }
  $self->session( expires => 1 );
  $self->app->log->info($self->session('name') . " logged out");
  return 1;
};

# Create a new room in the DB
# Requires two args: the name of the room and the session name of the creator
helper create_room => sub {
  my $self = shift;
  my ($name,$owner) = @_;
  # Convert room names to lowercase
  if ($name ne lc $name){
    $name = lc $name;
  }
  # Check if the name is valid
  if (!$self->valid_room_name($name)){
    return 0;
  }
  if ($self->get_room_by_name($name)){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('INSERT INTO `rooms`
                          (`name`,
                           `create_date`,
                           `last_activity`,
                           `owner`)
                          VALUES (?,
                                  CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'),
                                  CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'),
                                  ?');
  };
  $sth->execute(
    $name,
    $owner,
  );
  $self->app->log->info("Room $name created by " . $self->session('name'));
  # Etherpad integration ? If so, create the corresponding pad
  if ($ec){
    $self->create_pad($name);
  }
  return 1;
};

# Take a string as argument
# Return corresponding room data in ->{data}
helper get_room_by_name => sub {
  my $self = shift;
  my ($name) = @_;
  my $res = $self->valid_room_name($name);
  if (!$self->valid_room_name($name)){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `rooms`
                          WHERE `name`=?');
  };
  $sth->execute($name);
  return $sth->fetchall_hashref('name')->{$name}
};

# Same as before, but take a room ID as argument
helper get_room_by_id => sub {
  my $self = shift;
  my ($id) = @_;
  if (!$self->valid_id($id)){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `rooms`
                          WHERE `id`=?');
  };
  $sth->execute($id);
  return $sth->fetchall_hashref('id')->{$id};
};

# Update a room, take a room object as a hashref
# TODO: log modified fields
helper modify_room => sub {
  my $self = shift;
  my ($room) = @_;
  if (!$self->valid_id($room->{id})){
    return 0;
  }
  if (!$self->valid_room_name($room->{name})){
    return 0;
  }
  if (!$room->{max_members} ||
      ($room->{max_members} > $config->{'rooms.max_members'} && $config->{'rooms.max_members'} > 0)){
    $room->{max_members} = 0;
  }
  if (($room->{locked} && $room->{locked} !~ m/^0|1$/) ||
      ($room->{ask_for_name} && $room->{ask_for_name} !~ m/^0|1$/) ||
      ($room->{persistent} && $room->{persistent} !~ m/^0|1$/) ||
       $room->{max_members} !~ m/^\d+$/){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('UPDATE `rooms`
                          SET `owner`=?,
                              `locked`=?,
                              `ask_for_name`=?,
                              `join_password`=?,
                              `owner_password`=?,
                              `persistent`=?,
                              `max_members`=?
                          WHERE `id`=?');
  };
  $sth->execute(
    $room->{owner},
    $room->{locked},
    $room->{ask_for_name},
    $room->{join_password},
    $room->{owner_password},
    $room->{persistent},
    $room->{max_members},
    $room->{id}
  );
  $self->app->log->info("Room " . $room->{name} ." modified by " . $self->session('name'));
  return 1;
};

# Set the role of a peer
helper set_peer_role => sub {
  my $self = shift;
  my ($data) = @_;
  # Check the peer exists and is already in the room
  if (!$data->{peer_id} ||
      !$peers->{$data->{peer_id}}){
    return 0;
  }
  $peers->{$data->{peer_id}}->{role} = $data->{role};
  $self->app->log->info("Peer " . $data->{peer_id} . " has now the " .
                          $data->{role} . " role in room " . $data->{room});
  return 1;
};

# Return the role of a peer, from it's signaling ID
helper get_peer_role => sub {
  my $self = shift;
  my ($data) = @_;
  return $peers->{$data->{peer_id}}->{role};
};

# Promote a peer to owner
helper promote_peer => sub {
  my $self = shift;
  my ($data) = @_;
  return $self->set_peer_role({
    peer_id => $data->{peer_id},
    room    => $data->{room},
    role    => 'owner'
  });
};

# Purge api keys
helper purge_api_keys => sub {
  my $self = shift;
  $self->app->log->debug('Removing expired API keys');
  my $sth = eval {
    $self->db->prepare('DELETE FROM `api_keys`
                          WHERE `not_after` < CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\')');
  };
  $sth->execute;
  return 1;
};

# Purge unused rooms
helper purge_rooms => sub {
  my $self = shift;
  $self->app->log->debug('Removing unused rooms');
  my $sth = eval {
    $self->db->prepare('SELECT `name`,`etherpad_group`
                          FROM `rooms`
                          WHERE `last_activity` < DATE_SUB(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL ' . $config->{'rooms.inactivity_timeout'} . ' MINUTE)
                          AND `persistent`=\'0\' AND `owner_password` IS NULL');
  };
  $sth->execute;
  my $toDelete = {};
  while (my ($room,$ether_group) = $sth->fetchrow_array){
    $toDelete->{$room} = $ether_group;
  }
  if ($config->{'rooms.reserved_inactivity_timeout'} > 0){
    $sth = eval {
      $self->db->prepare('SELECT `name`,`etherpad_group`
                            FROM `rooms`
                            WHERE `last_activity` < DATE_SUB(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL ' . $config->{'rooms.reserved_inactivity_timeout'} . ' MINUTE)
                              AND `persistent`=\'0\' AND `owner_password` IS NOT NULL')
    };
    $sth->execute;
    while (my ($room, $ether_group) = $sth->fetchrow_array){
      $toDelete->{$room} = $ether_group;
    }
  }
  foreach my $room (keys %{$toDelete}){
    $self->app->log->debug("Room $room will be deleted");
    # Remove Etherpad group
    if ($ec){
      $ec->delete_pad($toDelete->{$room} . '$' . $room);
      $ec->delete_group($toDelete->{$room});
    }
  }
  # Now remove rooms
  if (keys %{$toDelete} > 0){
    $sth = eval {
      $self->db->prepare("DELETE FROM `rooms`
                            WHERE `name` IN (" . join( ",", map { "?" } keys %{$toDelete} ) . ")");
    };
    $sth->execute(keys %{$toDelete});
  }
  return 1;
};

# delete just a specific room
helper delete_room => sub {
  my $self = shift;
  my ($room) = @_;
  $self->app->log->debug("Removing room $room");
  my $data = $self->get_room_by_name($room);
  if (!$data){
    $self->app->log->debug("Error: room $room doesn't exist");
    return 0;
  }
  if ($ec && $data->{etherpad_group}){
    $ec->delete_pad($data->{etherpad_group} . '$' . $room);
    $ec->delete_group($data->{etherpad_group});
  }
  my $sth = eval {
      $self->db->prepare('DELETE FROM `rooms`
                            WHERE `name`=?');
  };
  $sth->execute($room);
  return 1;
};

# Retrieve the list of rooms
helper get_room_list => sub {
  my $self = shift;
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `rooms`');
  };
  $sth->execute;
  return $sth->fetchall_hashref('name');
};

# Just update the activity timestamp
# so we can detect unused rooms
helper update_room_last_activity => sub {
  my $self = shift;
  my ($name) = @_;
  my $data = $self->get_room_by_name($name);
  if (!$data){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('UPDATE `rooms`
                          SET `last_activity`=CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\')
                          WHERE `id`=?');
  };
  $sth->execute($data->{id});
  return 1;
};

# Generate a random token
helper get_random => sub {
  my $self = shift;
  my ($entropy) = @_;
  return Session::Token->new(entropy => $entropy)->get;
};

# Generate a random name
helper get_random_name => sub {
  my $self = shift;
  my $name = lc $self->get_random(64);
  # Get another one if already taken
  while ($self->get_room_by_name($name)){
    $name = $self->get_random_name();
  }
  return $name;
};

# Return the mtime of a file
# Used to append the timestamp to JS and CSS files
# So client can get new version immediatly
helper get_mtime => sub {
  my $self = shift;
  my ($file) = @_;
  return stat($file)->mtime;
};

# Wrapper arround url_for which adds a trailing / if needed
helper get_url => sub {
  my $self = shift;
  my $url = $self->url_for(shift);
  $url .= ($url =~ m/\/$/) ? '' : '/';
  return $url;
};

# Add an email address to the list of notifications
helper add_notification => sub {
  my $self = shift;
  my ($room,$email) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$data || !$self->valid_email($email)){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('INSERT INTO `email_notifications`
                          (`room_id`,`email`)
                          VALUES (?,?)');
  };
  $sth->execute(
    $data->{id},
    $email
  );
  return 1;
};

# Update the list of notified email for a room in one go
# Take the room and an array ref of emails
helper update_email_notifications => sub {
  my $self = shift;
  my ($room,$emails) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$data){
    return 0;
  }
  # First, drop all existing notifications
  my $sth = eval {
    $self->db->prepare('DELETE FROM `email_notifications`
                          WHERE `room_id`=?');
  };
  $sth->execute(
    $data->{id},
  );
  # Now, insert new emails
  foreach my $email (@$emails){
    # Skip empty inputs
    if ($email eq ''){
      next;
    }
    $self->add_notification($room,$email) || return 0;
  }
  return 1;
};

# Return the list of email addresses
helper get_email_notifications => sub {
  my $self = shift;
  my ($room) = @_;
  $room = $self->get_room_by_name($room) || return undef;
  my $sth = eval {
    $self->db->prepare('SELECT `id`,`email`
                          FROM `email_notifications`
                          WHERE `room_id`=?');
  };
  $sth->execute($room->{id});
  return $sth->fetchall_hashref('id');
};

# Remove an email from notification list
helper remove_notification => sub {
  my $self = shift;
  my ($room,$email) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$data){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('DELETE FROM `email_notifications`
                          WHERE `room_id`=?
                            AND `email`=?');
  };
  $sth->execute(
    $data->{id},
    $email
  );
  $self->app->log->debug($self->session('name') .
    " has removed $email from the list of email which are notified when someone joins room $room");
  return 1;
};

# Randomly choose a music on hold
helper choose_moh => sub {
  my $self = shift;
  my @files = (<public/snd/moh/*.*>);
  return basename($files[rand @files]);
};

# Add a invitation
helper add_invitation => sub {
  my $self = shift;
  my ($room,$email) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$data){
    return 0;
  }
  my $token = $self->get_random(256);
  my $sth = eval {
    $self->db->prepare('INSERT INTO `email_invitations`
                          (`room_id`,`from`,`token`,`email`,`date`)
                          VALUES (?,?,?,?,CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'))');
  };
  $sth->execute(
    $data->{id},
    $self->session('id'),
    $token,
    $email
  );
  $self->app->log->debug($self->session('name') . " has invited $email to join room $room");
  return $token;
};

# return a hash with all the invitation param
# just like get_room
helper get_invitation_by_token => sub {
  my $self = shift;
  my ($token) = @_;
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `email_invitations`
                          WHERE `token`=?
                            AND `processed`=\'0\'');
  };
  $sth->execute($token);
  return $sth->fetchall_hashref('token')->{$token};
};

# Find invitations which have a unprocessed repsponse
helper get_invitation_list => sub {
  my $self = shift;
  my ($session) = @_;
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `email_invitations`
                          WHERE `from`=?
                            AND `response` IS NOT NULL
                            AND `processed`=\'0\'');
  };
  $sth->execute($session);
  return $sth->fetchall_hashref('id');
};

# Got a response from invitation. Store the message in the DB
# so the organizer can get it on next ping
helper respond_to_invitation => sub {
  my $self = shift;
  my ($token,$response,$message) = @_;
  my $sth = eval {
    $self->db->prepare('UPDATE `email_invitations`
                          SET `response`=?,
                              `message`=?
                          WHERE `token`=?');
  };
  $sth->execute(
    $response,
    $message,
    $token
  );
  return 1;
};

# Mark a invitation response as processed
helper mark_invitation_processed => sub {
  my $self = shift;
  my ($token) = @_;
  my $sth = eval {
    $self->db->prepare('UPDATE `email_invitations`
                          SET `processed`=\'1\'
                          WHERE `token`=?');
  };
  $sth->execute($token);
  return 1;
};

# Purge expired invitation links
# Invitations older than 2 hours really doesn't make a lot of sens
helper purge_invitations => sub {
  my $self = shift;
  $self->app->log->debug('Removing expired invitations');
  my $sth = eval {
    $self->db->prepare('DELETE FROM `email_invitations`
                          WHERE `date` < DATE_SUB(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL 2 HOUR)');
  };
  $sth->execute;
  return 1;
};

# Check an invitation token is valid
helper check_invite_token => sub {
  my $self = shift;
  my ($room,$token) = @_;
  # Expire invitations before checking if it's valid
  $self->purge_invitations;
  $self->app->log->debug("Checking if invitation with token $token is valid for room $room");
  my $ret = 0;
  my $data = $self->get_room_by_name($room);
  if (!$data || !$token){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('SELECT COUNT(`id`)
                          FROM `email_invitations`
                          WHERE `room_id`=?
                          AND `token`=?
                          AND (`response` IS NULL
                                OR `response`=\'later\')');
  };
  $sth->execute(
    $data->{id},
    $token
  );
  my $num;
  $sth->bind_columns(\$num);
  $sth->fetch;
  if ($num != 1){
    $self->app->log->debug("Invitation is invalid");
    return 0;
  }
  $self->app->log->debug("Invitation is valid");
  return 1;
};

# Create a pad (and the group if needed)
helper create_pad => sub {
  my $self = shift;
  my ($room) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$ec || !$data){
    return 0;
  }
  # Create the etherpad group if not already done
  # and register it in the DB
  if (!$data->{etherpad_group} || $data->{etherpad_group} eq ''){
    $data->{etherpad_group} = $ec->create_group();
    if (!$data->{etherpad_group}){
      return 0;
    }
    my $sth = eval {
      $self->db->prepare('UPDATE `rooms`
                            SET `etherpad_group`=?
                            WHERE `id`=?');
    };
    $sth->execute(
      $data->{etherpad_group},
      $data->{id}
    );
  }
  $ec->create_group_pad($data->{etherpad_group},$room);
  $self->app->log->debug("Pad for room $room created (group " . $data->{etherpad_group} . ")");
  return 1;
};

# Create an etherpad session for a user
helper create_etherpad_session => sub {
  my $self = shift;
  my ($room) = @_;
  my $data = $self->get_room_by_name($room);
  if (!$ec || !$data || !$data->{etherpad_group}){
    return 0;
  }
  my $id = $ec->create_author_if_not_exists_for($self->session('name'));
  $self->session($room)->{etherpadAuthorId} = $id;
  my $etherpadSession = $ec->create_session(
    $data->{etherpad_group},
    $id,
    time + 86400
  );
  $self->session($room)->{etherpadSessionId} = $etherpadSession;
  my $etherpadCookieParam = {};
  if ($config->{'etherpad.base_domain'} && $config->{'etherpad.base_domain'} ne ''){
    $etherpadCookieParam->{domain} = $config->{'etherpad.base_domain'};
  }
  $self->cookie(sessionID => $etherpadSession, $etherpadCookieParam);
  return 1;
};

# Get an API key by id
helper get_key_by_token => sub {
  my $self = shift;
  my ($token) = @_;
  if (!$token || $token eq ''){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `api_keys`
                          WHERE `token`=?
                            AND `not_after` > CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\')
                          LIMIT 1');
  };
  $sth->execute($token);
  return $sth->fetchall_hashref('token')->{$token};
};

# Associate an API key to a room, and set the corresponding role
helper associate_key_to_room => sub {
  my $self = shift;
  my (%data) = @_;
  my $data = \%data;
  my $room = $self->get_room_by_name($data->{room});
  my $key = $self->get_key_by_token($data->{key});
  if (!$room || !$key){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('INSERT INTO `room_keys`
                          (`room_id`,`key_id`,`role`)
                          VALUES (?,?,?)
                          ON DUPLICATE KEY UPDATE `role`=?');
  };
  $sth->execute(
    $room->{id},
    $key->{id},
    $data->{role},
    $data->{role}
  );
  return 1;
};

# Make an API key admin of every rooms
helper make_key_admin => sub {
  my $self = shift;
  my ($token) = @_;
  my $key = $self->get_key_by_token($token);
  $self->app->log->debug("making key $token an admin key");
  if (!$key){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('UPDATE `api_keys`
                         SET `admin`=\'1\'
                         WHERE `id`=?');
  };
  $sth->execute($key->{id});
  return 1;
};

# Check if a key can perform an action against a room
helper key_can_do_this => sub {
  my $self = shift;
  my (%data) = @_;
  my $data = \%data;
  my $actions = API_ACTIONS;
  if (!$data->{action}){
    return 0;
  }
  # Anonymous actions
  if ($actions->{anonymous}->{$data->{action}}){
    return 1;
  }
  my $key = $self->get_key_by_token($data->{token});
  if (!$key){
    $self->app->log->debug("Invalid API key");
    return 0;
  }
  # API key is an admin one ?
  if ($key->{admin}){
    $self->app->log->debug("Admin API Key");
    return 1;
  }
  # Global actions can only be performed by admin keys
  if (!$data->{param}->{room}){
    $self->app->log->debug("Invalid room ID");
    return 0;
  }

  # Now, lookup the DB the role of this key for this room
  my $sth = eval {
    $self->db->prepare('SELECT `role`
                          FROM `room_keys`
                          LEFT JOIN `rooms` ON `room_keys`.`room_id`=`rooms`.`id`
                          WHERE `room_keys`.`key_id`=?
                            AND `rooms`.`name`=?
                          LIMIT 1');
  };
  $sth->execute($key->{id},$data->{param}->{room});
  $sth->bind_columns(\$key->{role});
  $sth->fetch;
  $self->app->log->debug("Key role: " . $key->{role} . " and action: " . $data->{action});
  # If this key has owner privileges on this room, allow both owner and partitipant actions
  if ($key->{role} eq 'owner' && ($actions->{owner}->{$data->{action}} || $actions->{participant}->{$data->{action}})){
    return 1;
  }
  # If this key as simple partitipant priv in this room, only allow participant actions
  elsif ($key->{role} eq 'participant' && $actions->{participant}->{$data->{action}}){
    return 1;
  }
  # Else, deny
  $self->app->log->debug("API Key " . $data->{token} . " cannot run action " . $data->{action} . " on room " . $data->{param}->{room});
  return 0;
};

# Get the number of participants currently in a room
helper get_room_members => sub {
  my $self = shift;
  my $room = shift;
  if (!$self->get_room_by_name($room)){
    return 0;
  }
  my $cnt = 0;
  foreach my $peer (keys $peers){
    if ($peers->{$peer}->{room} &&
        $peers->{$peer}->{room} eq $room){
      $cnt++;
    }
  }
  return $cnt;
};

# Broadcast a SocketIO message to all the members of a room
helper signal_broadcast_room => sub {
  my $self = shift;
  my $data = shift;

  # Send a message to all members of the same room as the sender
  # ecept the sender himself
  foreach my $peer (keys %$peers){
    next if ($peer eq $data->{from});
    next if !$peers->{$data->{from}}->{room};
    next if !$peers->{$peer}->{room};
    next if $peers->{$peer}->{room} ne $peers->{$data->{from}}->{room};
    $peers->{$peer}->{socket}->send($data->{msg});
  }
  return 1;
};

# Get the member limit for a room
helper get_member_limit => sub {
  my $self = shift;
  my $name = shift;
  my $room = $self->get_room_by_name($name);
  if ($room->{max_members} > 0 && $room->{max_members} < $config->{'rooms.max_members'}){
    return $room->{max_members};
  }
  elsif ($config->{'rooms.max_members'} > 0){
    return $config->{'rooms.max_members'};
  }
  return 0;
};


# Get credentials for the turn servers. Return an array (username,password)
helper get_turn_creds => sub {
  my $self = shift;
  my $room = $self->get_room_by_name(shift);
  if (!$room){
    return (undef,undef);
  }
  elsif ($config->{'turn.credentials'} eq 'static'){
    return ($config->{'turn.turn_user'},$config->{'turn.turn_password'});
  }
  elsif ($config->{'turn.credentials'} eq 'rest'){
    my $expire = time + 300;
    my $user = $expire . ':' . $room->{name};
    my $pass = encode_base64(hmac_sha1($user, $config->{'turn.secret_key'}));
    chomp $pass;
    return ($user,$pass);
  }
  else {
    return (undef,undef);
  }
};

# Socket.IO handshake
get '/socket.io/:ver' => sub {
  my $self = shift;
  $self->session(peer_id => $self->get_random(256));
  my $handshake = Protocol::SocketIO::Handshake->new(
      session_id        => $self->session('peer_id'),
      heartbeat_timeout => 20,
      close_timeout     => 40,
      transports        => [qw/websocket/]
  );
  return $self->render(text => $handshake->to_bytes);
};

# WebSocket transport for the Socket.IO channel
websocket '/socket.io/:ver/websocket/:id' => sub {
  my $self = shift;
  my $id = $self->stash('id');
  # the ID must match the one stored in our session
  if ($id ne $self->session('peer_id') || !$self->session('name')){
    $self->app->log->debug('Sometyhing is wrong, peer ID is ' . $id . ' but should be ' . $self->session('peer_id'));
    return $self->send('Bad session');
  }

  # We create the peer in the global hash
  $peers->{$id}->{socket} = $self->tx;
  # And set the initial "last seen" flag
  $peers->{$id}->{last} = time;
  # Associate the unique ID and name
  $peers->{$id}->{id} = $self->session('id');
  $peers->{$id}->{name} = $self->session('name');

  # When we recive a message, lets parse it as e Socket.IO one
  $self->on('message' => sub {
    my $self = shift;
    my $msg = Protocol::SocketIO::Message->new->parse(shift);

    if ($msg->type eq 'event'){
      # Here's a client joining a room
      if ($msg->{data}->{name} eq 'join'){
        my $room = $msg->{data}->{args}[0];
        # Is this peer allowed to join the room ?
        if (!$self->get_room_by_name($room) ||
            !$self->session($room) ||
            !$self->session($room)->{role} ||
            $self->session($room)->{role} !~ m/^owner|participant$/){
          $self->app->log->debug("Failed to connect to the signaling channel, " . $self->session('name') .
                                 " (session ID " . $self->session('id') . ") has no role for this room");
          $self->send( Protocol::SocketIO::Message->new( type => 'disconnect' ) );
          $self->finish;
          return;
        }
        # Are we under the limit of members ?
        my $limit = $self->get_member_limit($room);
        if ($limit > 0 && $self->get_room_members($room) >= $limit){
          $self->app->log->debug("Failed to connect to the signaling channel, members limit (" . $config->{'rooms.max_members'} .
                                 ") is reached");
          $self->send( Protocol::SocketIO::Message->new( type => 'disconnect' ) );
          $self->finish;
          return;
        }
        # We build a list of peers, except this new one so we can send it
        # to the new peer, and he'll be able to contact all those peers
        my $others = {};
        foreach my $peer (keys %$peers){
          next if ($peer eq $id);
          $others->{$peer} = $peers->{$peer}->{details};
        }
        $peers->{$id}->{details} = {
          screen => \0,
          video  => \1,
          audio  => \0
        };
        $peers->{$id}->{room} = $room;
        $self->app->log->debug("Client id " . $id . " joined room " . $room);
        # Lets send the list of peers in our ack message
        # Not sure why the null arg is needed, got it by looking at how it works with SignalMaster
        $self->send(
          Protocol::SocketIO::Message->new(
            type       => 'ack',
            message_id => $msg->{id},
            args => [
              undef,
              {
                clients => $others
              }
            ]
          )
        );
        # Update room last activity
        $self->update_room_last_activity($room);
      }
      # We have a message from a peer
      elsif ($msg->{data}->{name} eq 'message'){
        $self->app->log->debug("Signaling message received from peer " . $id);
        # Forward this message to all other members of the same room
        $msg->{data}->{args}[0]->{from} = $id;
        $self->signal_broadcast_room({
          from => $id,
          msg  => Protocol::SocketIO::Message->new(%$msg)
        });
      }
      # When a peer share its screen
      elsif ($msg->{data}->{name} eq 'shareScreen'){
        $peers->{$id}->{details}->{screen} = \1;
      }
      # Or unshare it
      elsif ($msg->{data}->{name} eq 'unshareScreen'){
        $peers->{$id}->{details}->{screen} = \0;
        $self->signal_broadcast_room({
          from => $id,
          msg  => Protocol::SocketIO::Message->new(
            type => 'event',
            data => {
              name => 'remove',
              args => [{ id => $id, type => 'screen' }]
            }
          )
        });
      }
      elsif ($msg->{data}->{name} =~ m/^leave|disconnect$/){
        $peers->{$id}->{socket}->{finish};
      }
      else{
        $self->app->log->debug("Unhandled SocketIO message\n" . Dumper $msg);
      }
    }
    # Heartbeat reply, update timestamp
    elsif ($msg->type eq 'heartbeat'){
      $peers->{$id}->{last} = time;
    }
  });

  # Triggerred when a websocket connection ends
  $self->on(finish => sub {
    my ($self, $code, $reason) = @_;
    $self->app->log->debug("Client id " . $id . " closed websocket connection");
    $self->app->log->debug("Notifying others that $id leaved");
    $self->signal_broadcast_room({
      from => $id,
      msg  => Protocol::SocketIO::Message->new(
        type => 'event',
        data => {
          name => 'remove',
          args => [{ id => $id, type => 'video' }]
        }
      )
    });
    $self->update_room_last_activity($peers->{$id}->{room});
    delete $peers->{$id};
  });

  # This is just the end of the initial handshake, we indicate the client we're ready
  $self->send(Protocol::SocketIO::Message->new( type => 'connect' ));
};

# Send heartbeats to all websocket clients
# Every 3 seconds
Mojo::IOLoop->recurring( 3 => sub {
  foreach my $peer ( keys %$peers ) {
    # This shouldn't happen, but better to log an error and fix it rather
    # than looping indefinitly on a bogus entry if something went wrong
    if (!$peers->{$peer}->{socket}){
      app->log->debug("Garbage found in peers (peer $peer)\n" . Dumper($peers->{$peer}));
      delete $peers->{$peer};
    }
    # If we had no reply from this peer in the last 15 sec
    # (5 heartbeat without response), we consider it dead and remove it
    elsif ($peers->{$peer}->{last} < time - 15){
      app->log->debug("Peer $peer didn't reply in 15 sec, disconnecting");
      $peers->{$peer}->{socket}->finish;
      delete $peers->{$peer};
    }
    else {
      $peers->{$peer}->{socket}->send(Protocol::SocketIO::Message->new( type => 'heartbeat' ));
    }
  }
});

# Route / to the index page
get '/' => sub {
  my $self = shift;
  $self->stash(
    etherpad => ($ec) ? 'true' : 'false'
  );
} => 'index';

# Route for the about page
get '/about' => sub {
  my $self = shift;
  $self->stash(
    components => COMPONENTS,
    musics     => MOH
  );
} => 'about';

# Documentation
get '/documentation' => 'documentation';

# Route for the help page
get '/help' => 'help';

# Routes for feedback. One get to display the form
# and one post to get data from it
get '/feedback' => 'feedback';
post '/feedback' => sub {
  my $self = shift;
  my $email = $self->param('email') || '';
  my $comment = $self->param('comment');
  my $sent = $self->mail(
    to      => $config->{'email.contact'},
    subject => $self->l("FEEDBACK_FROM_VROOM"),
    data    => $self->render_mail('feedback',
      email   => $email,
      comment => $comment
    )
  );
  return $self->render('feedback_thanks');
};

# Route for the goodbye page, displayed when someone leaves a room
get '/goodbye/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  if (!$self->get_room_by_name($room)){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->logout($room);
} => 'goodbye';

# Route for the kicked page
# Should be merged with the goodby route
get '/kicked/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  if (!$self->get_room_by_name($room)){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->logout($room);
} => 'kicked';

# Route for invitition response
any [qw(GET POST)] => '/invitation/:token' => { token => '' } => sub {
  my $self = shift;
  my $token = $self->stash('token');
  # Delete expired invitation now
  $self->purge_invitations;
  my $invite = $self->get_invitation_by_token($token);
  my $room = $self->get_room_by_id($invite->{room_id});
  if (!$invite || !$room){
    return $self->render('error',
      err  => 'ERROR_INVITATION_INVALID',
      msg  => $self->l('ERROR_INVITATION_INVALID'),
      room => $room
    );
  }
  if ($self->req->method eq 'GET'){
    return $self->render('invitation',
      token => $token,
      room  => $room->{name},
    );
  }
  elsif ($self->req->method eq 'POST'){
    my $response = $self->param('response') || 'decline';
    my $message = $self->param('message') || '';
    if ($response !~ m/^(later|decline)$/ || !$self->respond_to_invitation($token,$response,$message)){
      return $self->render('error');
    }
    return $self->render('invitation_thanks');
  }
};

# Translation for JS resources
get '/localize/:lang' => { lang => 'en' } => sub {
  my $self = shift;
  my $strings = {};
  foreach my $string (keys %Vroom::I18N::en::Lexicon){
    $strings->{$string} = $self->l($string);
  }
  # Tell the client to cache it
  $self->res->headers->cache_control('private,max-age=3600');
  return $self->render(json => $strings);
};

# Route for the password page
# When someone tries to join a password protected room
any [qw(GET POST)] => '/password/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room') || '';
  my $data = $self->get_room_by_name($room);
  if (!$data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  if ($self->req->method eq 'GET'){
    return $self->render('password',
      room => $room
    );
  }
  else{
    my $pass = $self->param('password');
    # First check if we got the owner password, and if so, mark this user as owner
    if ($data->{owner_password} && Crypt::SaltedHash->validate($data->{owner_password}, $pass)){
      $self->session($room => {role => 'owner'});
      $self->associate_key_to_room(
        room => $room,
        key  => $self->session('key'),
        role => 'owner'
      );
      return $self->redirect_to($self->get_url('/') . $room);
    }
    # Then, check if it's the join password
    elsif ($data->{join_password} && Crypt::SaltedHash->validate($data->{join_password}, $pass)){
      $self->session($room => {role => 'participant'});
      $self->associate_key_to_room(
        room => $room,
        key  => $self->session('key'),
        role => 'participant'
      );
      return $self->redirect_to($self->get_url('/') . $room);
    }
    # Else, it's a wrong password, display an error page
    else{
      return $self->render('error',
        err  => 'WRONG_PASSWORD',
        msg  => sprintf ($self->l("WRONG_PASSWORD"), $room),
        room => $room
      );
    }
  }
};

# API requests handler
any '/api' => sub {
  my $self = shift;
  $self->purge_api_keys;
  my $token = $self->req->headers->header('X-VROOM-API-Key');
  my $json = Mojo::JSON->new;
  my $req = $json->decode($self->param('req'));
  my $err = $json->error;
  my $room;
  if ($err || !$req->{action} || !$req->{param}){
    return $self->render(
      json => {
        msg => $err,
        err => $err
      },
      status => 503
    );
  }   
  # Handle requests authorized for anonymous users righ now
  if ($req->{action} eq 'switch_lang'){
    if (!grep { $req->{param}->{language} eq $_ } @supported_lang){
      return $self->render(
        json => {
          msg => $self->l('UNSUPPORTED_LANG'),
          err => 'UNSUPPORTED_LANG'
        },
        status => 400
      );
    }
    $self->session(language => $req->{param}->{language});
    return $self->render(
      json => {}
    );
  }

  # Now, lets check if the key can do the requested action
  my $res = $self->key_can_do_this(
    token  => $token,
    action => $req->{action},
    param  => $req->{param}
  );

  # This action isn't possible with the privs associated to the API Key
  if (!$res){
    return $self->render(
      json => {
        msg => $self->l('NOT_ALLOWED'),
        err => 'NOT_ALLOWED'
      },
      status => '401'
    );
  }

  # Here are method not tied to a room
  if ($req->{action} eq 'get_room_list'){
    my $rooms = $self->get_room_list;
    foreach my $r (keys %{$rooms}){
      # Blank out a few param we don't need
      foreach my $p (qw/join_password owner_password owner etherpad_group/){
        delete $rooms->{$r}->{$p};
      }
      # Count active users
      $rooms->{$r}->{members} = $self->get_room_members($r);
    }
    return $self->render(
      json => {
        rooms => $rooms
      }
    );
  }
  # And here anonymous method, which do not require an API Key
  elsif ($req->{action} eq 'create_room'){
    $req->{param}->{room} ||= $self->get_random_name();
    $req->{param}->{room} = lc $req->{param}->{room};
    my $json = {
      err  => 'ERROR_OCCURRED',
      msg  => $self->l('ERROR_OCCURRED'),
      room => $req->{param}->{room}
    };
    $self->login;
    # Cleanup unused rooms before trying to create it
    $self->purge_rooms;
    if (!$self->valid_room_name($req->{param}->{room})){
      $json->{err} = 'ERROR_NAME_INVALID';
      $json->{msg} = $self->l('ERROR_NAME_INVALID');
      return $self->render(json => $json, status => 400);
    }
    elsif ($self->get_room_by_name($req->{param}->{room})){
      $json->{err} = 'ERROR_NAME_CONFLICT';
      $json->{msg} = $self->l('ERROR_NAME_CONFLICT');
      return $self->render(json => $json, status => 409);
    }
    if (!$self->create_room($req->{param}->{room},$self->session('name'))){
      $json->{err} = 'ERROR_OCCURRED';
      $json->{msg} = $self->l('ERROR_OCCURRED');
      return $self->render(json => $json, status => 500);
    }
    $json->{err} = '';
    $self->session($req->{param}->{room} => {role => 'owner'});
    $self->associate_key_to_room(
      room => $req->{param}->{room},
      key  => $self->session('key'),
      role => 'owner'
    );
    return $self->render(json => $json);
  }

  if (!$req->{param}->{room}){
    return $self->render(
      json => {
        msg => $self->l('ERROR_ROOM_NAME_MISSING'),
        err => 'ERROR_ROOM_NAME_MISSING'
      },
      status => '400'
    );
  }

  $room = $self->get_room_by_name($req->{param}->{room});
  if (!$room){
    return $self->render(
      json => {
        msg => sprintf($self->l('ERROR_ROOM_s_DOESNT_EXIST'), $req->{param}->{room}),
        err => 'ERROR_ROOM_DOESNT_EXIST'
      },
      status => '400'
    );
  }

  # Ok, now, we don't have to bother with authorization anymore
  if ($req->{action} eq 'invite_email'){
    my $rcpts = $req->{param}->{rcpts};
    foreach my $addr (@$rcpts){
      if (!$self->valid_email($addr) && $addr ne ''){
        return $self->render(
          json => {
            msg => $self->l('ERROR_MAIL_INVALID'),
            err => 'ERROR_MAIL_INVALID'
          },
          status => 400
        );
      }
    }
    foreach my $addr (@$rcpts){
      my $token = $self->add_invitation(
        $req->{param}->{room},
        $addr
      );
      my $sent = $self->mail(
        to      => $addr,
        subject => $self->l("EMAIL_INVITATION"),
        data    => $self->render_mail('invite',
          room     => $req->{param}->{room},
          message  => $req->{param}->{message},
          token    => $token,
          joinPass => ($room->{join_password}) ? 'yes' : 'no'
        )
      );
      if (!$token || !$sent){
        return $self->render(
          json => {
            msg => $self->l('ERROR_OCCURRED'),
            err => 'ERROR_OCCURRED'
          },
          status => 400
        );
      }
      $self->app->log->info("Email invitation to join room " . $req->{param}->{room} . " sent to " . $addr);
    }
    return $self->render(
      json => {
        msg => sprintf($self->l('INVITE_SENT_TO_s'), join("\n", @$rcpts)),
       }
    );
  }
  # Handle room lock/unlock
  elsif ($req->{action} =~ m/(un)?lock_room/){
    $room->{locked} = ($req->{action} eq 'lock_room') ? '1':'0';
    if ($self->modify_room($room)){
      my $m = ($req->{action} eq 'lock_room') ? 'ROOM_LOCKED' : 'ROOM_UNLOCKED';
      return $self->render(
        json => {
          msg => $self->l($m),
          err => $m
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  # Handle activity pings sent every minute by each participant
  elsif ($req->{action} eq 'ping'){
    $self->update_room_last_activity($room->{name});
    # Cleanup expired rooms every ~10 pings
    if ((int (rand 100)) <= 10){
      $self->purge_rooms;
      $self->purge_invitations;
    }
    # Check if we got any invitation response to process
    my $invitations = $self->get_invitation_list($self->session('id'));
    my $msg = '';
    foreach my $invit (keys %{$invitations}){
      $msg .= sprintf($self->l('INVITE_REPONSE_FROM_s'), $invitations->{$invit}->{email}) . "\n" ;
      if ($invitations->{$invit}->{response} && $invitations->{$invit}->{response} eq 'later'){
        $msg .= $self->l('HE_WILL_TRY_TO_JOIN_LATER');
      }
      else{
        $msg .= $self->l('HE_WONT_JOIN');
      }
      if ($invitations->{$invit}->{message} && $invitations->{$invit}->{message} ne ''){
        $msg .= "\n" . $self->l('MESSAGE') . ":\n" . $invitations->{$invit}->{message} . "\n";
      }
      $msg .= "\n";
      $self->mark_invitation_processed($invitations->{$invit}->{token});
    }
    return $self->render(
      json => {
        msg => $msg,
      }
    );
  }
  # Update room configuration
  elsif ($req->{action} eq 'update_room_conf'){
    $room->{locked} = ($req->{param}->{locked}) ? '1' : '0';
    $room->{ask_for_name} = ($req->{param}->{ask_for_name}) ? '1' : '0';
    $room->{max_members} = $req->{param}->{max_members};
    # Room persistence can only be set by admins
    if ($self->key_can_do_this(token  => $token, action => 'set_persistent') && $req->{param}->{persistent} ne ''){
      $room->{persistent} = ($req->{param}->{persistent} eq Mojo::JSON->true) ? '1' : '0';
    }
    foreach my $pass (qw/join_password owner_password/){
      if ($req->{param}->{$pass} eq Mojo::JSON->false){
        $room->{$pass} = undef;
      }
      elsif ($req->{param}->{$pass} ne ''){
        $room->{$pass} = Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($req->{param}->{$pass})->generate;
      }
    }
    if ($self->modify_room($room) && $self->update_email_notifications($room->{name},$req->{param}->{emails})){
      return $self->render(
        json => {
          msg => $self->l('ROOM_CONFIG_UPDATED')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED'
      },
      staus => 503
    );
  }
  # Handle password (join and owner)
  elsif ($req->{action} eq 'set_join_password'){
    $room->{join_password} = ($req->{param}->{password} && $req->{param}->{password} ne '') ?
      Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($req->{param}->{password})->generate : undef;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg => $self->l(($req->{param}->{password}) ? 'PASSWORD_PROTECT_SET' : 'PASSWORD_PROTECT_UNSET'),
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  elsif ($req->{action} eq 'set_owner_password'){
    if (grep { $req->{param}->{room} eq $_ } (split /[,;]/, $config->{'rooms.common_names'})){
      return $self->render(
        json => {
          msg => $self->l('ERROR_COMMON_ROOM_NAME'),
          err => 'ERROR_COMMON_ROOM_NAME'
        },
        status => 406
      );
    }
    $room->{owner_password} = ($req->{param}->{password} && $req->{param}->{password} ne '') ?
      Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($req->{param}->{password})->generate : undef;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg => $self->l(($req->{param}->{password}) ? 'ROOM_NOW_RESERVED' : 'ROOM_NO_MORE_RESERVED'),
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  elsif ($req->{action} eq 'set_persistent'){
    my $set = $self->param('set');
    $room->{persistent} = ($set eq 'on') ? 1 : 0;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg => $self->l(($set eq 'on') ? 'ROOM_NOW_PERSISTENT' : 'ROOM_NO_MORE_PERSISTENT')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  # Set/unset askForName
  elsif ($req->{action} eq 'set_ask_for_name'){
    my $set = $req->{param}->{set};
    $room->{ask_for_name} = ($set eq 'on') ? 1 : 0;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg => $self->l(($set eq 'on') ? 'FORCE_DISPLAY_NAME' : 'NAME_WONT_BE_ASKED')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  # Add or remove an email address to the list of email notifications
  elsif ($req->{action} eq 'email_notification'){
    my $email = $req->{param}->{email};
    my $set = $req->{param}->{set};
    if (!$self->valid_email($email)){
      return $self->render(
        json => {
          msg => $self->l('ERROR_MAIL_INVALID'),
          err => 'ERROR_MAIL_INVALID',
        },
        status => 400
      );
    }
    elsif ($set eq 'on' && $self->add_notification($room->{name},$email)){
      return $self->render(
        json => {
          msg => sprintf($self->l('s_WILL_BE_NOTIFIED'), $email)
        }
      );
    }
    elsif ($set eq 'off' && $self->remove_notification($room->{name},$email)){
      return $self->render(
        json => {
          msg => sprintf($self->l('s_WONT_BE_NOTIFIED_ANYMORE'), $email)
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  elsif ($req->{action} eq 'authenticate'){
    my $pass = $req->{param}->{'password'};
    # Auth succeed ? lets promote him to owner of the room
    if ($room->{owner_password} && Crypt::SaltedHash->validate($room->{owner_password}, $pass)){
      $self->session($room->{name}, {role => 'owner'});
      $self->associate_key_to_room(
        room => $room->{name},
        key  => $self->session('key'),
        role => 'owner'
      );
      return $self->render(
        json => {
          msg    => $self->l('AUTH_SUCCESS')
        }
      );
    }
    # Oner password is set, but auth failed
    elsif ($room->{owner_password}){
      return $self->render(
        json => {
          msg => $self->l('WRONG_PASSWORD'),
          err => 'WRONG_PASSWORD'
        },
        status => 401
      );
    }
    # There's no owner password, so you cannot auth
    return $self->render(
      json => {
        msg => $self->l('NOT_ALLOWED'),
        err => 'NOT_ALLOWED',
      },
      status => 403
    );
  }
  # Return configuration for SimpleWebRTC
  elsif ($req->{action} eq 'get_rtc_conf'){
    my $resp = {
      url => $config->{'signaling.uri'},
      peerConnectionConfig => {
        iceServers => []
      },
      autoRequestMedia => Mojo::JSON::true,
      enableDataChannels => Mojo::JSON::true,
      debug => Mojo::JSON::false,
      detectSpeakingEvents => Mojo::JSON::true,
      adjustPeerVolume => Mojo::JSON::false,
      autoAdjustMic => Mojo::JSON::false,
      harkOptions => {
        interval => 300,
        threshold => -20
      },
      media => {
        audio => Mojo::JSON::true,
        video => {
          mandatory => {
            maxFrameRate => $config->{'video.frame_rate'}
          }
        }
      },
      localVideo => {
        autoplay => Mojo::JSON::true,
        mirror => Mojo::JSON::false,
        muted => Mojo::JSON::true
      }
    };
    if ($config->{'turn.stun_server'}){
      if (ref $config->{'turn.stun_server'} ne 'ARRAY'){
        $config->{'turn.stun_server'} = [ $config->{'turn.stun_server'} ];
      }
      foreach my $s (@{$config->{'turn.stun_server'}}){
        push @{$resp->{peerConnectionConfig}->{iceServers}}, { url => $s };
      }
    }
    if ($config->{'turn.turn_server'}){
      if (ref $config->{'turn.turn_server'} ne 'ARRAY'){
        $config->{'turn.turn_server'} = [ $config->{'turn.turn_server'} ];
      }
      foreach my $t (@{$config->{'turn.turn_server'}}){
        my $turn = { url => $t };
        ($turn->{username},$turn->{credential}) = $self->get_turn_creds($room->{name});
        push @{$resp->{peerConnectionConfig}->{iceServers}}, $turn;
      }
    }
    return $self->render(
      json => {
        config => $resp
      }
    );
  }
  # Return just room config
  elsif ($req->{action} eq 'get_room_conf'){
    return $self->render(
      json => {
        owner_auth   => ($room->{owner_password}) ? 'yes' : 'no',
        join_auth    => ($room->{join_password})  ? 'yes' : 'no',
        locked       => ($room->{locked})         ? 'yes' : 'no',
        ask_for_name => ($room->{ask_for_name})   ? 'yes' : 'no',
        persistent   => ($room->{persistent})     ? 'yes' : 'no',
        max_members  => $room->{max_members},
        notif        => $self->get_email_notifications($room->{name}),
      }
    );
  }
  # Return your role and various info about the room
  elsif ($req->{action} eq 'get_room_info'){
    my $peer_id = $req->{param}->{peer_id};
    if ($self->session($room->{name}) && $self->session($room->{name})->{role}){
      # If we just have been promoted to owner
      if ($self->session($room->{name})->{role} ne 'owner' &&
          $self->get_peer_role({room => $room->{name}, peer_id => $peer_id}) &&
          $self->get_peer_role({room => $room->{name}, peer_id => $peer_id}) eq 'owner'){
        $self->session($room->{name})->{role} = 'owner';
        $self->associate_key_to_room(
          room => $room->{name},
          key  => $self->session('key'),
          role => 'owner'
        );
      }
      my $res = $self->set_peer_role({
        room    => $room->{name},
        peer_id => $peer_id,
        role    => $self->session($room->{name})->{role}
      });
      if (!$res){
        return $self->render(
          json => {
            msg => $self->l('ERROR_OCCURRED'),
            err => 'ERROR_OCCURRED'
          },
          status => 503
        );
      }
    }
    return $self->render(
      json => {
        role         => $self->session($room->{name})->{role},
        owner_auth   => ($room->{owner_password}) ? 'yes' : 'no',
        join_auth    => ($room->{join_password})  ? 'yes' : 'no',
        locked       => ($room->{locked})         ? 'yes' : 'no',
        ask_for_name => ($room->{ask_for_name})   ? 'yes' : 'no',
        max_members  => $room->{max_members},
        notif        => $self->get_email_notifications($room->{name}),
      },
    );
  }
  # Return the role of a peer
  elsif ($req->{action} eq 'get_peer_role'){
    my $peer_id = $req->{param}->{peer_id};
    if (!$peer_id){
      return $self->render(
        json => {
          msg => $self->l('ERROR_PEER_ID_MISSING'),
          err => 'ERROR_PEER_ID_MISSING'
        },
        status => 400
      );
    }
    my $role = $self->get_peer_role({room => $room->{name}, peer_id => $peer_id});
    if (!$role){
      return $self->render(
        json => {
          msg => $self->l('ERROR_PEER_NOT_FOUND'),
          err => 'ERROR_PEER_NOT_FOUND'
        },
        status => 400
      );
    }
    return $self->render(
      json => {
        role => $role,
      }
    );
  }
  # Notify the backend when we join a room
  elsif ($req->{action} eq 'join'){
    my $name = $req->{param}->{name} || '';
    my $subj = sprintf($self->l('s_JOINED_ROOM_s'), ($name eq '') ? $self->l('SOMEONE') : $name, $room->{name});
    # Send notifications
    my $recipients = $self->get_email_notifications($room->{name});
    foreach my $rcpt (keys %{$recipients}){
      $self->app->log->debug('Sending an email to ' . $recipients->{$rcpt}->{email});
      my $sent = $self->mail(
        to      => $recipients->{$rcpt}->{email},
        subject => $subj,
        data    => $self->render_mail('notification',
          room => $room->{name},
          name => $name
        )
      );
    }
    return $self->render(
      json => {}
    );
  }
  # Promote a participant to be owner of a room
  elsif ($req->{action} eq 'promote_peer'){
    my $peer_id = $req->{param}->{peer_id};
    if (!$peer_id){
      return $self->render(
        json => {
          msg => $self->l('ERROR_PEER_ID_MISSING'),
          err => 'ERROR_PEER_ID_MISSING'
        },
        status => 400
      );
    }
    elsif ($self->promote_peer({room => $room->{name}, peer_id => $peer_id})){
      return $self->render(
        json => {
          msg => $self->l('PEER_PROMOTED')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED'
      },
      status => 503
    );
  }
  # Wipe room data (chat history and etherpad content)
  elsif ($req->{action} eq 'wipe_data'){
    if (!$ec || ($ec->delete_pad($room->{etherpad_group} . '$' . $room->{name}) &&
           $self->create_pad($room->{name}) &&
           $self->create_etherpad_session($room->{name}))){
      return $self->render(
        json => {
          msg => $self->l('DATA_WIPED')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
  # Get a new etherpad session
  elsif ($req->{action} eq 'get_pad_session'){
    if ($self->create_etherpad_session($room->{name})){
      return $self->render(
        json => {
          msg => $self->l('SESSION_CREATED')
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      styaus => 503
    );
  }
  # Delete a room
  elsif ($req->{action} eq 'delete_room'){
    if ($self->delete_room($room->{name})){
      return $self->render(
        json => {
          msg => $self->l('ROOM_DELETED'),
        }
      );
    }
    return $self->render(
      json => {
        msg => $self->l('ERROR_OCCURRED'),
        err => 'ERROR_OCCURRED',
      },
      status => 503
    );
  }
};

group {
  under '/admin' => sub {
    my $self = shift;
    # For now, lets just pretend that anyone able to access
    # /admin is already logged in (auth is managed outside of VROOM)
    # TODO: support several auth method, including an internal one where user are managed
    # in our DB, and another where auth is handled by the web server
    $self->login;
    $self->make_key_admin($self->session('key'));
    $self->purge_rooms;
    $self->stash(admin => 1);
    return 1;
  };

  # Admin index
  get '/' => sub {
    my $self = shift;
    return $self->render('admin');
  };

  # Room management
  get '/rooms' => sub {
    my $self = shift;
    return $self->render('admin_manage_rooms');
  };
};

# Catch all route: if nothing else match, it's the name of a room
get '/:room' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  my $video = $self->param('video') || '1';
  my $token = $self->param('token') || undef;
  # Redirect to lower case
  if ($room ne lc $room){
    $self->redirect_to($self->get_url('/') . lc $room);
  }
  $self->purge_rooms;
  $self->purge_invitations;
  my $res = $self->valid_room_name($room);
  if (!$self->valid_room_name($room)){
    return $self->render('error',
      msg  => $self->l('ERROR_NAME_INVALID'),
      err  => 'ERROR_NAME_INVALID',
      room => $room
    );
  }
  my $data = $self->get_room_by_name($room);
  unless ($data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  # Create a session if not already done
  $self->login;
  # If the room is locked and we're not the owner, we cannot join it !
  if ($data->{'locked'} &&
      (!$self->session($room) ||
       !$self->session($room)->{role} ||
       $self->session($room)->{role} ne 'owner')){
    return $self->render('error',
      msg => sprintf($self->l("ERROR_ROOM_s_LOCKED"), $room),
      err => 'ERROR_ROOM_s_LOCKED',
      room => $room,
      ownerPass => ($data->{owner_password}) ? '1':'0'
    );
  }
  # If we've reached the members' limit
  my $limit = $self->get_member_limit($room);
  if ($limit > 0 && $self->get_room_members($room) >= $limit){
    return $self->render('error',
      msg  => $self->l("ERROR_TOO_MANY_MEMBERS"),
      err  => 'ERROR_TOO_MANY_MEMBERS',
      room => $room,
    );
  }
  # Now, if the room is password protected and we're not a participant, nor the owner, lets prompt for the password
  # Email invitation have a token which can be used instead of password
  if ($data->{join_password} &&
     (!$self->session($room) ||
      $self->session($room)->{role} !~ m/^participant|owner$/) &&
     !$self->check_invite_token($room,$token)){
    return $self->redirect_to($self->get_url('/password') . $room);
  }
  # Set this peer as a simple participant if he has no role yet (shouldn't happen)
  if (!$self->session($room) || !$self->session($room)->{role}){
    $self->session($room => {role => 'participant'});
    $self->associate_key_to_room(
      room => $room,
      key  => $self->session('key'),
      role => 'participant'
    );
  }
  # Create etherpad session if needed
  if ($ec && !$self->session($room)->{etherpadSession}){
    # pad doesn't exist yet ?
    if (!$data->{etherpad_group}){
      $self->create_pad($room);
      # Reload data so we get the etherpad_group
      $data = $self->get_room_by_name($room);
    }
    $self->create_etherpad_session($room);
  }
  # Now display the room page
  return $self->render('join',
    moh           => $self->choose_moh(),
    video         => $video,
    etherpad      => ($ec) ? 'true' : 'false',
    etherpadGroup => $data->{etherpad_group},
    ua            => $self->req->headers->user_agent
  );
};

# use the templates defined in the config
push @{app->renderer->paths}, 'templates/'.$config->{'interface.template'};
# Set the secret used to sign cookies
app->secrets([$config->{'cookie.secret'}]);
app->sessions->secure(1);
app->sessions->cookie_name($config->{'cookie.name'});
app->hook(before_dispatch => sub {
  my $self = shift;
  # Switch to the desired language
  if ($self->session('language')){
    $self->languages($self->session('language'));
  }
  # Stash the configuration hashref
  $self->stash(config => $config);

  # Check db is available
  if ($error){
    return $self->render('error',
      msg => $self->l($error),
      err => $error,
      room => ''
    );
  }
});

if (!app->db){
  $error = 'ERROR_DB_UNAVAILABLE';
}
if (!app->check_db_version){
  $error = 'ERROR_DB_VERSION_MISMATCH';
}

# Are we running in hypnotoad ?
app->config(
  hypnotoad => {
    listen   => ['http://' . $config->{'daemon.listen_ip'} . ':' . $config->{'daemon.listen_port'}],
    pid_file => $config->{'daemon.pid_file'},
    proxy    => 1
  }
);

app->log->info('Starting VROOM daemon');
# And start, lets VROOM !!
app->start;

