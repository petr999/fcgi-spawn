package FCGI::Spawn::Tests::MaxRequests;

use Moose;
use MooseX::FollowPBP;

use JSON;
use Sub::Name;
use Const::Fast;

extends( 'FCGI::Spawn::Tests::Multiple', );

const( my $trials => 205, );

has( '+trials' => ( 'default' => $trials, ), );
has( qw/try_number    is rw isa Int/, );
has( qw/max_try_number    is ro isa Int default/ => $trials - 1, );
has( qw/pids  is rw isa ArrayRef[Int]   default/ =>
        subname( 'init_pids' => sub { []; }, ), );
has( qw/max_pids    is ro isa Int default 10/, );
has('+descr' => (
        'default' => 'Max requests were reached, new processes were started',
    )
);

override( 'request' => \&pick_try_number, );

__PACKAGE__->meta->make_immutable;

sub pick_try_number {
    my ( $self => $tn, ) = @_;
    $self->set_try_number( $tn, );
    super();
}

sub enparse {
    my ( $self, ( $out => $err ), ) = @_;
    my $rv = my $pid = pop @$out;
    my @pids = ( @{ $self->get_pids } );
    unless ( grep { $_ == $pid } @pids ) {
        push @pids, $pid;
        $self->set_pids( [@pids] );
    }
    my ( $try_number => $max_try_number, ) =
        ( $self->get_try_number => $self->get_max_try_number, );
    if ( $try_number == $max_try_number ) {
        my $max_pids = $self->get_max_pids;
        $rv = ( @pids < $try_number ) && ( @pids >= $max_pids );
    }
    return $rv;
}

1;
