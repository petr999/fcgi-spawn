package FCGI::Spawn::TestKit::Spawnable;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit::Utilized', );

sub init_tests_list{
  my $self = shift;
  croak unless my $class = ref( $self );
  my $name = $class -> make_name_from_class;
  my $rv =  [ 'spawn' => $name, ];
  return $rv;
}

1;
