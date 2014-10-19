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
$config->{'rooms.inactivity_timeout'}          ||= 3600;
$config->{'rooms.reserved_inactivity_timeout'} ||= 5184000;
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
  my @reserved = qw(about help feedback feedback_thanks goodbye admin create localize action
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
  $self->session(
      name => $login,
      ip   => $self->tx->remote_address
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
  $sth->execute($room->{id},$participant);
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
  $sth->execute($room->{id},$participant);
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
    $self->db->prepare('SELECT `participant`
                          FROM `room_participants`
                          WHERE `room_id`=?');
  };
  $sth->execute($room->{id});
  return $sth->fetchall_hashref('room_id')->{$room->{id}};
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
  $sth->execute($data->{peer_id},$data->{room});
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
  $sth->execute($data->{peer_id},$data->{room});
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
  $sth->execute($data->{room},$data->{name});
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
# TODO: rewrite to return a hashref with full room data
helper get_all_rooms => sub {
  my $self = shift;
  my @rooms;
  my $sth = eval {
    $self->db->prepare('SELECT `name`
                          FROM `rooms`');
  };
  $sth->execute;
  while (my $name = $sth->fetchrow_array){
    push @rooms, $name;
  }
  return @rooms;
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
  $sth->execute($data->{id},$self->session('name'));
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
  if (!$data){
    return 0;
  }
  my $sth = eval {
    $self->db->prepare('INSERT INTO `email_notifications`
                          (`room_id`,`email`)
                          VALUES (?,?)');
  };
  $sth->execute($data->{id},$email);
  $self->app->log->debug($self->session('name') . 
       " has added $email to the list of email which will be notified when someone joins room $room");
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
  $sth->execute($data->{id},$email);
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

helper respond_invitation => sub {
  my $self = shift;
  my ($id,$response,$message) = @_;
  my $sth = eval {
    $self->db->prepare('UPDATE `email_invitations`
                          SET `response`=?,
                              `message`=?
                          WHERE `token`=?');
  } || return undef;
  $sth->execute($response,$message,$id) || return undef;
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
helper delete_invitations => sub {
  my $self = shift;
  $self->app->log->debug('Removing expired invitations');
  my $sth = eval {
    $self->db->prepare('DELETE FROM `email_invitations`
                          WHERE `date` < DATE_SUB(CONVERT_TZ(NOW(), @@session.time_zone, \'+00:00\'), INTERVAL 2 HOUR)');
  } || return undef;
  $sth->execute || return undef;
  return 1;
};

# Check an invitation token is valid
helper check_invite_token => sub {
  my $self = shift;
  my ($room,$token) = @_;
  # Expire invitations before checking if it's valid
  $self->delete_invitations;
  $self->app->log->debug("Checking if invitation with token $token is valid for room $room");
  my $ret = 0;
  my $data = $self->get_room_by_name($room);
  if (!$data || !$token){
    return undef;
  }
  my $sth = eval {
    $self->db->prepare('SELECT *
                          FROM `email_invitations`
                          WHERE `room_id`=?
                          AND `token`=?
                          AND (`response` IS NULL
                                OR `response`=\'later\')');
  } || return undef;
  $sth->execute($data->{id},$token) || return undef;
  if ($sth->rows == 1){
    $ret = 1;
    $self->app->log->debug("Invitation is valid");
  }
  else{
    $self->app->log->debug("Invitation is invalid");
  }
  return $ret;
};

# Create a pad (and the group if needed)
helper create_pad => sub {
  my $self = shift;
  my ($room) = @_;
  return undef unless ($ec);
  my $data = $self->get_room_by_name($room);
  return undef unless ($data);
  if (!$data->{etherpad_group}){
    my $group = $ec->create_group() || undef;
    return undef unless ($group);
    my $sth = eval {
      $self->db->prepare('UPDATE `rooms`
                            SET `etherpad_group`=?
                            WHERE `name`=?');
    } || return undef;
    $sth->execute($group,$room) || return undef;
    $data = $self->get_room_by_name($room);
  }
  $ec->create_group_pad($data->{etherpad_group},$room) || return undef;
  $self->app->log->debug("Pad for room $room created (group " . $data->{etherpad_group} . ")");
  return 1;
};

# Create an etherpad session for a user
helper create_etherpad_session => sub {
  my $self = shift;
  my ($room) = @_;
  return undef unless ($ec);
  my $data = $self->get_room_by_name($room);
  return undef unless ($data && $data->{etherpad_group});
  my $id = $ec->create_author_if_not_exists_for($self->session('name'));
  $self->session($room)->{etherpadAuthorId} = $id;
  my $etherpadSession = $ec->create_session($data->{etherpad_group}, $id, time + 86400);
  $self->session($room)->{etherpadSessionId} = $etherpadSession;
  my $etherpadCookieParam = {};
  if ($config->{'etherpad.base_domain'} && $config->{'etherpad.base_domain'} ne ''){
    $etherpadCookieParam->{domain} = $config->{'etherpad.base_domain'};
  }
  $self->cookie(sessionID => $etherpadSession, $etherpadCookieParam);
};

# Route / to the index page
any '/' => sub {
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

# Route for the admin page
# This one displas the details of a room
get '/admin/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  $self->purge_participants;
  my $data = $self->get_room_by_name($room);
  unless ($data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  my $num = scalar keys %{$self->get_participants_list($room)};
  $self->stash(
    room         => $room,
    participants => $num
  );
} => 'manage_room';
# And this one displays the list of existing rooms
get '/admin' => sub {
  my $self = shift;
  $self->purge_rooms;
} => 'admin';

# Routes for feedback. One get to display the form
# and one post to get data from it
get '/feedback' => 'feedback';
post '/feedback' => sub {
  my $self = shift;
  my $email = $self->param('email') || '';
  my $comment = $self->param('comment');
  my $sent = $self->mail(
    to => $config->{'email.contact'},
    subject => $self->l("FEEDBACK_FROM_VROOM"),
    data => $self->render_mail('feedback',
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
    $self->remove_participant_from_room($room,$self->session('name'));
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
  $self->remove_participant_from_room($room,$self->session('name'));
  $self->logout($room);
} => 'kicked';

# Route for invitition response
get '/invitation' => sub {
  my $self = shift;
  my $inviteId = $self->param('token') || '';
  # Delete expired invitation now
  $self->delete_invitations;
  my $invite = $self->get_invitation_by_token($inviteId);
  my $room = $self->get_room_by_id($invite->{room_id});
  if (!$invite || !$room){
    return $self->render('error',
      err  => 'ERROR_INVITATION_INVALID',
      msg  => $self->l('ERROR_INVITATION_INVALID'),
      room => $room
    );
  }
  $self->render('invitation',
    inviteId => $inviteId,
    room     => $room->{name},
  );
};

post '/invitation' => sub {
  my $self = shift;
  my $id = $self->param('token') || '';
  my $response = $self->param('response') || 'decline';
  my $message = $self->param('message') || '';
  if ($response !~ m/^(later|decline)$/ || !$self->respond_invitation($id,$response,$message)){
    return $self->render('error');
  }
  $self->render('invitation_thanks');
};

# This handler creates a new room
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
  # Cache the translation
  $self->res->headers->cache_control('private,max-age=3600');
  return $self->render(json => $strings);
};

# Route for the password page
get '/password/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room') || '';
  my $data = $self->get_room_by_name($room);
  unless ($data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->render('password', room => $room);
};

# Route for password submiting
post '/password/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room') || '';
  my $data = $self->get_room_by_name($room);
  unless ($data){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  my $pass = $self->param('password');
  # First check if we got the owner password, and if so, mark this user as owner
  if ($data->{owner_password} && Crypt::SaltedHash->validate($data->{owner_password}, $pass)){
    $self->session($room => {role => 'owner'});
    $self->redirect_to($self->get_url('/') . $room);
  }
  # Then, check if it's the join password
  elsif ($data->{join_password} && Crypt::SaltedHash->validate($data->{join_password}, $pass)){
    $self->session($room => {role => 'participant'});
    $self->redirect_to($self->get_url('/') . $room);
  }
  # Else, it's a wrong password, display an error page
  else{
    $self->render('error',
      err  => 'WRONG_PASSWORD',
      msg  => sprintf ($self->l("WRONG_PASSWORD"), $room),
      room => $room
    );
  }
};

# Catch all route: if nothing else match, it's the name of a room
get '/(*room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  my $video = $self->param('video') || '1';
  my $token = $self->param('token') || undef;
  # Redirect to lower case
  if ($room ne lc $room){
    $self->redirect_to($self->get_url('/') . lc $room);
  }
  $self->purge_rooms;
  $self->delete_invitations;
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
  if ($data->{'locked'} && (!$self->session($room) || !$self->session($room)->{role} || $self->session($room)->{role} ne 'owner')){
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
     (!$self->session($room) || $self->session($room)->{role} !~ m/^participant|owner$/) &&
     !$self->check_invite_token($room,$token)){
    return $self->redirect_to($self->get_url('/password') . $room);
  }
  # Set this peer as a simple participant if he has no role yet (shouldn't happen)
  $self->session($room => {role => 'participant'}) if (!$self->session($room) || !$self->session($room)->{role});
  # Create etherpad session if needed
  if ($ec && !$self->session($room)->{etherpadSession}){
    # pad doesn't exist yet ?
    if (!$data->{etherpad_group}){
      $self->create_pad($room);
    }
    $self->create_etherpad_session($room);
  }
  # Short life cookie to negociate a session with the signaling server
  $self->cookie(vroomsession => encode_base64($self->session('name') . ':' . $data->{name} . ':' . $data->{token}, ''), {expires => time + 60, path => '/'});
  # Add this user to the participants table
  if (!$self->add_participant_to_room($room,$self->session('name'))){
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

# Route for various room actions
post '/*action' => [action => [qw/action admin\/action/]] => sub {
  my $self = shift;
  my $action = $self->param('action');
  my $prefix = ($self->stash('action') eq 'admin/action') ? 'admin':'room';
  my $room = $self->param('room') || '';
  if ($action eq 'langSwitch'){
    my $new_lang = $self->param('lang') || 'en';
    $self->app->log->debug("switching to lang $new_lang");
    $self->session(language => $new_lang);
    return $self->render(
      json => {
        status => 'success',
      }
    );
  }
  # Refuse any action from non members of the room
  if ($prefix ne 'admin' && (!$self->session('name') ||
                             !$self->has_joined({name => $self->session('name'), room => $room}) ||
                             !$self->session($room) ||
                             !$self->session($room)->{role})){
    return $self->render(
             json => {
               msg    => $self->l('ERROR_NOT_LOGGED_IN'),
               status => 'error'
             },
           );
  }
  # Sanity check on the room name
  if (!$self->valid_room_name($room)){
    return $self->render(
      json => {
        msg    => $self->l('ERROR_NAME_INVALID'),
        status => 'error'
      },
    );
  }
  # Push the room name to the stash, just in case
  $self->stash(room => $room);
  # Gather room info from the DB
  my $data = $self->get_room_by_name($room);
  # Stop here if the room doesn't exist
  if (!$data){
    return $self->render(
      json => {
        msg    => sprintf ($self->l('ERROR_ROOM_s_DOESNT_EXIST'), $room),
        err    => 'ERROR_ROOM_s_DOESNT_EXIST',
        status => 'error'
      },
    );
  }

  # Handle email invitation
  if ($action eq 'invite'){
    my $rcpt    = $self->param('recipient');
    my $message = $self->param('message');
    my $status  = 'error';
    my $msg     = $self->l('ERROR_OCCURRED');
    if ($prefix ne 'admin' && $self->session($room)->{role} ne 'owner'){
      $msg = 'NOT_ALLOWED';
    }
    elsif ($rcpt !~ m/\S+@\S+\.\S+$/){
      $msg = $self->l('ERROR_MAIL_INVALID');
    }
    else{
      my $inviteId = $self->add_invitation($room,$rcpt);
      my $sent = $self->mail(
                   to      => $rcpt,
                   subject => $self->l("EMAIL_INVITATION"),
                   data    => $self->render_mail('invite', 
                                room     => $room,
                                message  => $message,
                                inviteId => $inviteId,
                                joinPass => ($data->{join_password}) ? 'yes' : 'no'
                              )
                 );
      if ($inviteId && $sent){
        $self->app->log->info($self->session('name') . " sent an invitation for room $room to $rcpt");
        $status = 'success';
        $msg = sprintf($self->l('INVITE_SENT_TO_s'), $rcpt);
      }
    }
    $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # Handle room lock/unlock
  if ($action =~ m/(un)?lock/){
    my ($lock,$success);
    my $msg = 'ERROR_OCCURRED';
    my $status = 'error';
    $data->{locked} = ($action eq 'lock') ? '1':'0';
    # Only the owner can lock or unlock a room
    if ($prefix ne 'admin' && $self->session($room)->{role} ne 'owner'){
      return $self->render(
        json => {
          status => 'error',
          msg    => $self->l('NOT_ALLOWED')
        }
      );
    }
    if (!$self->modify_room($data)){
      return $self->render(
        json => {
          status => 'error',
          msg => $self->l('ERROR_OCCURRED')
        }
      );
    }
    return $self->render(
      json => {
        msg    => ($action eq 'lock') ? $self->l('ROOM_LOCKED') : $self->l('ROOM_UNLOCKED'),
        status => 'success'
      }
    );
  }
  # Handle activity pings sent every minute by each participant
  elsif ($action eq 'ping'){
    my $status = 'error';
    my $msg = $self->l('ERROR_OCCURRED');
    my $res = $self->ping_room($room);
    # Cleanup expired rooms every ~10 pings
    if ((int (rand 100)) <= 10){
      $self->purge_rooms;
    }
    # And same for expired invitation links
    if ((int (rand 100)) <= 10){
      $self->delete_invitations;
    }
    # And also remove inactive participants
    if ((int (rand 100)) <= 10){
      $self->purge_participants;
    }
    if ($res){
      $status = 'success';
      $msg = '';
    }
    my $invitations = $self->get_invitation_list($self->session('name'));
    $msg = '';
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
               status => $status
             }
           );
  }
  # Handle password (join and owner)
  elsif ($action eq 'setPassword'){
    my $pass = $self->param('password');
    my $type = $self->param('type') || 'join';
    # Empty password is equivalent to no password at all
    $pass = ($pass && $pass ne '') ?
      Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($pass)->generate : undef;
    my $msg = $self->l('ERROR_OCCURRED');
    my $status = 'error';
    # Once again, only the owner can do this
    if ($prefix eq 'admin' || $self->session($room)->{role} eq 'owner'){
      if ($type eq 'owner'){
        $data->{owner_password} = $pass;
        # Forbid a few common room names to be reserved
        if (grep { $room eq $_ } (split /[,;]/, $config->{'rooms.common_names'})){
          $msg = $self->l('ERROR_COMMON_ROOM_NAME');
        }
        elsif ($self->modify_room($data)){
          $msg = ($pass) ? $self->l('ROOM_NOW_RESERVED') : $self->l('ROOM_NO_MORE_RESERVED');
          $status = 'success';
        }
      }
      elsif ($type eq 'join'){
        $data->{join_password} = $pass;
        if ($self->modify_room($data)){
          $msg = ($pass) ? $self->l('PASSWORD_PROTECT_SET') : $self->l('PASSWORD_PROTECT_UNSET');
          $status = 'success';
        }
      }
    }
    # Simple participants will get an error
    else{
      $msg = $self->l('NOT_ALLOWED');
    }
    return $self->render(
             json => {
               msg    => $msg,
               status => $status
             }
           );
  }
  # Handle persistence
  elsif ($action eq 'setPersistent'){
    my $type = $self->param('type');
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    # Only possible through /admin/action
    if ($prefix ne 'admin'){
      $msg = $self->l('NOT_ALLOWED');
    }
    $data->{persistent} = ($type eq 'set') ? 1 : 0;
    if ($self->modify_room($data)){
      $status = 'success';
      $msg = $self->l(($type eq 'set') ? 'ROOM_NOW_PERSISTENT' : 'ROOM_NO_MORE_PERSISTENT');
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # A participant is trying to auth as an owner, lets check that
  elsif ($action eq 'authenticate'){
    my $pass = $self->param('password');
    my $res = undef;
    my $msg = $self->l('ERROR_OCCURRED');
    my $status = 'error';
    # Auth succeed ? lets promote him to owner of the room
    if ($data->{owner_password} && Crypt::SaltedHash->validate($data->{owner_password}, $pass)){
      $self->session($room, {role => 'owner'});
      $msg = $self->l('AUTH_SUCCESS');
      $status = 'success';
    }
    elsif ($data->{owner_password}){
      $msg = $self->l('WRONG_PASSWORD');
    }
    # There's no owner password, so you cannot auth
    else{
      $msg = $self->l('NOT_ALLOWED');
    }
    return $self->render(
               json => {
                 msg    => $msg,
                 status => $status
               },
             );
  }
  # Return your role and various info about the room
  elsif ($action eq 'getRoomInfo'){
    my $id = $self->param('id');
    my %emailNotif;
    if ($self->session($room) && $self->session($room)->{role}){
      if ($self->session($room)->{role} ne 'owner' && $self->get_peer_role({room => $room, peer_id => $id}) eq 'owner'){
        $self->session($room)->{role} = 'owner';
      }
      my $res = $self->set_peer_role({
        room    => $room,
        name    => $self->session('name'),
        peer_id => $id,
        role    => $self->session($room)->{role}
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
    if ($self->session($room)->{role} eq 'owner'){
      my $i = 0;
    }
    return $self->render(
               json => {
                 role         => $self->session($room)->{role},
                 owner_auth   => ($data->{owner_password}) ? 'yes' : 'no',
                 join_auth    => ($data->{join_password})  ? 'yes' : 'no',
                 locked       => ($data->{locked})         ? 'yes' : 'no',
                 ask_for_name => ($data->{ask_for_name})   ? 'yes' : 'no',
                 notif        => $self->get_notification($room),
                 status       => 'success'
               },
             );
  }
  # Return the role of a peer
  elsif ($action eq 'getPeerRole'){
    my $id = $self->param('id');
    my $role = $self->get_peer_role({room => $room, peer_id => $id});
    return $self->render(
      json => {
        role => $role,
        status => 'success'
      }
    );
  }
  # Add a new email for notifications when someone joins
  elsif ($action eq 'emailNotification'){
    my $email  = $self->param('email');
    my $type   = $self->param('type');
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if ($prefix ne 'admin' && $self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif ($email !~ m/^\S+@\S+\.\S+$/){
      $msg = $self->l('ERROR_MAIL_INVALID');
    }
    elsif ($type eq 'add' && $self->add_notification($room,$email)){
      $status = 'success';
      $msg = sprintf($self->l('s_WILL_BE_NOTIFIED'), $email);
    }
    elsif ($type eq 'remove' && $self->remove_notification($room,$email)){
      $status = 'success';
      $msg = sprintf($self->l('s_WONT_BE_NOTIFIED_ANYMORE'), $email);
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # Set/unset askForName
  elsif ($action eq 'askForName'){
    my $type = $self->param('type');
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if ($prefix ne 'admin' && $self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    $data->{ask_for_name} = ($type eq 'set') ? 1 : 0;
    if ($self->modify_room($data)){
      $status = 'success';
      $msg = $self->l(($type eq 'set') ? 'FORCE_DISPLAY_NAME' : 'NAME_WONT_BE_ASKED');
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # New participant joined the room
  elsif ($action eq 'join'){
    my $name = $self->param('name') || '';
    my $subj = ($name eq '') ? sprintf($self->l('s_JOINED_ROOM_s'), $self->l('SOMEONE'), $room) : sprintf($self->l('s_JOINED_ROOM_s'), $name, $room);
    # Send notifications
    my $recipients = $self->get_notification($room);
    foreach my $rcpt (keys %{$recipients}){
      my $sent = $self->mail(
                   to      => $recipients->{$rcpt}->{email},
                   subject => $subj,
                   data    => $self->render_mail('notification',
                                room => $room,
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
  # A participant is being promoted to the owner status
  elsif ($action eq 'promote'){
    my $peer = $self->param('peer');
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if (!$peer){
      $msg    = $self->l('ERROR_OCCURRED');
    }
    elsif ($self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif ($self->promote_peer({room => $room, peer_id => $peer})){
      $status = 'success';
      $msg = $self->l('PEER_PROMOTED');
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # Wipe etherpad data
  elsif ($action eq 'wipeData'){
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if ($self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif (!$ec){
      $msg = 'NOT_ENABLED';
    }
    elsif ($ec->delete_pad($data->{etherpad_group} . '$' . $room) && $self->create_pad($room) && $self->create_etherpad_session($room)){
      $status = 'success';
      $msg = '';
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  elsif ($action eq 'padSession'){
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if ($self->session($room)->{role} !~ m/^owner|participant$/){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif (!$ec){
      $msg = 'NOT_ENABLED';
    }
    elsif ($self->create_etherpad_session($room)){
      $status = 'success';
      $msg = '';
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
  # delete the room
  elsif ($action eq 'deleteRoom'){
    my $status = 'error';
    my $msg    = $self->l('ERROR_OCCURRED');
    if ($prefix ne 'admin' && $self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif ($self->delete_room($room)){
      $msg = $self->l('ROOM_DELETED');
      $status = 'success';
    }
    return $self->render(
      json => {
        msg    => $msg,
        status => $status
      }
    );
  }
};

# use the templates defined in the config
push @{app->renderer->paths}, 'templates/'.$config->{'interface.template'};
# Set the secret used to sign cookies
app->secret($config->{'cookie.secret'});
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

