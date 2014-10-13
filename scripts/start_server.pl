#!/usr/bin/env perl

use strict;
use warnings;
use Config::Simple;
use File::Basename;

my $dir=dirname($0);
chdir $dir . '/..';

my $cfg = new Config::Simple();
$cfg->read('conf/settings.ini');
our $config = $cfg->vars();

$config->{'daemon.listen_ip'}   ||= '127.0.0.1';
$config->{'daemon.listen_port'} ||= '8090';
$config->{'daemon.backend'}     ||= 'hypnotoad';

$ENV{'PERL5LIB'} = 'lib';

if ($config->{'daemon.backend'} eq 'morbo'){
  exec ('/usr/bin/morbo', '-l', 'http://' . $config->{'daemon.listen_ip'} . ':' . $config->{'daemon.listen_port'}, '-v', 'vroom.pl');
}
else{
  exec ('/usr/bin/hypnotoad', '-f', 'vroom.pl');
}
