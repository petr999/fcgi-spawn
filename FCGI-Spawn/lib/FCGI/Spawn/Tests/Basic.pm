package FCGI::Spawn::Tests::Basic;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+descr' => ( 'default' => 'Basic CGI', ), );
has( '+is_response_json' => ( qw/default 0/, ), );

sub init_test_var{ \'CGI'; }

1;
