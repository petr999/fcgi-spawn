package FCGI::Spawn::TestKit::Shm;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  return [ qw/shm/, ];
}
1;
