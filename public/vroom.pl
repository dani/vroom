#!/usr/bin/env perl

# This file is part of the VROOM project
# released under the MIT licence
# Copyright 2014 Firewall Services

use lib '../lib';
use Mojolicious::Lite;
use Mojolicious::Plugin::Mailer;
use Mojo::JSON;
use DBI;
use Data::GUID qw(guid_string);
use Digest::MD5 qw(md5_hex);
use Crypt::SaltedHash;
use MIME::Base64;
use Email::Sender::Transport::Sendmail;
use Encode;
use File::stat;
use File::Basename;

# List The different components we rely on.
# Used to generate thanks on the about template
our $components = {
  "SimpleWebRTC" => {
    url => 'http://simplewebrtc.com/'
  },
  "Mojolicious" => {
    url => 'http://mojolicio.us/'
  },
  "Jquery" => {
    url => 'http://jquery.com/'
  },
  "notify.js" => {
    url => 'http://notifyjs.com/'
  },
  "jquery-browser-plugin" => {
    url => 'https://github.com/gabceb/jquery-browser-plugin'
  },
  "sprintf.js" => {
    url => 'http://hexmen.com/blog/2007/03/printf-sprintf/'
  },
  "node.js" => {
    url => 'http://nodejs.org/'
  },
  "bootstrap" => {
    url => 'http://getbootstrap.com/'
  },
  "MariaDB" => {
    url => 'https://mariadb.org/'
  },
  "SignalMaster" => {
    url => 'https://github.com/andyet/signalmaster/'
  },
  "rfc5766-turn-server" => {
    url => 'https://code.google.com/p/rfc5766-turn-server/'
  },
  "FileSaver" => {
    url => 'https://github.com/eligrey/FileSaver.js'
  },
  "WPZOOM Developer Icon Set" => {
    url => 'https://www.iconfinder.com/search/?q=iconset%3Awpzoom-developer-icon-set'
  }
};

