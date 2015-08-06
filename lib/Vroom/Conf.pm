package Vroom::Conf;

use strict;
use warnings;

use Config::Simple;

sub get_conf(){
  my $file = _find_ini();
  my $config = {};
  if ($file){
    my $cfg = new Config::Simple();
    $cfg->read($file);
    $config = $cfg->vars();
  }
  # Set default values if required
  $config->{'database.dsn'}                      ||= 'DBI:mysql:database=vroom;host=localhost';
  $config->{'database.user'}                     ||= 'vroom';
  $config->{'database.password'}                 ||= 'vroom';
  $config->{'database.redis'}                    ||= 'redis://127.0.0.1:6379/';
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
  $config->{'rooms.inactivity_timeout'}          ||= 60;
  $config->{'rooms.reserved_inactivity_timeout'} ||= 86400;
  $config->{'rooms.common_names'}                ||= '';
  $config->{'rooms.max_members'}                 ||= 0;
  $config->{'etherpad.uri'}                      ||= '';
  $config->{'etherpad.api_key'}                  ||= '';
  $config->{'etherpad.base_domain'}              ||= '';
  $config->{'directories.cache'}                 ||= 'data/cache';
  $config->{'directories.cache'}                 ||= 'data/tmp';
  $config->{'daemon.listen_ip'}                  ||= '127.0.0.1';
  $config->{'daemon.listen_port'}                ||= '8090';
  $config->{'daemon.backend'}                    ||= 'hypnotoad';
  $config->{'daemon.log_level'}                  ||= 'warn';
  $config->{'daemon.pid_file'}                   ||= '/tmp/vroom.pid';

  return $config;
}

sub _find_ini() {
  if (-e '/etc/vroom/settings.ini'){
    return '/etc/vroom/settings.ini';
  }
  elsif (-e 'conf/settings.ini'){
    return 'conf/settings.ini';
  }
  else{
    return undef;
  }
}

1;
