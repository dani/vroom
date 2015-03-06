#!/usr/bin/env perl

use warnings;
use strict;

use File::Basename;
use lib dirname($0) . '/../lib';
use DBI;
use Config::Simple;
use Vroom::Constants;
use utf8;


# Load and parse global config file
my $cfg = new Config::Simple();
$cfg->read(dirname($0) . '/../conf/settings.ini');
my $config = $cfg->vars();

# Open a handle to the database server
my $dbh = DBI->connect(
  $config->{'database.dsn'},
  $config->{'database.user'},
  $config->{'database.password'},
  { 
    mysql_enable_utf8  => 1,
    PrintError         => 0,
    RaiseError         => 1,
    ShowErrorStatement => 1,
  }
) || die "Cannot connect to the database: " . DBI->errstr . "\n";

# Check current schema version
my $sth = eval {
  $dbh->prepare('SELECT `value`
                   FROM `config`
                   WHERE `key`=\'schema_version\'');
};
if ($@){
  die "DB Error: $@\n";
}
$sth->execute;
if ($sth->err){
  die "DB Error: " . $sth->errstr . " (code: " . $sth->err . ")\n";
}
my $cur_ver;
$sth->bind_columns(\$cur_ver);
$sth->fetch;

print "Current version is $cur_ver\n";

if ($cur_ver > Vroom::Constants::DB_VERSION){
  die "Database version is unknown, sorry (current version is $cur_ver when it should be " .
        Vroom::Constants::DB_VERSION . ")\n";
}

if ($cur_ver == Vroom::Constants::DB_VERSION){
  print "Database is up to date, nothing to do\n";
  exit 0;
}

if ($cur_ver < 2){
  print "Upgrading the schema to version 2\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ ALTER TABLE `room_participants` MODIFY `peer_id` VARCHAR(60) });
    $dbh->do(qq{ UPDATE `config` SET `value`='2' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 2\n";
}

if ($cur_ver < 3){
  print "Upgrading the schema to version 3\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ DROP TABLE `room_participants` });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 3\n";
}
