#!/usr/bin/env perl

use strict;
use warnings;

{
  local $SIG{ 'INT' } = 'IGNORE';
  local $SIG{ 'TERM' } = 'IGNORE';
  sleep 20;
}
print "Content-type: text/json\n\n1";
