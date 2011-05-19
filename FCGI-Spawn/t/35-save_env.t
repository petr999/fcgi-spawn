#!/usr/bin/perl -w

use strict;
use warnings;

use lib 'lib';

use FCGI::Spawn::TestKit;

FCGI::Spawn::TestKit::perform( ( __FILE__ ) => ( 'name' => '', ), );
