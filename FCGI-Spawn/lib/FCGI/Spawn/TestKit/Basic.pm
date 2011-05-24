package FCGI::Spawn::TestKit::Basic;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit::Utilized', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  croak unless my $class = ref( $self );
  my $name = 'basic';
  if( $class =~ m/CgiFast$/ or $class =~ m/Cf$/ ){
    $name .= '_cf';
  }
  my $rv =  [ 'spawn' => $name, ];
  return $rv;
}

1;
