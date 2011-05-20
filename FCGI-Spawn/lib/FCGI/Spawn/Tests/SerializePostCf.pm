package FCGI::Spawn::Tests::SerializePostCf;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::SerializePost', );
has( '+descr' => ( 'default' => 'Serialization via POST and CGI::Fast', ), );

1;
