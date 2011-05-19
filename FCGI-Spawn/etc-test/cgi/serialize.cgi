#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use CGI;

print "Content-type: text/json\n\n"
  , encode_json( CGI->new->Vars ),
;
