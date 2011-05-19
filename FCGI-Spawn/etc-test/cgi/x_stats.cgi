#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use JSON;

use XStats;

my $fn = 'x_stats.tmpl';
set_fn( $fn );
my $arr = FCGI::Spawn::xinc( $fn, \&make_sref );
print "Content-type: text/json\n\n".encode_json( $arr );

