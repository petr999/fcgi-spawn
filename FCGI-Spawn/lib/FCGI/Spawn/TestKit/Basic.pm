package FCGI::Spawn::TestKit::Basic;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit::Utilized', );

sub init_tests_list{
  my $self = shift;
  croak unless my $class = ref( $self );
  my $name = 'basic';
  my $rv =  [ 'spawn' => $name, ];
  return $rv;
}

1;
