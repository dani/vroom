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
  }
};

app->log->level('info');
our $config = plugin Config => {
  file     => '../conf/vroom.conf',
  default  => {
    dbi                 => 'DBI:mysql:database=vroom;host=localhost',
    dbUser              => 'vroom',
    dbPassword          => 'vroom',
    signalingServer     => 'https://vroom.example.com/',
    stunServer          => 'stun.l.google.com:19302',
    realm               => 'vroom',
    emailFrom           => 'vroom@example.com',
    feedbackRecipient   => 'admin@example.com',
    template            => 'default',
    inactivityTimeout   => 3600,
    logLevel            => 'info',
    chromeExtensionId   => 'ecicdpoejfllflombfanbhfpgcimjddn',
    sendmail            => '/sbin/sendmail'
  }
};

app->log->level($config->{logLevel});

plugin I18N => {
  namespace => 'Vroom::I18N',
  support_url_langs => [qw(en fr)]
};


plugin Mailer => {
  from      => $config->{emailFrom},
  transport => Email::Sender::Transport::Sendmail->new({ sendmail => $config->{sendmail}}),
};

helper db => sub { 
  my $dbh = DBI->connect($config->{dbi}, $config->{dbUser}, $config->{dbPassword}) || die "Could not connect";
  $dbh
};

helper login => sub {
  my $self = shift;
  return if $self->session('name');
  my $login = $ENV{'REMOTE_USER'} || lc guid_string();
  $self->session( name => $login,
                  ip   => $self->tx->remote_address );
  $self->app->log->info($self->session('name') . " logged in from " . $self->tx->remote_address);
};

helper logout => sub {
  my $self = shift;
  $self->session( expires => 1 );
  $self->app->log->info($self->session('name') . " logged out");
};

helper create_room => sub {
  my $self = shift;
  my ($name,$owner) = @_;
  return undef if ( $self->get_room($name) || !$self->valid_room_name($name));
  my $sth = eval { $self->db->prepare("INSERT INTO rooms (name,create_timestamp,activity_timestamp,owner,token,realm) VALUES (?,?,?,?,?,?);") } || return undef;
  my $tp = join '' => map{('a'..'z','A'..'Z','0'..'9')[rand 62]} 0..49;
  $sth->execute($name,time(),time(),$owner,$tp,$config->{realm}) || return undef;
  $self->app->log->info("room $name created by " . $self->session('name'));
  return 1;
};

helper get_room => sub {
  my $self = shift;
  my ($name) = @_;
  my $sth = eval { $self->db->prepare("SELECT * from rooms where name=?;") } || return undef;
  $sth->execute($name) || return undef;
  return $sth->fetchall_hashref('name')->{$name};
};

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

helper add_participant => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room($name) || return undef;
  my $sth = eval { $self->db->prepare("INSERT IGNORE INTO participants (id,participant) VALUES (?,?);") } || return undef;
  $sth->execute($room->{id},$participant) || return undef;
  $self->app->log->info($self->session('name') . " joined the room $name");
  return 1;
};

helper remove_participant => sub {
  my $self = shift;
  my ($name,$participant) = @_;
  my $room = $self->get_room($name) || return undef;
  my $sth = eval { $self->db->prepare("DELETE FROM participants WHERE id=? AND participant=?;") } || return undef;
  $sth->execute($room->{id},$participant) || return undef;
  $self->app->log->info($self->session('name') . " leaved the room $name");
  return 1;
};

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

helper has_joined => sub {
  my $self = shift;
  my ($session,$name) = @_;
  my $ret = 0;
  my $sth = eval { $self->db->prepare("SELECT * FROM rooms WHERE name=? AND id IN (SELECT id FROM participants WHERE participant=?)") } || return undef;
  $sth->execute($name,$session) || return undef;
  $ret = 1 if ($sth->rows > 0);
  return $ret;
};

