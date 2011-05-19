#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::More;

use Const::Fast;

const my @imported => qw/get_fork_rv get_fork_pid kill_proc_dead/;

my( $pid, $util, $timeout );
require_ok(         'FCGI::Spawn::BinUtils',  )
  and use_ok(       'FCGI::Spawn::BinUtils',  )
  and use_ok(       'FCGI::Spawn::TestUtils', )
  and ok( not( grep{ not defined $::{ $_ } } @imported ) 
          => 'BinUtils import success' )
  and is( get_fork_rv( sub{ return 3; } ) => 3, 'Get value from fork()' )
  and ok( $util = FCGI::Spawn::TestUtils -> new, 'TestUtils constructor' )
  and ok( $timeout = $util->get_timeout, 'Get timeout from utils' )
  and cmp_ok( $pid = get_fork_pid( sub{ sleep $timeout; } ), '>', 0, 'Get PID from fork()' )
  and ok( kill_proc_dead( $pid )                       => 'Process killer' )
;
done_testing;
