package FCGI::Spawn::Tests::Uid0;

use Moose;
use MooseX::FollowPBP;

use English;
use Test::More;

extends( 'FCGI::Spawn::Tests', );
has( '+mandatory' => ( qw/default 1/, ), );
has( '+descr' => ( 'default' => 'User uid=0 is required to run this test', ), );

augment( 'check_out' => \&check, );

__PACKAGE__->meta->make_immutable;

sub check{
  my $self = shift;
  my $descr = $self -> get_descr;
  my $rv = is( $UID => 0, $descr, );
  return $rv;
}

1;
