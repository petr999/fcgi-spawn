#!/usr/bin/perl

use strict;
use warnings;

use English;
use JSON;

print "Content-type: text/json\n\n"
  , encode_json( [ $PID ] ),
;
