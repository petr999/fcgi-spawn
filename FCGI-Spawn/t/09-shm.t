#!/usr/bin/perl

use strict;
use warnings;

use English;
use lib 'lib';

use FCGI::Spawn::BinUtils qw/get_shared_scalar/;

use Test::More tests => 1;

;

TODO: {
  local $TODO = 'requires uid=0 for IPC::MM to work';
  $UID ? ok( 1 => 'TODO' )
    : is( &get_shared_scalar(), undef, 'Sharing variable in memory' );
}
