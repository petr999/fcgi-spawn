package FCGI::Spawn::Tests::Multiple;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use Carp;

extends('FCGI::Spawn::Tests::Cgi');

has( qw/trials    is ro   isa Int   required 1    default 20/, );
has( qw/inverted  is ro   isa Bool  default 0/, );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self   = shift;
    my $trials = $self->get_trials;
    my ( $rv, $err );
    for ( my $i = 0; $i < $trials; $i++ ) {
        ( my $out => $err ) = $self->request($i);
        $rv = $self->parse( $out, $err );
        my $failure = $self->get_failure;
        if ( defined $failure ) {
            unless ( defined $err ) { $err = \''; }
            $$err .= " $failure";
        }
        last unless $rv;
    }
    my $descr = $self->get_descr;
    if ( $self->get_inverted ) { $rv = not $rv; }
    unless ($rv) { $descr .= ": $$err"; }
    ok( $rv => $descr, );
    return $rv;
}

1;
