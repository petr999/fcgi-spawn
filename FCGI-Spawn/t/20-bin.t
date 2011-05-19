#!/usr/bin/perl -w

use strict;
use warnings;

use English;
use lib 'lib';

use Test::More;

use POSIX ':sys_wait_h';

use FCGI::Spawn::TestUtils;
use FCGI::Spawn qw/statnames_to_policy/;



my $util = FCGI::Spawn::TestUtils -> new;
my ( $pid_file, $log_file ) = map{
    my $s_name = "get_$_"."_fname"; $util -> $s_name;
  } qw/pid log/
;
my $user = $util -> get_user;
my $timeout = $util -> get_timeout;
if( is( $UID => 0, 'User uid=0 is required to run this test' )
    and cmp_ok( getpwnam( $user ), '>', 0, "System user $user is necessary to exist for this test" )
    and use_ok( 'FCGI' )
    and use_ok( 'IPC::MM' )
  ){


  my( $pid, $ppid, $fsp_pid_fh );

  # 'log file' mode tests
  ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' );
  if( ok( $ppid = get_fork_pid( $util -> spawn_fcgi ) => 'Spawner initialisation' ) ){
    sleep $timeout;
    my $wp = waitpid( $ppid => WNOHANG ) != -1;
    ok( $wp, "FCGI Spawned" )
      and ok( $pid = $util -> read_pidfile => 'Reading pid file' )
      and kill_proc_dead( $pid )
      and ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' )
      and ok( ( ( -f $log_file ) and ( [ stat $log_file ]->[ statnames_to_policy( 'size' )->[ 0 ] ] > 0 ) ) 
          => 'Finding if log file exists',
        )
    ;
  }
  $util -> rm_files_if_exists;

    # 'no detach' mode tests, Ctrl-C emulation
    if( ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' )
        and ok( $ppid = get_fork_pid( $util -> spawn_fcgi( 1 ) ) => 'Spawner initialisation' )
      ){
      sleep $timeout;
      if( is( waitpid( $ppid => WNOHANG ) => 0, "FCGI spawned: pid $ppid" ) 
          and kill INT => $ppid
        ){
        sleep $timeout;
        isnt( waitpid( $ppid => WNOHANG ) => 0, "FCGI stopped " )
        or kill_proc_dead( $ppid );
        ok( ( not -f $pid_file ) => 'Finding if pid file doesn\'t exist' );
      }
    }

    $util -> rm_files_if_exists;
}
done_testing;
