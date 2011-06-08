package FCGI::Spawn::Tests::ModPerlHandlers;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+descr' => ( 'default' => 'ModPerl handlers', ), );
has( '+is_response_json' => ( qw/default 0/, ), );

__PACKAGE__->meta->make_immutable;

sub init_test_var{ \'HANDLER'; }

1;
