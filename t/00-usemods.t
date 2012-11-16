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
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

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

### MAIN ###
# Require   :   Test::Most
#

# TODO Requires Apache::Fake unreleased yet
# require_ok 'FCGI::Spawn::ModPerl';

# Check loadability of the every module
use_ok $_
    foreach qw{FCGI::Spawn::BinUtils FCGI::Spawn::ConfigFile FCGI::Spawn};

# Continues till this point
done_testing();
