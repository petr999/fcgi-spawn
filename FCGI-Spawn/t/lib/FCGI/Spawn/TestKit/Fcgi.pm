package FCGI::Spawn::TestKit::Fcgi;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

has( qw/+self_skip default 1/, );
has( qw/+push_tests default/ => sub{ return [
  qw/basic serialize serialize_post/,
]; }, );

__PACKAGE__->meta->make_immutable;

1;
