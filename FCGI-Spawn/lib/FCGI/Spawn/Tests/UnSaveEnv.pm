package FCGI::Spawn::Tests::UnSaveEnv;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::SaveEnv' );
with( 'FCGI::Spawn::Tests::RoleNegative', );


has( '+state' => ( qw/isa HashRef/, ) );
has( '+trials' => ( qw/default 25/, ) );

has( '+descr' => ( 'default' => 'Keep environment changes', ), );

1;
