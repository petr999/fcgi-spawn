#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use lib 'lib';

use FCGI::Spawn::ConfigFile;

ok( my $conf = FCGI::Spawn::ConfigFile->new(), 'Config file object creation', );
ok( $conf->read_fsp_config_file(), 'Config file reading', );

