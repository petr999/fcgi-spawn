#!/usr/bin/perl

use strict;
use warnings;

use English;
use lib 'lib';

use FCGI::Spawn::TestUtils;

use Test::More;

my $shared;
my $ipc;

share_var( \$shared => \$ipc, ) ;

$shared = 321;

if( $UID == 0 ){
  my $pid = fork;
  if( defined $pid ){
    if( $pid ){
      sleep FCGI::Spawn::TestUtils -> new -> get_timeout;
      is( $shared => 123, 'Share variable between forks' );
    } else {
      $shared = 123 if $shared == 321;
      exit;
    }
  } else {
    die "Cannot fork: $@ $!";
  }
}

done_testing;
