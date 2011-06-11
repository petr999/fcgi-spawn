package FCGI::Spawn::Tests::TestUtils;

use Moose;
use MooseX::FollowPBP;

use Test::More;

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'TestUtils functionality', ), );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self = shift;
    my ( $pid, $util, $timeout );
    my @tests = (
        sub { use_ok( 'FCGI::Spawn::BinUtils', ); },
        sub { use_ok( 'FCGI::Spawn::TestUtils', ); },
        sub {
            is( get_fork_rv( sub { return 3; } ) => 3,
                'Get value from fork()'
            );
        },
        sub {
            ok( $util = FCGI::Spawn::TestUtils->new,
                => 'TestUtils constructor' );
        },
        sub {
            ok( $timeout = $util->get_timeout => 'Get timeout from utils', );
        },
        sub {
            cmp_ok(
                $pid = get_fork_pid( sub { sleep $timeout; }, ),
                '>', 0, 'Get PID from fork()',
            );
        },
        sub { ok( kill_proc_dead($pid) => 'Process killer', ); },
    );
    my $rv = 1;
    foreach my $test (@tests) {
        last unless $rv;
        $rv = &$test;
    }
    return $rv;
}

1;
