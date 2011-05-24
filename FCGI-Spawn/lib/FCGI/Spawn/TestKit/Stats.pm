package FCGI::Spawn::TestKit::Stats;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  push( @$rv => 'stats_mod', );
  return $rv;
}

1;
