package FCGI::Spawn::TestKit::CgiFast;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

has( qw/+self_skip default 1/, );
has( qw/+push_tests default/ => sub{ return [
  qw/basic_cf serialize serialize_cf serialize_post_cf save_env/,
]; }, );

__PACKAGE__->meta->make_immutable;

1;
