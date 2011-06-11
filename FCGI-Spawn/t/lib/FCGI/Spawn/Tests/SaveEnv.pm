package FCGI::Spawn::Tests::SaveEnv;

use Moose;
use MooseX::FollowPBP;

extends('FCGI::Spawn::Tests::Persistent');

has( '+state'     => ( qw/isa HashRef/, ) );
has( '+trials'    => ( qw/default 25/, ) );
has( '+sngl_chng' => ( qw/default 0/, ), );
has( '+descr'     => ( 'default' => 'Keep environment from change', ), );

__PACKAGE__->meta->make_immutable;

1;
