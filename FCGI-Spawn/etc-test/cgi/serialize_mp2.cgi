#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use CGI;

print "Content-type: text/json\n\n";
my $r = Apache2::RequestUtil->request;
my %r_hash = map{ $_ => $r->param( $_ ), } $r->param;
print encode_json( \%r_hash );
;
