#!/usr/bin/env perl

use strict;
use warnings;

use CGI;
my $cgi = CGI -> new;
print "Content-type: text/plain\n\n"
  , ref( defined( $CGI::Q ) ? $CGI::Q : $cgi ),;
;
