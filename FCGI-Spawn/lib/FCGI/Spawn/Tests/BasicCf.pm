package FCGI::Spawn::Tests::BasicCf;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+descr' => ( 'default' => 'Basic CGI', ), );
has( '+is_response_json' => ( qw/default 0/, ), );

__PACKAGE__->meta->make_immutable;

sub init_test_var{ \'CGI::Fast'; }

1;
