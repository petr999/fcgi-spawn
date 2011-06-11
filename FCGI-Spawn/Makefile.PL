#!/usr/bin/env perl
# Copyright (c) 2010,2011 Peter Vereshagin <peter@vereshagin.org>
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'FCGI::Spawn',
    VERSION_FROM => 'lib/FCGI/Spawn.pm',
    DISTNAME     => 'FCGI-Spawn',
    ABSTRACT => 'FastCGI server for CGI-like applications multiprocessing',
    AUTHOR   => 'Peter V. Vereshagin <peter@vereshagin.org>',
    PREREQ_PRINT => 1,
    EXE_FILES    => ['bin/fcgi_spawn'],
    PREREQ_PM    => { 'FCGI::ProcManager' => 0, },
);
