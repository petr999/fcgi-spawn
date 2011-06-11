package FCGI::Spawn::Tests::Fixed;

use Moose;
use MooseX::FollowPBP;

use Data::Dumper qw/Dumper/;

extends('FCGI::Spawn::Tests::Cgi');

has(qw/test_var    is ro isa Ref lazy 1  required 1 builder init_test_var/);

__PACKAGE__->meta->make_immutable;

sub enparse {
    my ( $self => ( $out => $err, ), ) = @_;
    my $test_var = $self->get_test_var;
    if ( 'SCALAR' eq ref $out ) { $out = $$out;   $test_var = $$test_var; }
    if ( 'HASH'   eq ref $out ) { $out = [%$out]; $test_var = [%$test_var]; }
    my $rv = $out ~~ $test_var;
    unless ($rv) {
        my $failure = "OUT: " . Dumper($out) . "TVAR: " . Dumper($test_var);
        $self->set_failure($failure);
    }
    return $rv;
}

1;
