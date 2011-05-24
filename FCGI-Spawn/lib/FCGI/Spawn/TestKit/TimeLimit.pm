package FCGI::Spawn::TestKit::TimeLimit;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable' );

use Carp;

use FCGI::Spawn::TestUtils;

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  # push( @$rv => qw/time_limit_term_ignore time_limit_kill/, );
  return $rv;
}

1;
