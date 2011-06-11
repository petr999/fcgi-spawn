package FCGI::Spawn::Tests::Socket;

use Moose;
use MooseX::FollowPBP;

use Test::More;

use FCGI::Spawn::TestUtils;
use FCGI::Spawn::BinUtils ':testutils';

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'Spawn from module and listen for socket', ),
);
has( qw/timeout is ro isa Int required 1 default 10/, );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self = shift;
    my ( $spawn => $spawn_pid, );
    my $timeout = $self->get_timeout;
    my @tests   = (
        sub { use_ok( 'FCGI', ); },
        sub { use_ok( 'FCGI::Spawn', ); },
        sub {
            ok( $spawn = FCGI::Spawn->new(
                    {   'sock_name' =>
                            FCGI::Spawn::TestUtils->new->get_sock_name,
                    }
                    ) => 'Spawner initialisation',
            );
        },
        sub {
            ok( $spawn_pid =
                    get_fork_pid( sub { $spawn->spawn; }, ) => 'Spawning' );
        },
        sub { sleep $timeout; },
        sub {
            ok( not( is_process_dead( $spawn_pid, ), ) =>
                    'Spawn is listening', );
            my $sock_name = $$spawn{ 'sock_name' };
            ok( not( sock_try_serv( $sock_name, ) ) => 'Socket was binded' );
            ok( kill_proc_dead( $spawn_pid, ) => 'finding if spawn ended', );
        },
    );
    my $rv = 1;
    foreach my $test (@tests) {
        last unless $rv;
        $rv = &$test;
    }
    return $rv;
}

1;
