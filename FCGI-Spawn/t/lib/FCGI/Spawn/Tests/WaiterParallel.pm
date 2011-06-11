package FCGI::Spawn::Tests::WaiterParallel;

use Moose::Role;
use MooseX::FollowPBP;

use Parallel::ForkManager;

has( qw/n_processes   is ro isa Int required 1 default 5/, );

around( 'waiter' => \&parallelise, );

sub parallelise {
    my $orig        = shift;
    my $self        = shift;
    my $n_processes = $self->get_n_processes;
    my $pm          = Parallel::ForkManager->new($n_processes);
    foreach ( 1 .. $n_processes ) {
        my $pid = $pm->start and next;
        $self->$orig(@_);
        $pm->finish;
    }
    $pm->wait_all_children;
}

1;
