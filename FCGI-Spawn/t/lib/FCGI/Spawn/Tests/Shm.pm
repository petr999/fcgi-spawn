package FCGI::Spawn::Tests::Shm;

use Moose;
use MooseX::FollowPBP;

use English;
use Test::More;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests', );

has( qw/timeout   is ro isa Int required 1 default 5/, );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self = shift;
    my ( $shared => $ipc, );
    my $timeout = $self->get_timeout;
    share_var( \$shared => \$ipc, );
    $shared = 321;
    my $pid = fork;
    if ( defined $pid ) {
        if ($pid) {
            sleep $timeout;
            is( $shared => 123, 'Share variable between forks' );
        }
        else {
            $shared = 123 if $shared == 321;
            exit;
        }
    }
    else {
        die "Cannot fork: $@ $!";
    }
}

1;
