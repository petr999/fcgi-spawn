package FCGI::Spawn::Tests::KillProcDead;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use Const::Fast;
use Try::Tiny;

use FCGI::Spawn::TestUtils;
use FCGI::Spawn::BinUtils qw/:testutils/;

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'Killing process with TERM ignoration', ), );

__PACKAGE__->meta->make_immutable;

sub bore_proc{
  local $SIG{ 'TERM' } = 'IGNORE';
  sleep shift;
}

sub check{
  my $self = shift;
  my $shared = 0;
  my( $ipc, $pid, $rv, );

  share_var( \$shared => \$ipc, ) ;

  $pid = fork;

  if( defined $pid ){
    if( $pid ){
      select( undef, undef, undef, 0.025 );
      $rv = ok( kill_proc_dead( $pid ) => 'Killing TERM-ignorant sleeping process' );
      sleep 5;
      $rv &&= is( $shared => 123, 'action is taken after sleep despite TERM sent' );
    } else {
      bore_proc( 3 );
      $shared = 123;
      exit;
    }
  } else {
    die "Cannot fork: $@ $!";
  }

  if( $rv ){
    $shared = 0;
    $pid = fork;
    if( defined $pid ){
      if( $pid ){
        select( undef, undef, undef, 0.025 );
        ok( kill_proc_dead( $pid => 2, ) => 'Killing TERM-ignorant sleeping process', );
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

  return $rv;
}

sub on_time_out{
  my( $self, $died => $pid, ) = @_;
  unless( $died ){
    $self -> set_failure( "Process was not dead: $pid", );
  }
}

1;
