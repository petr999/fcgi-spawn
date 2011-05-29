package FCGI::Spawn::Tests::LogRotate;

use Moose;
use MooseX::FollowPBP;

use Test::More;

extends( 'FCGI::Spawn::Tests' );

has( '+descr' => ( 'default' => 'Rotate log file by mean of sending USR1 to logger', ), );

__PACKAGE__->meta->make_immutable;

sub check{
  my $self = shift;
  my $util = $self -> get_util;
  my $pid = $util -> get_pid;
  my $log_file = $util -> get_log_fname;
  croak( "No PID" ) unless defined( $pid ) and $pid;
  croak( "No log file" )
    unless defined( $log_file )  and length( $log_file ) and -f $log_file;
  croak( "Can not delete log file: $!" ) unless unlink $log_file;
  my $rv = not -f $log_file;
  if( $rv ){
    croak( "Can not kill USR1 $pid: $!" ) if -1 eq kill 'USR1' => $pid;
    sleep 5;
    $rv = -f $log_file;
  }
  my $descr = $self -> get_descr;
  ok( $rv => $descr, );
  return $rv;
}

1;
