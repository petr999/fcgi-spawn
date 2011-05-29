package FCGI::Spawn::Tests::TimeLimitParallel;

use Moose;
use MooseX::FollowPBP;

use Parallel::ForkManager;

extends( 'FCGI::Spawn::Tests::TimeLimit', );

has( '+descr' => ( 'default' => 'Limit CGI execution time in several processes', ), );

with( 'FCGI::Spawn::Tests::WaiterParallel', );

__PACKAGE__->meta->make_immutable;

sub make_cgi_basename{ return 'time_limit'; }

1;
