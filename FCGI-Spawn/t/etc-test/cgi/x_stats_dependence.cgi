#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

use JSON;

use XStats;

my $fn = 'x_stats_dependence.tmpl';
set_fn( $fn );
my $arr = FCGI::Spawn::xinc( [ 'xsd_changeable.tmpl' => $fn, ], \&make_tref );
print "Content-type: text/json\n\n".encode_json( $arr );

no warnings 'redefine';

