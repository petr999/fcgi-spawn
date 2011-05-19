package FCGI::Spawn::Tests::XStatsCached;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Persistent' );

has( '+descr' => ( 'default' => 'xinc() is cached', ), );

sub change_persistence{
}

1;
