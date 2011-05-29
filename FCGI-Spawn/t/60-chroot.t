#!/usr/bin/perl -w

use strict;
use warnings;

use lib 't/lib';

use FCGI::Spawn::TestKit;

FCGI::Spawn::TestKit::perform( __FILE__, );
