package FCGI::Spawn::TestKit::Spawnable;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Test::More;
use Try::Tiny;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestKit::Utilized', );

augment( 'testify' => \&unspawn_if_pid, );

has( qw/push_tests is ro isa ArrayRef[Str] required 1 default/ => sub { []; },
);
has( qw/self_skip is ro isa Bool required 1 default 0/, );

__PACKAGE__->meta->make_immutable;

sub init_tests_list {
    my $self       = shift;
    my $name       = $self->get_name;
    my $self_skip  = $self->get_self_skip;
    my $push_tests = $self->get_push_tests;
    my $rv         = [ 'spawn', ];
    unless ($self_skip) { push( @$rv => $name, ); }
    push( @$rv => @$push_tests, );
    return $rv;
}

sub spawn {
    my $self = shift;
    my $name = $self->get_name;
    my $util = $self->get_util;
    my $rv   = 0;
    ok( my $ppid =
            get_fork_pid( $util->spawn_fcgi ) =>
            "Spawner initialisation named '$name'" );
    if (ok( ( my $pid = $util->read_pidfile($ppid) ) =>
                "FCGI Spawned: pid $ppid",
        )
        )
    {
        $util->set_pid($pid);
        $rv = 1;
    }
    return ( $rv => not $rv, );
}

sub unspawn {
    my $self = shift;
    my $util = $self->get_util or croak( "No Fcgi Spawned to unspawn!", );
    my $rv   = 0;
    my $pid  = $util->get_pid or croak( "No Fcgi PID spawned!", );
    ok( $rv = $self->stop_serv => 'Stopping spawn', )
        or croak("Can not stop pid: $pid");
    $util->set_pid(0);
    return ( $rv => not $rv, );
}

sub unspawn_if_pid {
    my $self = shift;
    my $meta = $self->meta;
    if ( defined $meta->find_attribute_by_name('util') ) {
        my $util = $self->get_util;
        if ( defined($util) ) {
            my $pid = $util->get_pid;
            if ( defined($pid) and $pid > 0 ) {
                try {
                    $self->unspawn;
                }
                catch {
                    diag( "No unspawn: $_", );
                }
            }
        }
    }
}

sub stop_serv {
    my $self = shift;
    my $util = $self->get_util;
    my $pid  = $util->get_pid;
    $util->kill_procsock;
}

1;
