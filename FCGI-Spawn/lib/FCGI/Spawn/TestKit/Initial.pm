package FCGI::Spawn::TestKit::Initial;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::TestKit', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $rv =  [ qw/config_file test_utils/, ];
  return $rv;
}

1;
