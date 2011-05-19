package FCGI::Spawn::Tests::CleanIncSubNs;

use Moose;
use MooseX::FollowPBP;

use Carp;
use File::Basename qw/dirname/;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has( '+descr' => ( 'default' => 'specific package typeglobs reset', ) );

sub make_cgi{
  my( $self, $name ) = @_;
  my $env = $self -> get_env;
  my $cgi = $$env{ 'SCRIPT_FILENAME' };
  croak unless defined( $cgi ) and length( $cgi );
  my $cgi_dir = dirname( $cgi );
  my $cgi_contents = \<<EOT;
#!$^X

use strict;
use warnings;

use lib '$cgi_dir';

use CleanIncSubNs;

CleanIncSubNs::tell_name();

EOT
  $self -> write_file_contents( $cgi_contents => $cgi, );
  
  my $mod_fn = join '/', dirname( $cgi ), 'CleanIncSubNs.pm';
  my $mod_contents = \( join "\n",
    "#!$^X",
    "",
    "package CleanIncSubNs;",
    "",
    "use strict;",
    "use warnings;",
    "",
    "use JSON;",
    "",
    "no warnings 'redefine';",
    "",
    "our \$name = '$name';",
    "",
  );
  my $name_orig = $self ->get_cmp_vals -> [ 0 ];
  $$mod_contents .= ( join "\n",
    "sub tell_name{",
      'print "Content-type: text/plain\n\n".encode_json( [ "ITIS"',
      '.'
        .(
          ( $name eq $name_orig ) ?  '' : 'join "", reverse split //, '
        ).'"'
        .(  ( $name eq $name_orig ) ? $name
          : ( join '', reverse split //, $name )
        ).'", ]  );'
    ,'}',
    '',
    '1;',
  );
  $self -> write_file_contents( $mod_contents => $mod_fn, );
}

1;
