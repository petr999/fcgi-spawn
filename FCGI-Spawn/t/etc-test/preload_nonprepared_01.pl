#!/usr/bin/env perl
use strict;

our ( $TEST_VAR_00 => $TEST_VAR_01, );
map { ${ $main::{ $_ } } = $FCGI::Spawn::OURS->{ $_ }; }
    keys %$FCGI::Spawn::OURS;

package Test_Package;
sub itistest { return $TEST_VAR_00; }
