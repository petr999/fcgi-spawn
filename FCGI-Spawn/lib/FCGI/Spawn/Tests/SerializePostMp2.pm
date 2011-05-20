package FCGI::Spawn::Tests::SerializePostMp2;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::SerializePost', );
has( '+descr' => ( 'default' => 'Serialization via POST and mod_perl2 emulation', ), );

1;