# MOH authors for credits
our $musics = {
  "Papel Secante" => {
    author      => "Angel Gaitan",
    author_url  => "http://angelgaitan.bandcamp.com/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Overjazz" => {
    author      => "Funkyproject",
    author_url  => "http://www.funkyproject.fr",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Polar Express" => {
    author      => "Koteen",
    author_url  => "http://?.?",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "Funky Goose" => {
    author      => "Pepe Frias",
    author_url  => "http://www.pepefrias.tk/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  },
  "I got my own" => {
    author      => "Reole",
    author_url  => "http://www.reolemusic.com/",
    licence     => "Creative Commons BY-SA",
    licence_url => "http://creativecommons.org/licenses/by-sa/3.0"
  }
};

app->log->level('info');
# Read conf file, and set default values
our $config = plugin Config => {
  file     => '../conf/vroom.conf',
  default  => {
    dbi                           => 'DBI:mysql:database=vroom;host=localhost',
    dbUser                        => 'vroom',
    dbPassword                    => 'vroom',
    signalingServer               => 'https://vroom.example.com/',
    stunServer                    => 'stun.l.google.com:19302',
    realm                         => 'vroom',
    emailFrom                     => 'vroom@example.com',
    feedbackRecipient             => 'admin@example.com',
    poweredBy                     => '<a href="http://www.firewall-services.com" target="_blank">Firewall Services</a>',
    template                      => 'default',
    inactivityTimeout             => 3600,
    persistentInactivityTimeout   => 0,
    commonRoomNames               => [ qw() ],
    logLevel                      => 'info',
    chromeExtensionId             => 'ecicdpoejfllflombfanbhfpgcimjddn',
    sendmail                      => '/sbin/sendmail'
  }
};

app->log->level($config->{logLevel});

# Load I18N, and declare supported languages
plugin I18N => {
  namespace => 'Vroom::I18N',
  support_url_langs => [qw(en fr)]
};

# Load mailer plugin with its default values
plugin Mailer => {
  from      => $config->{emailFrom},
  transport => Email::Sender::Transport::Sendmail->new({ sendmail => $config->{sendmail}}),
};

# Wrapper arround DBI
helper db => sub { 
  my $dbh = DBI->connect($config->{dbi}, $config->{dbUser}, $config->{dbPassword}) || die "Could not connect";
  $dbh
};

# Create a cookie based session
helper login => sub {
  my $self = shift;
  return if $self->session('name');
  my $login = $ENV{'REMOTE_USER'} || lc guid_string();
  $self->session( name => $login,
                  ip   => $self->tx->remote_address );
  $self->app->log->info($self->session('name') . " logged in from " . $self->tx->remote_address);
};

# Expire the cookie
helper logout => sub {
  my $self = shift;
  $self->session( expires => 1 );
  $self->app->log->info($self->session('name') . " logged out");
};

# Create a new room in the DB
# Requires two args: the name of the room and the session name of the creator
helper create_room => sub {
  my $self = shift;
  my ($name,$owner) = @_;
  # Exit if the name isn't valid or already taken
  return undef if ( $self->get_room($name) || !$self->valid_room_name($name));
  my $sth = eval { $self->db->prepare("INSERT INTO rooms (name,create_timestamp,activity_timestamp,owner,token,realm) VALUES (?,?,?,?,?,?);") } || return undef;
  # Gen a random token. Will be used as a turnPassword
  my $tp = join '' => map{('a'..'z','A'..'Z','0'..'9')[rand 62]} 0..49;
  $sth->execute($name,time(),time(),$owner,$tp,$config->{realm}) || return undef;
  $self->app->log->info("room $name created by " . $self->session('name'));
  return 1;
};

# Read room param in the DB and return a perl hash
helper get_room => sub {
  my $self = shift;
  my ($name) = @_;
  my $sth = eval { $self->db->prepare("SELECT * from rooms where name=?;") } || return undef;
  $sth->execute($name) || return undef;
  return $sth->fetchall_hashref('name')->{$name};
};

# Lock/unlock a room, to prevent new participants
# Takes two arg: room name and 1 for lock, 0 for unlock
helper lock_room => sub {
  my $self = shift;
  my ($name,$lock) = @_;
  return undef unless ( %{ $self->get_room($name) });
  return undef unless ($lock =~ m/^0|1$/);
  my $sth = eval { $self->db->prepare("UPDATE rooms SET locked=? where name=?;") } || return undef;
  $sth->execute($lock,$name) || return undef;
  my $action = ($lock eq '1') ? 'locked':'unlocked';
  $self->app->log->info("room $name $action by " . $self->session('name'));
  return 1;
};

# Add a participant in the database. Used by the signaling server to check
# if user is allowed
helper add_participant => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room($name) || return undef;
  my $sth = eval { $self->db->prepare("INSERT IGNORE INTO participants (id,participant) VALUES (?,?);") } || return undef;
  $sth->execute($room->{id},$participant) || return undef;
  $self->app->log->info($self->session('name') . " joined the room $name");
  return 1;
};

# Remove participant from the DB
helper remove_participant => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room($name) || return undef;
  my $sth = eval { $self->db->prepare("DELETE FROM participants WHERE id=? AND participant=?;") } || return undef;
  $sth->execute($room->{id},$participant) || return undef;
  $self->app->log->info($self->session('name') . " leaved the room $name");
  return 1;
};

# Get a list of participants of a room
helper get_participants => sub {
  my $self = shift;
  my ($name) = @_;
  my $room = $self->get_room($name) || return undef;
  my $sth = eval { $self->db->prepare("SELECT participant FROM participants WHERE id=?;") } || return undef;
  $sth->execute($room->{id}) || return undef;
  my @res;
  while(my @row = $sth->fetchrow_array){
    push @res, $row[0];
  }
  return @res;
};

# Set the role of a peer
helper set_peer_role => sub {
  my $self = shift;
  my ($room,$name,$id,$role) = @_;
  # Check if this ID isn't the one from another peer first
  my $sth = eval { $self->db->prepare("SELECT * FROM participants WHERE peer_id=? AND participant!=? AND id IN (SELECT id FROM rooms WHERE name=?)") } || return undef;
  $sth->execute($id,$name,$room) || return undef;
  return undef if ($sth->rows > 0);
  $sth = eval { $self->db->prepare("UPDATE participants SET peer_id=?,role=? WHERE participant=? AND id IN (SELECT id FROM rooms WHERE name=?)") } || return undef;
  $sth->execute($id,$role,$name,$room) || return undef;
  return 1;
};

# Return the role of a peer, from it's signaling ID
helper get_peer_role => sub {
  my $self = shift;
  my ($room,$id) = @_;
  my $sth = eval { $self->db->prepare("SELECT role from participants WHERE peer_id=? AND id IN (SELECT id FROM rooms WHERE name=?)") } || return undef;
  $sth->execute($id,$room) || return undef;
  if ($sth->rows == 1){
    my ($role) = $sth->fetchrow_array();
    return $role;
  }
  else{
    return 'participant';
  }
};

# Check if a participant has joined a room
# Takes two args: the session name, and the room name
helper has_joined => sub {
  my $self = shift;
  my ($session,$name) = @_;
  my $ret = 0;
  my $sth = eval { $self->db->prepare("SELECT * FROM rooms WHERE name=? AND id IN (SELECT id FROM participants WHERE participant=?)") } || return undef;
  $sth->execute($name,$session) || return undef;
  $ret = 1 if ($sth->rows > 0);
  return $ret;
};

# Purge unused rooms
helper delete_rooms => sub {
  my $self = shift;
  $self->app->log->debug('Removing unused rooms');
  eval {
    my $timeout = time()-$config->{inactivityTimeout};
    $self->db->do("DELETE FROM participants WHERE id IN (SELECT id FROM rooms WHERE activity_timestamp < $timeout AND persistent='0');");
    $self->db->do("DELETE FROM notifications WHERE id IN (SELECT id FROM rooms WHERE activity_timestamp < $timeout AND persistent='0');");
    $self->db->do("DELETE FROM rooms WHERE activity_timestamp < $timeout AND persistent='0';");
  } || return undef;
  if ($config->{persistentInactivityTimeout} && $config->{persistentInactivityTimeout} > 0){
    eval {
      my $timeout = time()-$config->{persistentInactivityTimeout};
      $self->db->do("DELETE FROM participants WHERE id IN (SELECT id FROM rooms WHERE activity_timestamp < $timeout AND persistent='1');");
      $self->db->do("DELETE FROM notifications WHERE id IN (SELECT id FROM rooms WHERE activity_timestamp < $timeout AND persistent='1');");
      $self->db->do("DELETE FROM rooms WHERE activity_timestamp < $timeout AND persistent='1';");
    } || return undef;
  }
  return 1;
};

# Just update the activity timestamp
# so we can detect unused rooms
helper ping_room => sub {
  my $self = shift;
  my ($name) = @_;
  return undef unless ( %{ $self->get_room($name) });
  my $sth = eval { $self->db->prepare("UPDATE rooms SET activity_timestamp=? where name=?;") } || return undef;
  $sth->execute(time(),$name) || return undef;
  $self->app->log->debug($self->session('name') . " pinged the room $name");
  return 1;
};

# Check if this name is a valid room name
helper valid_room_name => sub {
  my $self = shift;
  my ($name) = @_;
  my $ret = undef;
  # A few names are reserved
  my @reserved = qw(about help feedback goodbye admin create localize action missing dies password kicked);
  if ($name =~ m/^[\w\-]{1,49}$/ && !grep { $name eq $_ }  @reserved){
    $ret = 1;
  }
  return $ret;
};

# Generate a random name
helper get_random_name => sub {
  my $self = shift;
  my $name = join '' => map{('a'..'z','0'..'9')[rand 36]} 0..9;
  # Get another one if already taken
  while ($self->get_room($name)){
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

# Password protect a room
# Takes two args: room name and password
# If password is undef: remove the password
# Password is hashed and salted before being stored
helper set_join_pass => sub {
  my $self = shift;
  my ($room,$pass) = @_;
  return undef unless ( %{ $self->get_room($room) });
  my $sth = eval { $self->db->prepare("UPDATE rooms SET join_password=? where name=?;") } || return undef;
  $pass = ($pass) ? Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($pass)->generate : undef;
  $sth->execute($pass,$room) || return undef;
  if ($pass){
    $self->app->log->debug($self->session('name') . " has set a password on room $room");
  }
  else{
    $self->app->log->debug($self->session('name') . " has removed password on room $room");
  }
  return 1;
};

# Set owner password. Not needed to join a room
# but needed to prove you're the owner, and access the configuration menu
helper set_owner_pass => sub {
  my $self = shift;
  my ($room,$pass) = @_;
  return undef unless ( %{ $self->get_room($room) });
  # For now, setting an owner password makes the room persistant
  # Might be separated in the future
  if ($pass){
    my $sth = eval { $self->db->prepare("UPDATE rooms SET owner_password=?,persistent='1' where name=?;") } || return undef;
    my $pass = Crypt::SaltedHash->new(algorithm => 'SHA-256')->add($pass)->generate;
    $sth->execute($pass,$room) || return undef;
    $self->app->log->debug($self->session('name') . " has set an owner password on room $room, which is now persistent");
  }
  else{
    my $sth = eval { $self->db->prepare("UPDATE rooms SET owner_password=?,persistent='0' where name=?;") } || return undef;
    $sth->execute(undef,$room) || return undef;
    $self->app->log->debug($self->session('name') . " has removed the owner password on room $room, which is not persistent anymore");
  }
};

# Add an email address to the list of notifications
helper add_notification => sub {
  my $self = shift;
  my ($room,$email) = @_;
  my $data = $self->get_room($room);
  return undef unless ($data);
  my $sth = eval { $self->db->prepare("INSERT INTO notifications (id,email) VALUES (?,?)") } || return undef;
  $sth->execute($data->{id},$email) || return undef;
  return 1;
};

# Return the list of email addresses
helper get_notification => sub {
  my $self = shift;
  my ($room) = @_;
  $room = $self->get_room($room) || return undef;
  my $sth = eval { $self->db->prepare("SELECT email FROM notifications WHERE id=?;") } || return undef;
  $sth->execute($room->{id}) || return undef;
  my @res;
  while(my @row = $sth->fetchrow_array){
    push @res, $row[0];
  }
  return @res;
};

# Remove an email from notification list
helper remove_notification => sub {
  my $self = shift;
  my ($room,$email) = @_;
  my $data = $self->get_room($room);
  return undef unless ($data);
  my $sth = eval { $self->db->prepare("DELETE FROM notifications where id=? and email=?") } || return undef;
  $sth->execute($data->{id},$email) || return undef;
  return 1;
};


# Set/unset ask for name
helper ask_for_name => sub {
  my $self = shift;
  my ($room,$set) = @_;
  my $data = $self->get_room($room);
  return undef unless ($data);
  my $sth = eval { $self->db->prepare("UPDATE rooms SET ask_for_name=? WHERE name=?") } || return undef;
  $sth->execute($set,$room) || return undef;
  return 1;
};

# Randomly choose a music on hold
helper choose_moh => sub {
  my $self = shift;
  my @files = (<snd/moh/*.*>);
  return basename($files[rand @files]);
};

# Route / to the index page
any '/' => 'index';

# Route for the about page
get '/about' => sub {
  my $self = shift;
  $self->stash( components => $components,
                musics     => $musics
  );
} => 'about';

# Route for the help page
get '/help' => 'help';

# Routes for feedback. One get to display the form
# and one post to get data from it
get '/feedback' => 'feedback';
post '/feedback' => sub {
  my $self = shift;
  my $email = $self->param('email') || '';
  my $comment = $self->param('comment');
  $self->email(
    header => [
      Subject => encode("MIME-Header", $self->l("FEEDBACK_FROM_VROOM")),
      To => $config->{feedbackRecipient}
    ],
    data => [
      template => 'feedback',
      email    => $email,
      comment  => $comment
    ],
  );
  $self->redirect_to($self->get_url('feedback_thanks'));
};

# Route for the thanks after feedback form
get 'feedback_thanks' => 'feedback_thanks';

# Route for the goodbye page, displayed when someone leaves a room
get '/goodby/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  if (!$self->get_room($room)){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->remove_participant($room,$self->session('name'));
  $self->logout;
} => 'goodby';

# Route for the kicked page
# Should be merged with the goodby route
get '/kicked/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  if (!$self->get_room($room)){
    return $self->render('error',
      err  => 'ERROR_ROOM_s_DOESNT_EXIST',
      msg  => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
      room => $room
    );
  }
  $self->remove_participant($room,$self->session('name'));
  $self->logout;
} => 'kicked';

# This handler creates a new room
post '/create' => sub {
  my $self = shift;
  $self->res->headers->cache_control('max-age=1, no-cache');
  # No name provided ? Lets generate one
  my $name = $self->param('roomName') || $self->get_random_name();
  # Create a session for this user, but don't set a role for now
  $self->login;
  # Error if the name is invalid
  unless ($self->valid_room_name($name)){
    return $self->render('error',
      room => $name,
      msg  => $self->l('ERROR_NAME_INVALID'),
      err  => 'ERROR_NAME_INVALID'
    );
  }
  # Cleanup unused rooms before trying to create it
  $self->delete_rooms;
  unless ($self->create_room($name,$self->session('name'))){
    # If creation failed, it's most likly a name conflict
    return $self->render('error',
      room => $name,
      msg  => $self->l('ERROR_NAME_CONFLICT'),
      err  => 'ERROR_NAME_CONFLICT'
    );
  }
  # Everything went fine, the room is created, lets mark this user owner of the room
  # and redirect him on it.
  else{
    $self->session($name => {role => 'owner'});
    $self->redirect_to($self->get_url('/') . $name);
  }
};

# Translation for JS resources
# As there's no way to list all the available translated strings
# JS sends us the list it wants as a JSON object
# and we sent it back once localized
post '/localize' => sub {
  my $self = shift;
  my $strings = Mojo::JSON->new->decode($self->param('strings'));
  foreach my $string (keys %$strings){
    $strings->{$string} = $self->l($string);
  }
  return $self->render(json => $strings);
};

# Route for the password page
get '/password/(:room)' => sub {
  my $self = shift;
  my $room = $self->stash('room') || '';
  my $data = $self->get_room($room);
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
  my $data = $self->get_room($room);
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
  # Redirect to lower case
  if ($room ne lc $room){
    $self->redirect_to($self->get_url('/') . lc $room);
  }
  $self->delete_rooms;
  unless ($self->valid_room_name($room)){
    return $self->render('error',
      msg  => $self->l('ERROR_NAME_INVALID'),
      err  => 'ERROR_NAME_INVALID',
      room => $room
    );
  }
  my $data = $self->get_room($room);
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
  if ($data->{join_password} && (!$self->session($room) || $self->session($room)->{role} !~ m/^participant|owner$/)){
    return $self->redirect_to($self->get_url('/password') . $room);
  }
  # Set this peer as a simple participant if he has no role yet (shouldn't happen)
  $self->session($room => {role => 'participant'}) if (!$self->session($room) || !$self->session($room)->{role});
  # Short life cookie to negociate a session with the signaling server
  $self->cookie(vroomsession => encode_base64($self->session('name') . ':' . $data->{name} . ':' . $data->{token}, ''), {expires => time + 60, path => '/'});
  # Add this user to the participants table
  unless($self->add_participant($room,$self->session('name'))){
    return $self->render('error',
      msg  => $self->l('ERROR_OCCURED'),
      err  => 'ERROR_OCCURED',
      room => $room
    );
  }
  # Now display the room page
  $self->render('join',
    moh => $self->choose_moh(),
    turnPassword => $data->{token}
  );
};

# Route for various room actions
post '/action' => sub {
  my $self = shift;
  my $action = $self->param('action');
  my $room = $self->param('room') || "";
  # Refuse any action from non members of the room
  if (!$self->session('name') || !$self->has_joined($self->session('name'), $room) || !$self->session($room) || !$self->session($room)->{role}){
    return $self->render(
             json => {
               msg    => $self->l('ERROR_NOT_LOGGED_IN'),
               status => 'error'
             },
           );
  }
  # Sanity check on the room name
  return $self->render(
           json => {
             msg    => sprintf ($self->l("ERROR_NAME_INVALID"), $room),
             status => 'error'
           },
         ) unless ($self->valid_room_name($room));
  # Push the room name to the stash, just in case
  $self->stash(room => $room);
  # Gather room info from the DB
  my $data = $self->get_room($room);
  # Stop here if the room doesn't exist
  return $self->render(
           json => {
             msg    => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
             err    => 'ERROR_ROOM_s_DOESNT_EXIST',
             status => 'error'
           },
         ) unless ($data);

  # Handle email invitation
  if ($action eq 'invite'){
    my $rcpt    = $self->param('recipient');
    my $message = $self->param('message');
    my $status  = 'error';
    my $msg     = $self->l('ERROR_OCCURED');
    if (!$self->session($room) || $self->session($room)->{role} ne 'owner'){
      $msg = 'NOT_ALLOWED';
    }
    elsif ($rcpt !~ m/\S+@\S+\.\S+$/){
      $msg = $self->l('ERROR_MAIL_INVALID');
    }
    elsif ($self->email(
      header => [
        Subject => encode("MIME-Header", $self->l("EMAIL_INVITATION")),
        To => $rcpt
      ],
      data => [
        template => 'invite',
        room     => $room,
        message  => $message
      ],
    )){
      $self->app->log->info($self->session('name') . " sent an invitation for room $room to $rcpt");
      $status = 'success';
      $msg = sprintf($self->l('INVITE_SENT_TO_s'), $rcpt);
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
    my $msg = 'ERROR_OCCURED';
    my $status = 'error';
    # Only the owner can lock or unlock a room
    if (!$self->session($room) || $self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif ($self->lock_room($room,($action eq 'lock') ? '1':'0')){
      $status = 'success';
      $msg = ($action eq 'lock') ? $self->l('ROOM_LOCKED') : $self->l('ROOM_UNLOCKED');
    }
    return $self->render(
             json => {
               msg    => $msg,
               status => $status
             }
           );
  }
  # Handle activity pings sent every minute by each participant
  elsif ($action eq 'ping'){
    my $status = 'error';
    my $msg = $self->l('ERROR_OCCURED');
    my $res = $self->ping_room($room);
    # Cleanup expired rooms every ~10 pings
    if ((int (rand 100)) <= 10){
      $self->delete_rooms;
    }
    if ($res){
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
  # Handle password (join and owner)
  elsif ($action eq 'setPassword'){
    my $pass = $self->param('password');
    my $type = $self->param('type') || 'join';
    # Empty password is equivalent to no password at all
    $pass = undef if ($pass && $pass eq '');
    my $res = undef;
    my $msg = $self->l('ERROR_OCCURED');
    my $status = 'error';
    # Once again, only the owner can do this
    if ($self->session($room)->{role} eq 'owner'){
      if ($type eq 'owner'){
        # Forbid a few common room names to be reserved
        if (grep { $room eq $_ } @{$config->{commonRoomNames}}){
          $msg = $self->l('ERROR_COMMON_ROOM_NAME');
        }
        else{
          $res = $self->set_owner_pass($room,$pass);
        }
      }
      else{
        $res = $self->set_join_pass($room,$pass);
      }
      if ($res){
        $msg = ($pass) ? $self->l('PASSWORD_SET') : $self->l('PASSWORD_REMOVED');
        $status = 'success';
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
  # A participant is trying to auth as an owner, lets check that
  elsif ($action eq 'authenticate'){
    my $pass = $self->param('password');
    my $res = undef;
    my $msg = $self->l('ERROR_OCCURED');
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
    my $res = 'error';
    my %emailNotif;
    if ($self->session($room) && $self->session($room)->{role}){
      $res = ($self->set_peer_role($room,$self->session('name'),$id, $self->session($room)->{role})) ? 'success':$res;
    }
    if ($self->session($room)->{role} eq 'owner'){
      my $i = 0;
      my @email = $self->get_notification($room);
      %emailNotif = map { $i => $email[$i++] } @email;
    }
    return $self->render(
               json => {
                 role         => $self->session($room)->{role},
                 owner_auth   => ($data->{owner_password}) ? 'yes' : 'no',
                 join_auth    => ($data->{join_password})  ? 'yes' : 'no',
                 locked       => ($data->{locked})         ? 'yes' : 'no',
                 ask_for_name => ($data->{ask_for_name})   ? 'yes' : 'no',
                 notif        => Mojo::JSON->new->encode({email => { %emailNotif }}),
                 status       => $res
               },
             );
  }
  # Return the role of a peer
  elsif ($action eq 'getPeerRole'){
    my $id = $self->param('id');
    my $role = $self->get_peer_role($room,$id);
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
    my $msg    = $self->l('ERROR_OCCURED');
    if ($self->session($room)->{role} ne 'owner'){
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
    my $msg    = $self->l('ERROR_OCCURED');
    if ($self->session($room)->{role} ne 'owner'){
      $msg = $self->l('NOT_ALLOWED');
    }
    elsif($type eq 'set' && $self->ask_for_name($room,'1')){
      $status = 'success';
      $msg = $self->l('FORCE_DISPLAY_NAME');
    }
    elsif($type eq 'unset' && $self->ask_for_name($room,'0')){
      $status = 'success';
      $msg = $self->l('NAME_WONT_BE_ASKED');
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
    # Send notifications
    foreach my $rcpt ($self->get_notification($room)){
      $self->email(
        header => [
          Subject => encode("MIME-Header", $self->l("JOIN_NOTIFICATION")),
          To => $rcpt
        ],
        data => [
          template => 'notification',
          room     => $room,
          name     => $name
        ],
      );
    }
    return $self->render(
        json => {
          status => 'success'
        }
    );
  }
};

# use the templates defined in the config
push @{app->renderer->paths}, '../templates/'.$config->{template};
# Set the secret used to sign cookies
app->secret($config->{secret});
app->sessions->secure(1);
app->sessions->cookie_name('vroom');
# And start, lets VROOM !!
app->start;

