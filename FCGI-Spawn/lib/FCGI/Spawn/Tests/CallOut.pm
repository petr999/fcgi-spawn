package FCGI::Spawn::Tests::CallOut;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+descr' => ( 'default' => 'Do a callout:', ), );

__PACKAGE__->meta->make_immutable;

sub init_test_var{ [ qw/it is test/, ]; }

1;
