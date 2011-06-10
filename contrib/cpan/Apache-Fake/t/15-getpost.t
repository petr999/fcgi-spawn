#!/usr/bin/env perl

=pod

This test tries to simulate a typical GET and POST environment and tests the
input in such a conditions

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::More::UTF8;

use IPC::Open3;
use JSON;
use Const::Fast;
use URI;
use URI::Escape;
use Digest::MD5 qw/md5_base64/;

use Apache::Fake::Test;

const( my $piped     => "t/piped/getpost.pl" );
const( my $rand_max  => 16_000_000 );
const( my %saved_env => %ENV );

# Make query string
my $uri = URI->new;
$uri->query_form( map( { md5_base64( rand($rand_max) ); } 0 .. 9 ) );
my $query = $uri->query;

# Test if GET gets
# Set environment
$ENV{ 'REQUEST_METHOD' } = 'GET';
$ENV{ 'QUERY_STRING' }   = $query;

# Read from piped
my ( $str => $str_err ) = passthru_open3($piped);
if ( length($str_err) ) { ok( 0 => "Error: $str_err" ); done_testing }
exit if length $str_err;

# Test if args() reads
my $arr = decode_json($str);
ok( $arr ~~ [$query], 'args() reads GET query string' );

%ENV = %saved_env;

# Test if POST posts
# Set environment
$ENV{ 'REQUEST_METHOD' } = 'POST';
$ENV{ 'CONTENT_LENGTH' } = length $query;
$ENV{ 'CONTENT_TYPE' }   = 'application/x-www-form-urlencoded';

# Pass through piped
( $str => $str_err ) = passthru_open3( $piped => $query );
if ( length($str_err) ) { ok( 0 => "Error: $str_err" ); done_testing }
exit if length $str_err;

# Test if read() reads
($str) = @{ decode_json($str) };
is( $str => $query, 'read() from the POST' );

%ENV = %saved_env;

done_testing;
