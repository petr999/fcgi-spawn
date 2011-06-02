#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use CGI;
use FCGI::Spawn;

print "Content-type: text/json\n\n"
  , encode_json( FCGI::Spawn -> fcgi -> Vars ),
;
