package FCGI::Spawn::Tests::StatsCisns;

use Moose;
use MooseX::FollowPBP;

use Carp;
use File::Basename qw/dirname/;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has('+descr' => (
        'default' =>
            'specific package typeglobs reset with config re-reading',
    )
);

__PACKAGE__->meta->make_immutable;

sub make_cgi {
    my ( $self, $name ) = @_;
    my $env = $self->get_env;
    my $cgi = $$env{ 'SCRIPT_FILENAME' };
    croak unless ( defined($cgi) and length($cgi) );
    my $cgi_dir      = dirname($cgi);
    my $cgi_contents = \<<EOT;
#!/usr/bin/env perl

use strict;
use warnings;

use lib '$cgi_dir';

use StatsCisns;

StatsCisns::tell_name();

EOT
    $self->write_file_contents( $cgi_contents => $cgi, );

    my $cfg_fn = join( '/', $cgi_dir => 'stats_cisns.cfg', );
    my $mod_fn = join( '/', $cgi_dir => 'StatsCisns.pm', );
    my $mod_contents = \(
        join "\n",
        "#!$^X",
        "",
        "package StatsCisns;",
        "",
        "use strict;",
        "use warnings;",
        "",
        "use JSON;",
        "use File::Slurp;",
        "",
        "no warnings 'redefine';",
        "",
        "our \$name = [];",
        "",
        "sub tell_name{",
        "unless( @\$name > 0 ){ \$name = [ read_file( '$cfg_fn', ), ]; }",
        'print "Content-type: text/plain\n\n".encode_json( $name, );',
        '}',
        '',
        '1;',
    );
    $self->write_file_contents( $mod_contents => $mod_fn, );
    my $cfg_contents = \"ITIS$name";
    $self->write_file_contents( $cfg_contents => $cfg_fn, );
}

1;
