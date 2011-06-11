#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

print "Content-type: text/json\n\n"
  , encode_json( [ Test_Package::itistest() ] ),
;
