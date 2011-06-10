#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Cwd qw/realpath/;

use lib realpath( $FindBin::Bin.'/../../blib/lib' );

use JSON;

use Apache::Fake;

my $r = Apache2::RequestUtil->request;
my $out = '';
if( $ENV{ 'REQUEST_METHOD' } eq 'POST' ) {
    read(STDIN, $out, $ENV{ 'CONTENT_LENGTH' }); 
}
else { $out = $r->args;
}
print encode_json([ $out ]);
