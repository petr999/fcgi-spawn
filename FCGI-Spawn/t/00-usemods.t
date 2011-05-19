#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::More::UTF8;

use lib 'lib';

use_ok 'FCGI::Spawn';
use_ok 'FCGI::Spawn::ConfigFile';
use_ok 'FCGI::Spawn::BinUtils';
use_ok 'FCGI::Spawn::TestUtils';

require_ok 'FCGI::Spawn::ModPerl';

done_testing;
