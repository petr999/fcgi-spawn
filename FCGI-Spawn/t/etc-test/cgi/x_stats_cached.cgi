#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp;
use JSON;

eval( 'make_aref; 1;' ) or eval( 'sub make_aref{ [ "ITISORIG", ]; } 1;' ) or die "$@ $!";

my $arr;
eval( '$arr = FCGI::Spawn::xinc( __FILE__ => \&make_aref, ); 1; ', ) or die "$@ $!";
print "Content-type: text/json\n\n", encode_json( $arr );
 
no warnings 'redefine';
eval( 'sub make_aref{ [ "ITISCHNG", ]; } 1;' ) or die "$@ $!";
use warnings;

1;
