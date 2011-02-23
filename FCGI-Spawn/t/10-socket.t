#!/usr/bin/perl

use strict;
use warnings;

use English;
use lib 'lib';

use IPC::MM;

use Test::More tests => 1;

TODO: {
  local $TODO = 'requires FCGI.pm and an uid=0';
  ok( FCGI::Spawn->new( $conf ) => 'Spawner initialisation' );
}
