#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More;

use FCGI::Spawn::TestUtils;

use File::Temp;
use English;

my $shared = 0;
my $ipc;

share_var( \$shared => \$ipc, ) ;

my $pid;

sub bore_proc{
  $SIG{ 'TERM' } = 'IGNORE';
  sleep shift;
}
  
if( $UID == 0 ){

  $pid = fork;
  if( defined $pid ){
    if( $pid ){
      select( undef, undef, undef, 0.025 );
      ok( kill_proc_dead( $pid ) => 'Killing TERM-ignorant sleeping process' );
      sleep 4;
      is( $shared => 123, 'action is taken after sleep despite TERM sent' );
    } else {
      bore_proc( 3 );
      $shared = 123;
      exit;
    }
  } else {
    die "Cannot fork: $@ $!";
  }
  
  $shared = 0;
  
  $pid = fork;
  if( defined $pid ){
    if( $pid ){
      select( undef, undef, undef, 0.025 );
      my $util = FCGI::Spawn::TestUtils -> new( qw/timeout 2    pid/ => $pid, );
      ok( $util -> kill_procsock => 'Killing TERM-ignorant sleeping process' );
      sleep 10;
      is( $shared => 0, 'action is not taken after sleep because KILL was sent' );
    } else {
      bore_proc( 7 );
      $shared = 123;
      exit;
    }
  } else {
    die "Cannot fork: $@ $!";
  }
}

done_testing;
