#!/usr/bin/perl -w

use strict;
use warnings;

use English;
use lib 'lib';

use Test::More;
use Try::Tiny;

use POSIX ':sys_wait_h';

use FCGI::Spawn::TestUtils;
use FCGI::Spawn qw/statnames_to_policy/;

my @utils_args = (
  [ 'sock_name' => join( '/',
      './etc-test' => 'spawner_' . rand( 100000 ) . '.sock', ),
  ],
  [], # TCP is the default in TestUtils
);
my @utils = map{ FCGI::Spawn::TestUtils -> new( @$_, ) } @utils_args;
my $util0 = $utils[ 0 ];
my ( $pid_file, $log_file ) = map{
    my $s_name = "get_$_"."_fname"; $util0 -> $s_name;
  } qw/pid log/
;
my $user = $util0 -> get_user;
my $timeout = $util0 -> get_timeout;
if( is( $UID => 0, 'User uid=0 is required to run this test' )
    and cmp_ok( getpwnam( $user ), '>', 0,
      "System user $user is necessary to exist for this test" )
    and use_ok( 'FCGI' )
    and use_ok( 'IPC::MM' )
  ){
  try{
    foreach my $util( @utils ){
      my( $pid, $ppid, $fsp_pid_fh );
      # 'log file' mode tests
      ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' );
      if( ok( $ppid = get_fork_pid( $util -> spawn_fcgi )
          => 'Spawner initialisation' )
        ){
        if( ok( $pid = $util -> read_pidfile( $ppid ) => 'Reading pid file' ) ){
          my( $is_sock_tcp => $sock_name, )
            = ( $util -> addr_port => $util -> get_sock_name, );
          unless( $is_sock_tcp ){
            ok( ( -S $sock_name ) => "Socket file existence: $sock_name", );
          }
          kill_proc_dead( $pid )
          and ok( ( not -f $pid_file )
            => 'Finding if pid file was deleted by daemon' )
          and ok( ( ( -f $log_file ) and ( [ stat $log_file ]->[
                    statnames_to_policy( 'size' )->[ 0 ] 
                  ] > 0 ) 
              ) => 'Finding if log file was left by daemon',
            )
          ;
        }
      }
      $util -> rm_files_if_exists;
      
      # 'no detach' mode tests, Ctrl-C emulation
      if( ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' )
          and ok( $ppid = get_fork_pid( $util -> spawn_fcgi( 1 ) ) => 'Spawner initialisation' )
        ){
        diag( "Sleeping $timeout seconds to ensure daemon is still running" );
        sleep $timeout;
        if( is( waitpid( $ppid => WNOHANG ) => 0, "FCGI spawned: pid $ppid" ) 
            and kill INT => $ppid
          ){
          sleep $timeout;
          diag( "Sleeping $timeout seconds to ensure daemon is not running" );
          isnt( waitpid( $ppid => WNOHANG ) => 0, "FCGI stopped " )
          or kill_proc_dead( $ppid );
          ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' );
        }
      }
      $util -> rm_files_if_exists;
    }
  } catch {
    ok( 0 => 'Failed trying to start a binary', );
  };
}
done_testing;
