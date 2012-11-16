#!/usr/bin/env perl

# Test modules' strictness and warnity
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Loads module to test
use_ok( 'FCGI::Spawn::ConfigFile' );

### MAIN ###
# Require   :   Test::Most, FCGI::Spawn::ConfigFile
#
# Test if config file object creates
ok( my $conf = FCGI::Spawn::ConfigFile->new(), 'Config file object creation', );

# TODO put config file for tests
# Test reading configuration from file
# ok( $conf->read_fsp_config_file(), 'Config file reading', );

# Continues till this point
done_testing();
