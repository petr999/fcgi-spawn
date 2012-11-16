#!/usr/bin/env perl
# Test modules loading
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
# use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Test strictures
use Test::Strict;

# Loads main app module
# use Your::Module;

# Catches exceptions
# use Try::Tiny;

### CONSTANTS ###
#
# Makes constants possible
# use Const::Fast;

# (Enter constant description here)
# const my $SOME_CONST => 1;

# Test for 'use warnings;', too
$Test::Strict::TEST_WARNINGS = 1;

### MAIN ###
# Require   :   Test::Strict
#
# Check loadability of the every module
all_perl_files_ok()

# Continues till this point
# done_testing();
