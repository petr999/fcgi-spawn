#!/usr/bin/perl -w
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
use Test::Strict;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Makes Test::Strict to test for 'use warnings', too
const $Test::Strict::TEST_WARNINGS => 1;

### MAIN ###
# Require   :   Test::Strict
#
all_perl_files_ok(qw/lib t/);    # finlalizes the plan
