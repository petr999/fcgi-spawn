package FCGI::Spawn::Tests::SerializeCf;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Serialize', );
has( '+descr' => ( 'default' => 'Serialization via CGI::Fast', ), );

__PACKAGE__->meta->make_immutable;

1;
