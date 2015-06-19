#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib dirname($0) . '/../lib';
use Vroom::Conf;

chdir dirname($0) . '/..';

my $config = Vroom::Conf::get_conf();

$ENV{'PERL5LIB'} = 'lib';

if ($config->{'daemon.backend'} eq 'morbo'){
  exec ('/usr/bin/morbo',
        '-l', 'http://' . $config->{'daemon.listen_ip'} . ':' . $config->{'daemon.listen_port'},
        '-w', 'conf/settings.ini',
        '-w', 'lib',
        '-w', 'templates',
        '-v', 'vroom.pl');
}
else{
  exec ('/usr/bin/hypnotoad', '-f', 'vroom.pl');
}
