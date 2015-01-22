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
use MIME::Base64;
use File::stat;
use File::Basename;
use Etherpad::API;
use Session::Token;
use Config::Simple;
use Email::Valid;
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
$config->{'turn.turn_server'}                  ||= '';
$config->{'turn.realm'}                        ||= 'vroom';
$config->{'email.from '}                       ||= 'vroom@example.com';
$config->{'email.contact'}                     ||= 'admin@example.com';
$config->{'email.sendmail'}                    ||= '/sbin/sendmail';
$config->{'interface.powered_by'}              ||= '<a href="http://www.firewall-services.com" target="_blank">Firewall Services</a>';
$config->{'interface.template'}                ||= 'default';
$config->{'interface.chrome_extension_id'}     ||= 'ecicdpoejfllflombfanbhfpgcimjddn';
$config->{'cookie.secret'}                     ||= 'secret';
$config->{'cookie.name'}                       ||= 'vroom';
$config->{'rooms.inactivity_timeout'}          ||= 60;
$config->{'rooms.reserved_inactivity_timeout'} ||= 86400;
$config->{'rooms.common_names'}                ||= '';
$config->{'log.level'}                         ||= 'info';
$config->{'etherpad.uri'}                      ||= '';
$config->{'etherpad.api_key'}                  ||= '';
$config->{'etherpad.base_domain'}              ||= '';
$config->{'daemon.listen_ip'}                  ||= '127.0.0.1';
$config->{'daemon.listen_port'}                ||= '8090';
$config->{'daemon.backend'}                    ||= 'hypnotoad';

# Set log level
app->log->level($config->{'log.level'});

# Create etherpad api client if required
our $ec = undef;
if ($config->{'etherpad.uri'} =~ m/https?:\/\/.*/ && $config->{'etherpad.api_key'} ne ''){
  $ec = Etherpad::API->new({
    url => $config->{'etherpad.uri'},
    apikey => $config->{'etherpad.api_key'}
  });
}

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
    mysql_enable_utf8 => 1,
    RaiseError        => 1,
    PrintError        => 0
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
  my @reserved = qw(about help feedback feedback_thanks goodbye admin create localize api
                    missing dies password kicked invitation js css img fonts snd);
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
# TODO: replace with Email::Valid
helper valid_email => sub {
  my $self = shift;
  my ($email) = @_;
  return Email::Valid->address($email);
};

##########################
#   Various helpers      #
##########################

