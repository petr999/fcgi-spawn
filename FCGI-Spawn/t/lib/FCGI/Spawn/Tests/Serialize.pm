package FCGI::Spawn::Tests::Serialize;

use Moose;
use MooseX::FollowPBP;

use URI::Escape;
use Digest::MD5 'md5_base64';

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+env' => ( qw/lazy 1/, ), );
has( '+descr' => ( 'default' => 'Serialization', ), );

__PACKAGE__->meta->make_immutable;

sub make_env {
    my $self    = shift;
    my $env     = $self->SUPER::make_env();
    my $seeding = $self->make_test_seq;
    $$env{ 'QUERY_STRING' } = $$seeding;
    return $env;
}

sub make_test_seq {
    my $self    = shift;
    my @seeding = %{ $self->get_test_var };
    return \( join( "=", map { uri_escape($_) } @seeding, ) );
}

sub init_test_var {
    my $self     = shift;
    my $rand_max = $self->get_rand_max;
    my $b64_key  = md5_base64( rand $rand_max );
    my $b64_val  = md5_base64( rand $rand_max );
    my $seeding  = { $b64_key => $b64_val, };
    return $seeding;
}

1;
