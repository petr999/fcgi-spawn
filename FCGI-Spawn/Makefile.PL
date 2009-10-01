# -*- perl -*-
# Copyright (c) 2000, FundsXpress Financial Network, Inc.
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

# $Id: Makefile.PL,v 1.2 2000/11/10 01:09:41 muaddib Exp $

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'FCGI::Spawn',
   VERSION_FROM => 'Spawn.pm',   # finds $VERSION
   DISTNAME     => 'FCGI-Spawn',
   ($] >= 5.005 ?
    (	ABSTRACT  => 'A perl-based FastCGI process manager, convinient for admins and users',
     	AUTHOR    => 'Peter V. Vereshagin (peter@vereshagin.org)') : (),
		),
   	dist        => { COMPRESS => 'gzip', SUFFIX => 'gz', },
		PREREQ_PRINT	=>	1,
		PREREQ_PM		=> {	'FCGI::ProcManager'	=>	0, },
  );
