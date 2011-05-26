package FCGI::Spawn::TestKit::Utilized;

use Moose;
use MooseX::FollowPBP;

use Try::Tiny;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestKit' );

has( qw/util    is rw lazy 1 builder init_util isa/ => 'FCGI::Spawn::TestUtils', );

__PACKAGE__->meta->make_immutable;

sub init_util{
  my $self = shift;
  my $name = $self -> get_name;
  my $util = FCGI::Spawn::TestUtils -> new( $name );
  return $util;
}

sub test_obj{
  my( $self, $class ) = @_;
  my $util = $self -> get_util;
  my $obj = $self -> SUPER::test_obj( $class => ( 'util' => $util, ), );
}

1;
