#!/usr/bin/env perl

use strict;
use warnings;

use JSON qw/-convert_blessed_universally/;

use Apache::Fake;

my $json = JSON->new->utf8;
$json->convert_blessed(1);
print $json->encode( Apache->request );
