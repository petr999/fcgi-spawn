package FCGI::Spawn::TestKit::SaveEnv;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

__PACKAGE__->meta->make_immutable;

1;
