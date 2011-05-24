package FCGI::Spawn::TestKit::TimeLimit;

use Moose;
use MooseX::FollowPBP;


use Carp;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestKit::Spawnable' );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  # push( @$rv => qw/time_limit_term_ignore time_limit_kill/, );
  return $rv;
}

1;
