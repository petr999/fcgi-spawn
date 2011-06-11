package FCGI::Spawn::Tests::TimeLimitKillParallel;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::TimeLimitKill', );
with( 'FCGI::Spawn::Tests::WaiterParallel', );

has('+descr' => (
        'default' => 'Limit CGI execution time by a kill signal in parallel',
    ),
);

__PACKAGE__->meta->make_immutable;

1;
