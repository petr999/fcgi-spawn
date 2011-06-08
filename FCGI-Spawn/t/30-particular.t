#!/usr/bin/perl -w

use strict;
use warnings;

use lib 't/lib';

use FCGI::Spawn::TestKit;

FCGI::Spawn::TestKit::perform( 
  qw/cgi_fast mod_perl mod_perl_handlers cgi_fast_mod_perl clean_main call_out clean_inc_sub_ns/,
);
