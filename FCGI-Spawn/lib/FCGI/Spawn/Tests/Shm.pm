package FCGI::Spawn::Tests::Shm;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests', );

use English;
use Test::More;

use FCGI::Spawn::TestUtils;

sub check{
  my $shared;
  my $ipc;
  share_var( \$shared => \$ipc, ) ;
  $shared = 321;
  if( $UID == 0 ){
    my $pid = fork;
    if( defined $pid ){
      if( $pid ){
        sleep 1;
        is( $shared => 123, 'Share variable between forks' );
      } else {
        $shared = 123 if $shared == 321;
        exit;
      }
    } else {
      die "Cannot fork: $@ $!";
    }
  }
}

1;
