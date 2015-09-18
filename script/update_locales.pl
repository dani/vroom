#!/usr/bin/perl -w

use strict;
use warnings;
use File::Basename;
use Locale::Maketext::Extract::Run 'xgettext';

chdir dirname($0) . '/..';

my @files = qw(vroom public/js/vroom.js);
push @files, glob('templates/default/*');

foreach my $lang (map { basename(s/\.po$//r) } glob('lib/Vroom/I18N/*.po')){
  xgettext(
    '-o', 'lib/Vroom/I18N/' . $lang . '.po',
     '--wrap',
    @files
  );
}
