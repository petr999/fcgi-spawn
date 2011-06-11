package FCGI::Spawn::Tests::TimeLimitKill;

use Moose;
use MooseX::FollowPBP;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests::TimeLimit', );

has('+descr' => ( 'default' => 'Limit CGI execution time by a kill signal', ),
);
has( qw/timeout   is ro isa Int required 1 default 25/, );

__PACKAGE__->meta->make_immutable;

sub make_cgi_basename { return 'time_limit_term_ignore'; }

1;
