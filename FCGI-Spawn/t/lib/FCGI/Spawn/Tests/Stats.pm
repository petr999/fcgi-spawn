package FCGI::Spawn::Tests::Stats;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has( '+descr' =>
        ( 'default' => 'CGI script file change lead to output change', ) );

augment( 'enparse' => \&change_cgi, );

__PACKAGE__->meta->make_immutable;

sub make_cgi {
    my ( $self, $name ) = @_;
    my $env = $self->get_env;
    my $cgi = $$env{ 'SCRIPT_FILENAME' };
    croak unless defined($cgi) and length($cgi);
    my $cgi_contents = \<<EOT;
#!/usr/bin/perl

use strict;
use warnings;

use JSON;

print "Content-type: text/plain\n\n".encode_json( [ "ITIS$name" ] );
EOT
    $self->write_file_contents( $cgi_contents => $cgi, );
}

1;
