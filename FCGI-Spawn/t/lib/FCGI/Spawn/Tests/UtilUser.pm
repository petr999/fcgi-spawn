package FCGI::Spawn::Tests::UtilUser;

use Moose;
use MooseX::FollowPBP;

use Test::More;

extends('FCGI::Spawn::Tests');
has( '+mandatory' => ( qw/default 1/, ), );

augment( 'check_out' => \&check, );

__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self  = shift;
    my $util  = $self->get_util;
    my $user  = $util->get_user;
    my $descr = "System user $user is necessary to exist for this test";
    $self->set_descr($descr);
}

sub check {
    my $self  = shift;
    my $descr = $self->get_descr;
    my $util  = $self->get_util;
    my $user  = $util->get_user;
    my $rv    = 0;
    my $uid   = getpwnam($user);
    $rv = cmp_ok( $uid, '>', 0, $descr );
    return $rv;
}

1;
