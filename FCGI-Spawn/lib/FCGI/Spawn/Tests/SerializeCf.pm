package FCGI::Spawn::Tests::SerializeCf;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Serialize', );
has( '+descr' => ( 'default' => 'Serialization via CGI::Fast', ), );

1;
