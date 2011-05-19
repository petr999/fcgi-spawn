#!/usr/bin/perl

use strict;
use warnings;

use English;
use lib 'lib';

use Test::More;

use FCGI::Spawn::TestUtils;
my $util = FCGI::Spawn::TestUtils -> new;

my( $spawn, $spawn_pid );

if( is( $UID => 0, 'User is a root', )
    and use_ok( 'FCGI' )
    and use_ok( 'FCGI::Spawn' )
    and ok( $spawn = FCGI::Spawn->new() => 'Spawner initialisation' )
    and ok( $spawn_pid = get_fork_pid( sub{  $spawn->spawn; } ) => 'Spawning')
  ){
  select( undef, undef, undef, 0.025 );
  ok( kill_proc_dead( $spawn_pid ) => 'finding if spawn ended' );
}

done_testing;
