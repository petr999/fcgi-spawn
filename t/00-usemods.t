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

### MAIN ###
# Require   :   Test::Most
#

# TODO Requires Apache::Fake unreleased yet
# require_ok 'FCGI::Spawn::ModPerl';

# Check loadability of the every module
use_ok $_
    foreach qw{FCGI::Spawn::BinUtils FCGI::Spawn::ConfigFile FCGI::Spawn};

# XXX With Apache::Fake dependency, make all_perl_files_ok() in next
# release, this includes FCGI::Spawn::ModPerl
foreach my $modname ( map( { s!::!/!g; "lib/$_.pm" }
        @{[ qw{FCGI::Spawn::BinUtils FCGI::Spawn::ConfigFile FCGI::Spawn} ]}
    ), 'bin/fcgi_spawn') {
    syntax_ok( $modname );
    strict_ok( $modname );
    warnings_ok( $modname );
}

# Continues till this point
done_testing();
