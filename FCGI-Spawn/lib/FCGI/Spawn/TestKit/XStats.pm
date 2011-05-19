package FCGI::Spawn::TestKit::XStats;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );


sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  push( @$rv => ( qw/x_stats_dependence x_stats_cached/, ), );
  return $rv;
}

1;
