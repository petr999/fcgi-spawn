#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::More::UTF8;

use IPC::Open3;
use JSON;
use Const::Fast;

use Apache::Fake;

my( $write, $read, $err );
die( "Can not open pipe: $!" )
    unless open3( $write, $read, $err, "$^X t/piped/form_input.cgi" );
my $str = '';
while( my $buf = <$read>){ $str .= $buf; }

my $hash = decode_json( $str );
ok( defined( $$hash{ 'NOTES' } ) => 'Apache->request' );

done_testing;
