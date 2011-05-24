package FCGI::Spawn::TestKit::UnCleanMain;

use Moose;
use MooseX::FollowPBP;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

__PACKAGE__->meta->make_immutable;

1;
