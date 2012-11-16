#!/usr/bin/env perl
# Tests BinUtils subroutines.
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

# Import better perlvars
use English qw/$EUID $UID $EGID $GID/;

# Requires root user
plan( 'skip_all' => "Current user id is $EUID. This test requires uid == 0", )
    if $EUID;

# Loads main app module
use_ok( 'FCGI::Spawn::BinUtils' );

# Handles exceptions
use Test::Exception;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# User id to switch to for tests
const my $TEST_USER_ID => $ENV{ 'TEST_USER_ID' } // 12345;

# Group id to switch to for tests
const my $TEST_GROUP_ID => $ENV{ 'TEST_GROUP_ID' } // 12345;

### MAIN ###
# Require   :   Test::Most, Test::Exception, English, FCGI::Spawn::BinUtils,
#               POSIX modules
#
# Catch exception
lives_and {

    # Set group id
    FCGI::Spawn::BinUtils::_set_group_id( $TEST_GROUP_ID );
    is( $GID => "$TEST_GROUP_ID $TEST_GROUP_ID", "Real group set to $TEST_GROUP_ID" );
    is( $EGID => "$TEST_GROUP_ID $TEST_GROUP_ID", "Effective group set to $TEST_GROUP_ID" );

    # Set user id
    FCGI::Spawn::BinUtils::_set_user_id( $TEST_USER_ID );
    is( $UID => $TEST_USER_ID, "Real user set to $TEST_USER_ID" );
    is( $EUID => $TEST_USER_ID, "Effective user set to $TEST_USER_ID" );

} 'Switch user id and group id';

# Continues till this point
done_testing();
