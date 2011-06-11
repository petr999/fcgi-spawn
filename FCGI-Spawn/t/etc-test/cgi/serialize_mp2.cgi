#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use CGI;
use URI::Escape;

unless( eval( "use Apache2::RequestUtil; 1;" ) ) {
    die( $@ ) unless eval( "use Apache::Fake; 1;" );
}
die( $@ ) unless eval( "use Apache2::RequestUtil;
        use Apache2::RequestIO;
        1;"
    );

my $r = Apache2::RequestUtil->request;

# Get query string
my $query_string = '';
if( $ENV{ 'REQUEST_METHOD' } eq 'POST' ) {
    my $len = $ENV{ 'CONTENT_LENGTH' };
    $r->read( $query_string => $len );
}
else { $query_string = $ENV{ 'QUERY_STRING' };
}

# Get request hash
my @pairs = split /[&;]/, $query_string;
my %r_hash = map{ uri_unescape( $_ ) } map{ split '=', $_, 2 } @pairs;

print "Content-type: text/json\n\n";
print encode_json( \%r_hash );
