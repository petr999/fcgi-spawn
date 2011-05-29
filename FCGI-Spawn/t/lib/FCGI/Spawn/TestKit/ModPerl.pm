package FCGI::Spawn::TestKit::ModPerl;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

has( qw/+self_skip default 1/, );
has( qw/+push_tests default/ => sub{ return [
  qw/basic serialize serialize_post serialize_mp2 serialize_post_mp2/,
]; }, );

__PACKAGE__->meta->make_immutable;


1;