helper delete_rooms => sub {
  my $self = shift;
  $self->app->log->debug('Removing unused rooms');
  eval {
    my $timeout = time()-$config->{inactivityTimeout};
    $self->db->do("DELETE FROM participants WHERE id IN (SELECT id FROM rooms WHERE activity_timestamp < $timeout AND persistent='0');");
    $self->db->do("DELETE FROM rooms WHERE activity_timestamp < $timeout AND persistent='0';");
  } || return undef;
  return 1;
};

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
  my $len = length $name;
  # A few names are reserved
  my @reserved = qw(about help feedback goodbye admin create localize action missing dies password);
  if ($len > 0 && $len < 50 && $name =~ m/^[\w\-]+$/ && !grep { $name eq $_ }  @reserved){
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

# return the mtime of a file
helper get_mtime => sub {
  my $self = shift;
  my ($file) = @_;
  return stat($file)->mtime;
};

# password protect a room
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

# Set owner password
helper set_owner_pass => sub {
  my $self = shift;
  my ($room,$pass) = @_;
  return undef unless ( %{ $self->get_room($room) });
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

any '/' => 'index';

get '/about' => sub {
  my $self = shift;
  $self->stash( components => $components );
} => 'about';

get '/help' => 'help';

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
  $self->redirect_to($self->url_for('feedback_thanks'));
};

get 'feedback_thanks' => 'feedback_thanks';

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

# This handler creates a new room
post '/create' => sub {
  my $self = shift;
  $self->res->headers->cache_control('max-age=1, no-cache');
  my $name = $self->param('roomName') || $self->get_random_name();
  $self->login;
  unless ($self->valid_room_name($name)){
    return $self->render('error',
      room => $name,
      msg  => $self->l('ERROR_NAME_INVALID'),
      err  => 'ERROR_NAME_INVALID'
    );
  }
  $self->delete_rooms;
  unless ($self->create_room($name,$self->session('name'))){
    return $self->render('error',
      room => $name,
      msg  => $self->l('ERROR_NAME_CONFLICT'),
      err  => 'ERROR_NAME_CONFLICT'
    );
  }
  else{
    $self->session($name => {role => 'owner'});
    $self->redirect_to($self->url_for('/') . $name);
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
  if ($data->{owner_password} && Crypt::SaltedHash->validate($data->{owner_password}, $pass)){
    $self->session($room => {role => 'owner'});
    $self->redirect_to($self->url_for('/') . $room);
  }
  elsif ($data->{join_password} && Crypt::SaltedHash->validate($data->{join_password}, $pass)){
    $self->session($room => {role => 'participant'});
    $self->redirect_to($self->url_for('/') . $room);
  }
  else{
    $self->render('error',
      err  => 'WRONG_PASSWORD',
      msg  => sprintf ($self->l("WRONG_PASSWORD"), $room),
      room => $room
    );
  }
};

get '/(*room)' => sub {
  my $self = shift;
  my $room = $self->stash('room');
  # Redirect to lower case
  if ($room ne lc $room){
    $self->redirect_to($self->url_for('/') . lc $room);
  }
  $self->delete_rooms;
  # Not auth yet, probably a guest
  $self->login;
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
  my @participants = $self->get_participants($room);
  if ($data->{'locked'}){
    unless (($self->session('name') eq $data->{'owner'}) || (grep { $_ eq $self->session('name') } @participants )){
      return $self->render('error',
        msg => sprintf($self->l("ERROR_ROOM_s_LOCKED"), $room),
        err => 'ERROR_ROOM_s_LOCKED',
        room => $room
      );
    }
  }
  if ($data->{join_password} && (!$self->session($room) || $self->session($room)->{role} !~ m/^participant|owner$/)){
    my $url = $self->url_for('/');
    $url .= ($url =~ m/\/$/) ? '' : '/';
    return $self->redirect_to($url . 'password/' . $room);
  }
  # Set this peer as a simple participant if he has no role yet
  $self->session($room => {role => 'participant'}) if (!$self->session($room) || !$self->session($room)->{role});
  $self->cookie(vroomsession => encode_base64($self->session('name') . ':' . $data->{name} . ':' . $data->{token}, ''), {expires => time + 60});
  # Add this user to the participants table
  unless($self->add_participant($room,$self->session('name'))){
    return $self->render('error',
      msg  => $self->l('ERROR_OCCURED'),
      err  => 'ERROR_OCCURED',
      room => $room
    );
  }
  $self->stash(locked       => $data->{locked} ? 'checked':'',
               turnPassword => $data->{token});
  $self->render('join');
};

post '/action' => sub {
  my $self = shift;
  my $action = $self->param('action');
  my $room = $self->param('room') || "";
  if (!$self->session('name') || !$self->has_joined($self->session('name'), $room) || !$self->session($room) || !$self->session($room)->{role}){
    return $self->render(
             json => {
               msg    => $self->l('ERROR_NOT_LOGGED_IN'),
               status => 'error'
             },
           );
  }
  $self->stash(room => $room);
  my $data = $self->get_room($room);
  return $self->render(
           json => {
             msg    => sprintf ($self->l("ERROR_ROOM_s_DOESNT_EXIST"), $room),
             status => 'error'
           },
         ) unless ($data);

  if ($action eq 'invite'){
    my $rcpt    = $self->param('recipient');
    my $message = $self->param('message');
    $self->email(
      header => [
        Subject => encode("MIME-Header", $self->l("EMAIL_INVITATION")),
        To => $rcpt
      ],
      data => [
        template => 'invite',
        room     => $room,
        message  => $message
      ],
    ) ||
    return $self->render(
      json => {
        msg    => $self->l('ERROR_OCCURED'),
        status => 'error'
      },
    );
    $self->app->log->info($self->session('name') . " sent an invitation for room $room to $rcpt");
    $self->render(
      json => {
        msg    => sprintf($self->l('INVITE_SENT_TO_s'), $rcpt),
        status => 'success'
      }
    );
  }
  if ($action =~ m/(un)?lock/){
    my ($lock,$success);
    if ($action eq 'lock'){
      $lock = 1;
      $success = $self->l('ROOM_LOCKED');
    }
    else{
      $lock = 0;
      $success = $self->l('ROOM_UNLOCKED');
    }
    my $room = $self->param('room');
    my $res = $self->lock_room($room,$lock);
    unless ($res){
      return $self->render(
               json => {
                 msg => $self->l('ERROR_OCCURED'),
               },
               status   => '500'
             );
    }
    return $self->render(
             json => {
               msg => $success,
             }
           );
  }
  elsif ($action eq 'ping'){
    my $res = $self->ping_room($room);
    # Cleanup expired rooms every ~10 pings
    if ((int (rand 100)) <= 10){
      $self->delete_rooms;
    }
    if (!$res){
      return $self->render(
               json => {
                 msg    => $self->l('ERROR_OCCURED'),
                 status => 'error'
               },
             );
    }
    else{
      return $self->render(
               json => {
                 msg    => '',
                 status => 'success'
               }
             );
    }
  }
  elsif ($action eq 'setPassword'){
    my $pass = $self->param('password');
    my $type = $self->param('type') || 'join';
    $pass = undef if ($pass && $pass eq '');
    my $res = undef;
    my $errmsg = 'ERROR_OCCURED';
    if ($self->session($room)->{role} eq 'owner'){
      if ($type eq 'owner'){
        $res = $self->set_owner_pass($room,$pass);
      }
      else{
        $res = $self->set_join_pass($room,$pass);
      }
    }
    else{
      $errmsg = 'NOT_ALLOWED';
    }
    if (!$res){
      return $self->render(
               json => {
                 msg    => $self->l($errmsg),
                 status => 'error'
               },
             );
    }
    else{
      return $self->render(
               json => {
                 msg    => ($pass) ? $self->l('PASSWORD_SET') : $self->l('PASSWORD_REMOVED'),
                 status => 'success'
               }
             );
    }
  }
  elsif ($action eq 'authenticate'){
    my $pass = $self->param('password');
    my $res = undef;
    my $msg = 'ERROR_OCCURED';
    my $status = 'error';
    if ($data->{owner_password} && Crypt::SaltedHash->validate($data->{owner_password}, $pass)){
      $self->session($room, {role => 'owner'});
      $msg = 'AUTH_SUCCESS';
      $status = 'success';
    }
    elsif ($data->{owner_password}){
      $msg = 'WRONG_PASSWORD';
    }
    else{
      $msg = 'NOT_ALLOWED';
    }
    return $self->render(
               json => {
                 msg    => $self->l($msg),
                 status => $status
               },
             );
  }
  elsif ($action eq 'getRole'){
    return $self->render(
               json => {
                 role         => $self->session($room)->{role},
                 owner_auth   => ($data->{owner_password}) ? 'yes' : 'no',
                 join_auth    => ($data->{join_password})  ? 'yes' : 'no',
                 status       => 'success'
               },
             );
  }
};

# Not found (404)
get '/missing' => sub { shift->render('does_not_exist') };
# Exception (500)
get '/dies' => sub { die 'Intentional error' };

push @{app->renderer->paths}, '../templates/'.$config->{template};
app->secret($config->{secret});
app->sessions->secure(1);
app->sessions->cookie_name('vroom');
app->start;

