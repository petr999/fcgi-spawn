#!/usr/bin/env perl

# This test tries to create the typical request object and reads its attribute(s)

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::More::UTF8;

use IPC::Open3;
use JSON;
use Const::Fast;
use IO::Select;
use Symbol 'gensym';

use Apache::Fake::Test;

const( my $piped => "t/piped/form_input.pl" );

# Execute a command
my ( $str => $str_err ) = passthru_open3($piped);
if ( length($str_err) ) { ok( 0 => "Error: $str_err" ); done_testing }
exit if length $str_err;

# Read the command's output
my $hash;
eval { $hash = decode_json($str); 1; };
ok( defined( $$hash{ 'NOTES' } ) =>
        'Apache->request gives a hash with notes' );

done_testing;
