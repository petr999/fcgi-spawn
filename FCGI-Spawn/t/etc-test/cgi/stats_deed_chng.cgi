#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

print "Content-type: text/plain\n\n".encode_json( [ "ITISCHNG" ] );
