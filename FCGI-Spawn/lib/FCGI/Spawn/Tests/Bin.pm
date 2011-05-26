package FCGI::Spawn::Tests::Bin;

use Moose;
use MooseX::FollowPBP;

use English '$UID';
use Test::More;
use Try::Tiny;
use Const::Fast;

use FCGI::Spawn::TestUtils;
use FCGI::Spawn::BinUtils ':testutils';
use FCGI::Spawn qw/statnames_to_policy/;

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'run fcgi_spawn binary', ), );
has( qw/timeout is ro isa Int required 1 default 10/, );

__PACKAGE__->meta->make_immutable;

const( my $user => 'nobody', );

sub check{ 
  my $self = shift;
  my @utils_args = (
    [ 'sock_name' => join( '/',
        './etc-test' => 'spawner_' . rand( 100000 ) . '.sock', ),
    ],
    [], # TCP is the default in TestUtils
  );
  my @utils = map{ FCGI::Spawn::TestUtils -> new( @$_, ) } @utils_args;
  my $rv = 1;
  if( ok( $rv = ( $UID != 0 or getpwnam( $user ) > 0 )
        => "System user $user is necessary to exist for this test if you are root", )
      and use_ok( 'FCGI', ) and use_ok( 'IPC::MMA', )
    ){
    try{
      foreach my $util( @utils ){
        $self -> start_logged( $util, );
        $self -> start_foreground( $util, );
      }
    } catch {
      ok( 0 => 'Failed trying to start a binary', );
    };
  }
  return $rv;
}

sub start_logged{
  my( $self => $util, ) = @_;
  my $rv = 1; my ( $pid_file, $log_file ) = retr_file_names( $util );
  my( $pid => $ppid, );
  if( $rv ){
    $rv &&= not( -f $pid_file );
    ok( $rv => "Finding if pid file $pid_file doesn\'t exist", );
  }
  if( $rv ){
    $rv &&= $ppid = get_fork_pid( $util -> spawn_fcgi, );
    ok( $rv => 'Spawner initialisation', );
  }
  if( $rv ){
    $pid = $util -> read_pidfile( $ppid, );
    $rv &&= $pid;
    unless( $rv ){ $util -> inspect_log; }
    ok( $rv => 'Reading pid file', );
  }
  if( $rv ){ my( $is_sock_tcp => $sock_name, )
      = ( $util -> addr_port => $util -> get_sock_name, );
    unless( $is_sock_tcp ){
      sleep $self -> get_timeout;
      $rv &&= ( -S $sock_name );
      ok( $rv => "Socket file existence: $sock_name", );
    }
    my $kill_rv = kill_proc_dead( $pid );
    ok( $kill_rv => "Finding if process $pid was killed", );
    $rv &&= $kill_rv;
  }
  if( $rv ){
    $rv &&= not( -f $pid_file );
    ok( $rv => "Finding if pid file $pid_file was deleted by daemon", );
    my $log_rv = ( ( -f $log_file ) and ( [ stat $log_file ]->[
      statnames_to_policy( 'size' )->[ 0 ] ] > 0 ) );
    $rv &&= $log_rv;
    ok( $rv => 'Finding if log file was left by daemon', );
  }
  $util -> rm_files_if_exists;
  return $rv;
}

sub start_foreground{
  my( $self => $util, ) = @_;
  my $rv = 1; my $ppid; my $timeout = $self -> get_timeout;
  my ( $pid_file, $log_file ) = retr_file_names( $util );
  if( $rv ){
    $rv &&= not( -f $pid_file );
    ok( $rv => 'Finding if pid file doesn\'t exist', );
  }
  if( $rv ){
    $ppid = get_fork_pid( $util -> spawn_fcgi( 1, ), );
    $rv &&= $ppid;
    ok( $rv => 'Spawner initialisation', );
  }
  if( $rv ){
    diag( "Sleeping $timeout seconds to ensure daemon"
          . " is still running" );
    sleep $timeout;
    $rv &&= not( is_process_dead( $ppid, ) );
    ok( $rv => "FCGI spawned: pid $ppid", );
    # Ctrl-C
    if( $rv and kill( INT => $ppid, ) ){
      diag( "Sleeping $timeout seconds to ensure daemon"
            . " is not running" );
      sleep $timeout;
      $rv &&= is_process_dead( $ppid, );
      ok( $rv => "FCGI pid $ppid stopped", );
      unless( $rv ){ kill_proc_dead( $ppid ); }
      $rv &&= not( -f $pid_file );
      ok( $rv => 'Finding if pid file doesn\'t exist', );
    }
  }
  $util -> rm_files_if_exists;
  return $rv;
}

sub retr_file_names{
  my $util = shift;
  my ( $pid_file, $log_file ) = map{
      my $s_name = "get_$_"."_fname"; $util -> $s_name;
  } qw/pid log/ ;
  return ( $pid_file, $log_file );
}

1;
