package FCGI::Spawn::Tests::XStatsCached;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Persistent' );

has( '+descr' => ( 'default' => 'xinc() is cached', ), );

__PACKAGE__->meta->make_immutable;

sub change_persistence{
}

1;
