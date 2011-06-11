package FCGI::Spawn::Tests::StatsMod;

use Moose;
use MooseX::FollowPBP;

use Carp;
use File::Basename qw/dirname/;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has('+descr' => (
        'default' =>
            'Used module change lead to CGI script file output change',
    )
);

__PACKAGE__->meta->make_immutable;

sub make_cgi {
    my ( $self, $name ) = @_;
    my $env = $self->get_env;
    my $cgi = $$env{ 'SCRIPT_FILENAME' };
    croak unless defined($cgi) and length($cgi);
    my $cgi_dir      = dirname($cgi);
    my $cgi_contents = \<<EOT;
#!$^X

use strict;
use warnings;

use lib '$cgi_dir';

use StatsMod;

StatsMod::tell_name();

EOT
    $self->write_file_contents( $cgi_contents => $cgi, );

    my $mod_fn = join '/', dirname($cgi), 'StatsMod.pm';
    my $mod_contents = \<<EOM;
#!$^X

package StatsMod;

use strict;
use warnings;

use JSON;

no warnings 'redefine';

sub tell_name{
  print "Content-type: text/plain\n\n".encode_json( [ "ITIS$name" ] );
}

1;
EOM
    $self->write_file_contents( $mod_contents => $mod_fn, );
}

1;
