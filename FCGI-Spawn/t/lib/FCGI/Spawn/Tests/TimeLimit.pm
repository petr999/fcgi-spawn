package FCGI::Spawn::Tests::TimeLimit;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use Const::Fast;
use Try::Tiny;

use FCGI::Spawn::TestUtils;
use FCGI::Spawn::BinUtils qw/:testutils/;

extends( 'FCGI::Spawn::Tests::Cgi', );

has( '+descr' => ( 'default' => 'Limit CGI execution time', ), );
has( qw/timeout   is ro isa Int required 1 default 15/, );
has( qw/time_min   is ro isa Int required 1 default 5/, );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self    = shift;
    my $timeout = $self->get_timeout;
    my $rv;
    croak("Forking waiter: $!") unless defined( my $pid = fork );
    if ($pid) {
        my $i = 0;
        foreach ( 1 .. $timeout ) {
            $i++;
            sleep 1;
            $rv = is_process_dead($pid);
            last if $rv;
        }
        unless ($rv) { kill_proc_dead($pid); }
        if ( $i > $self->get_time_min ) {
            $self->on_time_out( $rv => $pid, );
        }
        else {
            $rv = 0;
            $self->set_failure("Ended before minimal time");
        }
    }
    else {
        $self->waiter;
        CORE::exit();
    }
    my $descr   = $self->get_descr;
    my $failure = $self->get_failure;
    unless ( defined $failure ) { $failure = ''; }
    unless ($rv) { $descr .= ": $failure"; }
    ok( $rv => $descr, );
    return $rv;
}

sub waiter {
    my $self = shift;
    try { my ( $out => $err, ) = $self->request; };
}

sub on_time_out {
    my ( $self, $died => $pid, ) = @_;
    unless ($died) {
        $self->set_failure( "Process was not dead: $pid", );
    }
}

1;
