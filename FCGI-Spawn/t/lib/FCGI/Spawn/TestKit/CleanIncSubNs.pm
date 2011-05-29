package FCGI::Spawn::TestKit::CleanIncSubNs;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

has( qw/+push_tests default/ => sub{ return [
  qw/stats_cisns/,
]; }, );

__PACKAGE__->meta->make_immutable;

1;
