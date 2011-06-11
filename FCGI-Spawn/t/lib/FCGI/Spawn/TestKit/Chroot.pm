package FCGI::Spawn::TestKit::Chroot;

use Moose;
use MooseX::FollowPBP;

use English qw/$UID/;
use Test::More;

extends( 'FCGI::Spawn::TestKit::Spawnable', );

override( 'testify' => \&testify_if_root, );

__PACKAGE__->meta->make_immutable;

sub init_tests_list {
    my $self = shift;
    my $rv   = $self->SUPER::init_tests_list();
    push( @$rv => ( qw/shm/, ), );    # shm must croak if mm_permission fails
    return $rv;
}

sub testify_if_root {
    my $self = shift;
    if ($UID) {
        my $msg =
              "Your UID is $UID but Super user privileges are required to"
            . " test chroot and mm_permission features."
            . " These tests are presumably passed ;-)";
        diag($msg);
        ok( 1 => $msg, );
    }
    else {
        return super();
    }
}

1;
