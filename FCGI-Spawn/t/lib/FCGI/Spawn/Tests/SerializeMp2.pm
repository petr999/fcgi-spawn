package FCGI::Spawn::Tests::SerializeMp2;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Serialize', );
has( '+descr' => ( 'default' => 'Serialization via mod_perl2 emulation', ), );

__PACKAGE__->meta->make_immutable;

1;
