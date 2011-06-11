package FCGI::Spawn::Tests::PreLoad;

use Moose;
use MooseX::FollowPBP;

use Const::Fast;

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+descr' => ( 'default' => 'Do a preload script', ), );

__PACKAGE__->meta->make_immutable;

sub init_test_var { return [ 'ITISTEST', ]; }

1;
