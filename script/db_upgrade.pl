#!/usr/bin/env perl

use warnings;
use strict;

use File::Basename;
use lib dirname($0) . '/../lib';
use DBI;
use Vroom::Constants;
use Vroom::Conf;
use utf8;

my $config = Vroom::Conf::get_conf();

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
    $dbh->do(qq{ UPDATE `config` SET `value`='3' WHERE `key`='schema_version' });
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

if ($cur_ver < 4){
  print "Upgrading the schema to version 4\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ ALTER TABLE `rooms` ADD COLUMN `max_members` TINYINT UNSIGNED DEFAULT '0' AFTER `persistent` });
    $dbh->do(qq{ UPDATE `config` SET `value`='4' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 4\n";
}

if ($cur_ver < 5){
  print "Upgrading the schema to version 5\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ DROP TABLE `denied_peer_ip` });
    $dbh->do(qq{ DROP TABLE `allowed_peer_ip` });
    $dbh->do(qq{ DROP TABLE `turn_secret` });
    $dbh->do(qq{ DROP TABLE `turnusers_st` });
    $dbh->do(qq{ DROP VIEW `turnusers_lt` });
    $dbh->do(qq{ ALTER TABLE `rooms` DROP COLUMN `token` });
    $dbh->do(qq{ ALTER TABLE `rooms` DROP COLUMN `realm` });
    $dbh->do(qq{ UPDATE `config` SET `value`='5' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 5\n";
}

if ($cur_ver < 6){
  print "Upgrading the schema to version 6\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ ALTER TABLE `rooms` DROP COLUMN `owner` });
    $dbh->do(qq{ UPDATE `config` SET `value`='6' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 6\n";
}

if ($cur_ver < 7){
  print "Upgrading the schema to version 7\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ CREATE TABLE `session_keys` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
                                              `key` VARCHAR(160) NOT NULL,
                                              `date` DATETIME NOT NULL DEFAULT 0,
                                              PRIMARY KEY (`id`),
                                              INDEX (`date`))
                 ENGINE INNODB DEFAULT CHARSET=utf8; });
    $dbh->do(qq{ UPDATE `config` SET `value`='7' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 7\n";
}

if ($cur_ver < 8){
  print "Upgrading the schema to version 8\n";
  eval {
    $dbh->begin_work;
    $dbh->do(qq{ CREATE TABLE `audit` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
                                       `date` DATETIME NOT NULL,
                                       `event` VARCHAR(255) NOT NULL,
                                       `from_ip` VARCHAR(45) DEFAULT NULL,
                                       `user` VARCHAR(255) DEFAULT NULL,
                                       `message` TEXT NOT NULL,
                                        PRIMARY KEY (`id`),
                                        INDEX (`date`),
                                        INDEX (`event`),
                                        INDEX (`from_ip`),
                                        INDEX (`user`))
                 ENGINE INNODB DEFAULT CHARSET=utf8; });
    $dbh->do(qq{ UPDATE `config` SET `value`='8' WHERE `key`='schema_version' });
    $dbh->commit;
  };
  if ($@){
    print "An error occurred: " . $dbh->errstr . "\n";
    local $dbh->{RaiseError} = 0;
    $dbh->rollback;
    exit 255;
  };
  print "Successfully upgraded to schema version 8\n";
}

