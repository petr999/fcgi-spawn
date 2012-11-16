#!perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2012 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use Test::More;
eval 'use Test::CPAN::Changes';
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
changes_ok();
done_testing();
