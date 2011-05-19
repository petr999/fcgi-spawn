#!/usr/bin/perl -w

use strict;
use Test::More;

use lib 'lib';

use FCGI::Spawn::ConfigFile;

my $conf;
ok( $conf = FCGI::Spawn::ConfigFile->new()  => 'Config file object creation', )
  and ok( $conf->read_fsp_config_file()     => 'Config file reading',         )
;

done_testing;

