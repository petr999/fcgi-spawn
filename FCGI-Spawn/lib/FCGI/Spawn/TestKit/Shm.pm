package FCGI::Spawn::TestKit::Shm;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit', );

sub init_tests_list{
  return [ qw/shm/, ];
}
1;
