package FCGI::Spawn::Tests::Chroot;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Fixed' );

has( '+descr' => ( 'default' => 'Run CGI script in a chroot environment', ), );
has( '+is_response_json' => ( qw/default 0/, ), );

__PACKAGE__->meta->make_immutable;

sub init_test_var{ return \1; }

1;
