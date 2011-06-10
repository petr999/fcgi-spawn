#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

# Define metadata
name('Apache-Fake');
all_from('lib/Apache/Fake.pm');

# Dependencies
requires( 'Sub::Alias'   => '0' );
requires( 'Sub::Name'    => '0' );
requires( 'Carp'         => '0' );
requires( 'CGI'          => '0' );
requires( 'HTTP::Date'   => '0' );
requires( 'HTTP::Status' => '0' );
requires( 'IO::Handle'   => '0' );
requires( 'CGI::Cookie'  => '0' );

# Test dependencies
test_requires( 'Test::More'           => '0' );
test_requires( 'JSON'                 => '0' );
test_requires( 'IPC::Open3'           => '0' );
test_requires( 'Perl6::Export::Attrs' => '0' );

recommends( 'JSON::XS' => '0' );

WriteAll();
