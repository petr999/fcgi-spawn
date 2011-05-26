package FCGI::Spawn::TestKit::Initial;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $rv =  [ qw/config_file shm test_utils kill_proc_dead socket bin/, ];
  return $rv;
}

1;