# Create a cookie based session
helper login => sub {
  my $self = shift;
  my $ret = {};
  if ($self->session('name')){
    return 1;
  }
  my $login = $ENV{'REMOTE_USER'} || lc $self->get_random(256);
  my $key = $self->get_random(256);
  my $sth = eval {
    $self->db->prepare('INSERT INTO `api_keys`
                         (`token`,`not_after`)
                         VALUES (?,DATE_ADD(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL 24 HOUR))');
  };
  $sth->execute($key);
  $self->session(
    name => $login,
    ip   => $self->tx->remote_address,
    key  => $key
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
                           `owner`,
                           `token`,
                           `realm`)
                          VALUES (?,
                                  CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'),
                                  CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'),
                                  ?,
                                  ?,
                                  ?)');
  };
  $sth->execute(
    $name,
    $owner,
    $self->get_random(256),
    $config->{'turn.realm'}
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
  if (($room->{locked} && $room->{locked} !~ m/^0|1$/) ||
      ($room->{ask_for_name} && $room->{ask_for_name} !~ m/^0|1$/) ||
      ($room->{persistent} && $room->{persistent} !~ m/^0|1$/)){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('UPDATE `rooms`
                          SET `owner`=?,
                              `locked`=?,
                              `ask_for_name`=?,
                              `join_password`=?,
                              `owner_password`=?,
                              `persistent`=?
                          WHERE `id`=?');
  };
  $sth->execute(
    $room->{owner},
    $room->{locked},
    $room->{ask_for_name},
    $room->{join_password},
    $room->{owner_password},
    $room->{persistent},
    $room->{id}
  );
  $self->app->log->info("Room " . $room->{name} ." modified by " . $self->session('name'));
  return 1;
};

# Add a participant in the database. Used by the signaling server to check
# if user is allowed
helper add_participant_to_room => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room_by_name($name);
  if (!$room){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('INSERT INTO `room_participants`
                          (`room_id`,`participant`,`last_activity`)
                          VALUES (?,?,CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'))
                          ON DUPLICATE KEY UPDATE `last_activity`=CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\')');
  };
  $sth->execute(
    $room->{id},
    $participant
  );
  $self->app->log->info($self->session('name') . " joined the room $name");
  return 1;
};

# Remove participant from the DB
# Takes two args: room name and user name
helper remove_participant_from_room => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room_by_name($name);
  if (!$room){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('DELETE FROM `room_participants`
                          WHERE `id`=?
                            AND `participant`=?');
  };
  $sth->execute(
    $room->{id},
    $participant
  );
  $self->app->log->info($self->session('name') . " leaved the room $name");
  return 0;
};

# Get a list of participants of a room
helper get_participants_list => sub {
  my $self = shift;
  my ($name) = @_;
  my $room = $self->get_room_by_name($name);
  if (!$room){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('SELECT `participant`,`room_id`
                          FROM `room_participants`
                          WHERE `room_id`=?');
  };
  $sth->execute($room->{id});
  return $sth->fetchall_hashref('room_id');
};

# Set the role of a peer
helper set_peer_role => sub {
  my $self = shift;
  my ($data) = @_;
  # Check if this ID isn't the one from another peer first
  my $sth = eval {
    $self->db->prepare('SELECT COUNT(`p`.`id`)
                          FROM `room_participants` `p`
                          LEFT JOIN `rooms` `r` ON `p`.`room_id`=`r`.`id`
                          WHERE `p`.`peer_id`=?
                            AND `p`.`participant`!=?
                            AND `r`.`name`=?');
  };
  $sth->execute($data->{peer_id},$data->{name},$data->{room});
  my $num;
  $sth->bind_columns(\$num);
  $sth->fetch;
  if ($num > 0){
    return 0;
  }
  $sth = eval {
    $self->db->prepare('UPDATE `room_participants` `p`
                          LEFT JOIN `rooms` `r` ON `p`.`room_id`=`r`.`id`
                          SET `p`.`peer_id`=?,
                              `p`.`role`=?
                          WHERE `p`.`participant`=?
                            AND `r`.`name`=?');
  };
  $sth->execute(
    $data->{peer_id},
    $data->{role},
    $data->{name},
    $data->{room}
  );
  $self->app->log->info("User " . $data->{name} . " (peer id " . 
                          $data->{peer_id} . ") has now the " .
                          $data->{role} . " role in room " . $data->{room});
  return 1;
};

# Return the role of a peer, from it's signaling ID
helper get_peer_role => sub {
  my $self = shift;
  my ($data) = @_;
  my $sth = eval {
    $self->db->prepare('SELECT `p`.`role`
                          FROM `room_participants` `p`
                          LEFT JOIN `rooms` `r` ON `p`.`room_id`=`r`.`id`
                          WHERE `p`.`peer_id`=?
                            AND `r`.`name`=?
                          LIMIT 1');
  };
  $sth->execute(
    $data->{peer_id},
    $data->{room}
  );
  my $role;
  $sth->bind_columns(\$role);
  $sth->fetch;
  return $role;
};

# Promote a peer to owner
helper promote_peer => sub {
  my $self = shift;
  my ($data) = @_;
  my $sth = eval {
    $self->db->prepare('UPDATE `room_participants` `p`
                          LEFT JOIN `rooms` `r` ON `p`.`room_id`=`r`.`id`
                          SET `p`.`role`=\'owner\'
                          WHERE `p`.`peer_id`=?
                            AND `r`.`name`=?');
  };
  $sth->execute(
    $data->{peer_id},
    $data->{room}
  );
  return 1;
};

# Check if a participant has joined a room
# Takes a hashref room => room name and name => session name
helper has_joined => sub {
  my $self = shift;
  my ($data) = @_;
  my $sth = eval {
    $self->db->prepare('SELECT COUNT(`r`.`id`)
                          FROM `rooms` `r`
                          LEFT JOIN `room_participants` `p` ON `r`.`id`=`p`.`room_id`
                          WHERE `r`.`name`=?
                            AND `p`.`participant`=?');
  };
  $sth->execute(
    $data->{room},
    $data->{name}
  );
  my $num;
  $sth->bind_columns(\$num);
  $sth->fetch;
  return ($num == 1) ? 1 : 0 ;
};

# Purge disconnected participants from the DB
helper purge_participants => sub {
  my $self = shift;
  $self->app->log->debug('Removing inactive participants from the database');
  my $sth = eval {
    $self->db->prepare('DELETE FROM `room_participants`
                          WHERE `last_activity` < DATE_SUB(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL 10 MINUTE)
                            OR `last_activity` IS NULL');
  };
  $sth->execute;
  return 1;
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
helper ping_room => sub {
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
  $sth = eval {
    $self->db->prepare('UPDATE `room_participants`
                          SET `last_activity`=CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\')
                          WHERE `id`=?
                            AND `participant`=?');
  };
  $sth->execute(
    $data->{id},
    $self->session('name')
  );
  $self->app->log->debug($self->session('name') . " pinged the room $name");
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
helper get_notification => sub {
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
    $self->session('name'),
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
  if (!$data->{action}){
    return 0;
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
  my $actions = API_ACTIONS;
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

# Route for the help page
get '/help' => 'help';

# Route for the admin pages
get '/admin/:room' => { room => '' } => sub {
  my $self = shift;
  my $room = $self->stash('room');
  # Someone accessing /admin is considered an admin
  # For now, the auth is handled outside of VROOM itself
  my $token = $self->req->headers->header('X-VROOM-API-Key');
  $self->make_key_admin($token);
  if ($room eq ''){
    $self->purge_rooms;
    return $self->render('admin');
  }
  my $data = $self->get_room_by_name($room);
  if (!$data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->purge_participants;
  return $self->render('manage_room',
    room         => $room,
    participants => scalar keys %{$self->get_participants_list($room)}
  );
};

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
  if ($self->get_room_by_name($room) && $self->session('name')){
    $self->remove_participant_from_room(
      $room,
      $self->session('name')
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
  $self->remove_participant_from_room(
    $room,
    $self->session('name')
  );
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

# This handler room creation
post '/create' => sub {
  my $self = shift;
  # No name provided ? Lets generate one
  my $name = $self->param('roomName') || $self->get_random_name();
  # Create a session for this user, but don't set a role for now
  $self->login;
  my $json = {
    status => 'error',
    err    => 'ERROR_OCCURRED',
    msg    => $self->l('ERROR_OCCURRED'),
    room   => $name
  };
  # Cleanup unused rooms before trying to create it
  $self->purge_rooms;
  if (!$self->valid_room_name($name)){
    $json->{err} = 'ERROR_NAME_INVALID';
    $json->{msg} = $self->l('ERROR_NAME_INVALID');
    return $self->render(json => $json);
  }
  elsif ($self->get_room_by_name($name)){
    $json->{err} = 'ERROR_NAME_CONFLICT';
    $json->{msg} = $self->l('ERROR_NAME_CONFLICT');
    return $self->render(json => $json);
  }
  if (!$self->create_room($name,$self->session('name'))){
    $json->{err} = 'ERROR_OCCURRED';
    $json->{msg} = $self->l('ERROR_OCCURRED');
    return $self->render(json => $json);
  }
  $json->{status} = 'success';
  $json->{err}    = '';
  $self->session($name => {role => 'owner'});
  $self->associate_key_to_room(
    room => $name,
    key  => $self->session('key'),
    role => 'owner'
  );
  return $self->render(json => $json);
};

# Translation for JS resources
# As there's no way to list all the available translated strings
# we just maintain a list of strings needed
get '/localize/:lang' => { lang => 'en' } => sub {
  my $self = shift;
  my $strings = {};
  foreach my $string (JS_STRINGS){
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
        status => 'error',
        msg    => $err
      },
      status => 503
    );
  }   
  # Handle requests authorized for anonymous users righ now
  if ($req->{action} eq 'switch_lang'){
    if (!grep { $req->{param}->{language} eq $_ } @supported_lang){
      return $self->render(
        json => {
          status => 'error',
          msg    => 'UNSUPPORTED_LANG'
        },
        status => 503
      );
    }
    $self->session(language => $req->{param}->{language});
    return $self->render(
      json => {
        status => 'success',
      }
    );
  }

  # Now, lets check if the key can do the requested action
  my $res = $self->key_can_do_this(
    token  => $token,
    action => $req->{action},
    param  => $req->{param}
  );

  # Here are mthod not tied to a room
  if ($req->{action} eq 'get_room_list'){
    my $rooms = $self->get_room_list;
    # Blank out a few param we don't need
    foreach my $r (keys %{$rooms}){
      foreach my $p (qw/join_password owner_password owner token etherpad_group/){
        delete $rooms->{$r}->{$p};
      }
    }
    return $self->render(
      json => {
        status => 'success',
        rooms  => $rooms
      }
    );
  }

  $room = $self->get_room_by_name($req->{param}->{room});
  if (!$res || (!$room && $req->{param}->{room})){
    return $self->render(
      json => {
        status => 'error',
        msg    => 'NOT_ALLOWED'
      },
      status => '403'
    );
  }
  # Ok, now, we don't have to bother with authorization anymore
  if ($req->{action} eq 'invite_email'){
    if (!$req->{param}->{rcpt} || $req->{param}->{rcpt}!~ m/\S+@\S+\.\S+$/){
      return $self->render(
        json => {
          status => 'error',
          msg    => 'ERROR_MAIL_INVALID'
        }
      );
    }
    my $token = $self->add_invitation(
      $req->{param}->{room},
      $req->{param}->{rcpt}
    );
    my $sent = $self->mail(
      to      => $req->{param}->{rcpt},
      subject => $self->l("EMAIL_INVITATION"),
      data    => $self->render_mail('invite',
        room     => $req->{param}->{room},
        message  => $req->{param}->{message},
        token    => $token,
        joinPass => ($room->{join_password}) ? 'yes' : 'no'
      )
    );
    if ($token && $sent){
      $self->app->log->info("Email invitation to join room " . $req->{param}->{room} . " sent to " . $req->{param}->{rcpt});
      return $self->render(
        json => {
          status => 'success',
          msg    => sprintf($self->l('INVITE_SENT_TO_s'), $req->{param}->{rcpt})
        }
      );
    }
    return $self->render(
      json => {
        status => 'error',
        msg    => 'ERROR_OCCURRED'
      }
    );
  }
  # Handle room lock/unlock
  elsif ($req->{action} =~ m/(un)?lock_room/){
    $room->{locked} = ($req->{action} eq 'lock_room') ? '1':'0';
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          status => 'success',
          msg => $self->l(($req->{action} eq 'lock_room') ? 'ROOM_LOCKED' : 'ROOM_UNLOCKED')
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  # Handle activity pings sent every minute by each participant
  elsif ($req->{action} eq 'ping'){
    $self->ping_room($room->{name});
    # Cleanup expired rooms every ~10 pings
    if ((int (rand 100)) <= 10){
      $self->purge_rooms;
      $self->purge_invitations;
      $self->purge_participants;
    }
    # Check if we got any invitation response to process
    my $invitations = $self->get_invitation_list($self->session('name'));
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
        msg    => $msg,
        status => 'success'
      }
    );
  }
  # Update room configuration
  elsif ($req->{action} eq 'update_room_conf'){
    $room->{locked} = ($req->{param}->{locked}) ? '1' : '0';
    $room->{ask_for_name} = ($req->{param}->{ask_for_name}) ? '1' : '0';
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
          status => 'success',
          msg    => $self->l('ROOM_CONFIG_UPDATED')
        }
      );
    }
    return $self->render(
      json => {
        status => 'error',
        msg    => $self->l('ERROR_OCCURRED')
      }
    );
  }
  # Handle password (join and owner)
  elsif ($req->{action} eq 'set_join_password'){
    $room->{join_password} = ($req->{param}->{password} && $req->{param}->{password} ne '') ?
      Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($req->{param}->{password})->generate : undef;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg    => $self->l(($req->{param}->{password}) ? 'PASSWORD_PROTECT_SET' : 'PASSWORD_PROTECT_UNSET'),
          status => 'success'
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  elsif ($req->{action} eq 'set_owner_password'){
    if (grep { $req->{param}->{room} eq $_ } (split /[,;]/, $config->{'rooms.common_names'})){
      return $self->render(
        json => {
          status => 'error',
          msg    => $self->l('ERROR_COMMON_ROOM_NAME')
        }
      );
    }
    $room->{owner_password} = ($req->{param}->{password} && $req->{param}->{password} ne '') ?
      Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($req->{param}->{password})->generate : undef;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          msg    => $self->l(($req->{param}->{password}) ? 'ROOM_NOW_RESERVED' : 'ROOM_NO_MORE_RESERVED'),
          status => 'success'
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  elsif ($req->{action} eq 'set_persistent'){
    my $set = $self->param('set');
    $room->{persistent} = ($set eq 'on') ? 1 : 0;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          status => 'success',
          msg    => $self->l(($set eq 'on') ? 'ROOM_NOW_PERSISTENT' : 'ROOM_NO_MORE_PERSISTENT')
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  # Set/unset askForName
  elsif ($req->{action} eq 'set_ask_for_name'){
    my $set = $req->{param}->{set};
    $room->{ask_for_name} = ($set eq 'on') ? 1 : 0;
    if ($self->modify_room($room)){
      return $self->render(
        json => {
          status => 'success',
          msg => $self->l(($set eq 'on') ? 'FORCE_DISPLAY_NAME' : 'NAME_WONT_BE_ASKED')
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  # Add or remove an email address to the list of email notifications
  elsif ($req->{action} eq 'email_notification'){
    my $email = $req->{param}->{email};
    my $set = $req->{param}->{set};
    if (!$self->valid_email($email)){
      return $self->render(
        json => {
          msg    => $self->l('ERROR_MAIL_INVALID'),
          status => 'error'
        }
      );
    }
    elsif ($set eq 'on' && $self->add_notification($room->{name},$email)){
      return $self->render(
        json => {
          status => 'success',
          msg    => sprintf($self->l('s_WILL_BE_NOTIFIED'), $email)
        }
      );
    }
    elsif ($set eq 'off' && $self->remove_notification($room->{name},$email)){
      return $self->render(
        json => {
          status => 'success',
          msg    => sprintf($self->l('s_WONT_BE_NOTIFIED_ANYMORE'), $email)
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
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
          status => 'success',
          msg    => $self->l('AUTH_SUCCESS')
        }
      );
    }
    # Oner password is set, but auth failed
    elsif ($room->{owner_password}){
      return $self->render(
        json => {
          status => 'error',
          msg    => $self->l('WRONG_PASSWORD')
        }
      );
    }
    # There's no owner password, so you cannot auth
    return $self->render(
      json => {
        msg    => $self->l('NOT_ALLOWED'),
        status => 'error'
      }
    );
  }
  # Return your role and various info about the room
  elsif ($req->{action} eq 'get_room_info'){
    my $peer_id = $req->{param}->{peer_id};
    if ($self->session($room->{name}) && $self->session($room->{name})->{role}){
      # If we just have been promoted to owner
      if ($self->session($room->{name})->{role} ne 'owner' &&
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
        name    => $self->session('name'),
        peer_id => $peer_id,
        role    => $self->session($room->{name})->{role}
      });
      if (!$res){
        return $self->render(
          json => {
            status => 'error',
            msg    => $self->l('ERROR_OCCURRED')
          }
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
        notif        => $self->get_notification($room->{name}),
        status       => 'success'
      },
    );
  }
  # Return the role of a peer
  elsif ($req->{action} eq 'get_peer_role'){
    my $peer_id = $req->{param}->{peer_id};
    my $role = $self->get_peer_role({room => $room->{name}, peer_id => $peer_id});
    return $self->render(
      json => {
        role => $role,
        status => 'success'
      }
    );
  }
  # Notify the backend when we join a room
  elsif ($req->{action} eq 'join'){
    my $name = $req->{param}->{name} || '';
    my $subj = sprintf($self->l('s_JOINED_ROOM_s'), ($name eq '') ? $self->l('SOMEONE') : $name, $room);
    # Send notifications
    my $recipients = $self->get_notification($room);
    foreach my $rcpt (keys %{$recipients}){
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
      json => {
        status => 'success'
      }
    );
  }
  # Promote a participant to be owner of a room
  elsif ($req->{action} eq 'promote_peer'){
    my $peer_id = $req->{param}->{peer_id};
    if ($peer_id && $self->promote_peer({room => $room->{name}, peer_id => $peer_id})){
      return $self->render(
        json => {
          status => 'success',
          msg    => $self->l('PEER_PROMOTED')
        }
      );
    }
    return $self->render(
      json => {
        status => 'error',
        msg    => $self->l('ERROR_OCCURRED')
      }
    );
  }
  # Wipe room data (chat history and etherpad content)
  elsif ($req->{action} eq 'wipe_data'){
    if (!$ec || ($ec->delete_pad($room->{etherpad_group} . '$' . $room->{name}) &&
           $self->create_pad($room->{name}) &&
           $self->create_etherpad_session($room->{name}))){
      return $self->render(
        json => {
          status => 'success',
          msg    => $self->l('DATA_WIPED')
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  # Get a new etherpad session
  elsif ($req->{action} eq 'get_pad_session'){
    if ($self->create_etherpad_session($room->{name})){
      return $self->render(
        json => {
          status => 'success',
          msg    => $self->l('SESSION_CREATED')
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
  # Delete a room
  elsif ($req->{action} eq 'delete_room'){
    if ($self->delete_room($room->{name})){
      return $self->render(
        json => {
          msg    => $self->l('ROOM_DELETED'),
          status => 'success'
        }
      );
    }
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURRED'),
        status => 'error'
      }
    );
  }
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
    }
    $self->create_etherpad_session($room);
  }
  # Short life cookie to negociate a session with the signaling server
  $self->cookie(vroomsession => encode_base64(
    $self->session('name') . ':' . $data->{name} . ':' . $data->{token}, ''),
    {
      expires => time + 60,
      path => '/'
    }
  );
  # Add this user to the participants table
  if (!$self->add_participant_to_room($room, $self->session('name'))){
    return $self->render('error',
      msg  => $self->l('ERROR_OCCURRED'),
      err  => 'ERROR_OCCURRED',
      room => $room
    );
  }
  # Now display the room page
  return $self->render('join',
    moh           => $self->choose_moh(),
    turnPassword  => $data->{token},
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
});
# Are we running in hypnotoad ?
app->config(
  hypnotoad => {
    listen   => ['http://' . $config->{'daemon.listen_ip'} . ':' . $config->{'daemon.listen_port'}],
    pid_file => '/tmp/vroom.pid',
    proxy    => 1
  }
);
# And start, lets VROOM !!
app->start;

