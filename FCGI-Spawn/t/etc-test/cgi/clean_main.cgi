#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use CGI;

my $cgi = CGI -> new;
my $old = $cgi->param( 'old' );
my $output = {};
foreach my $key( @$old ){
  my $is_defined = eval( 'defined $'.$key.';' );
  die $@ if $@;
  if( $is_defined ){
    eval( '$$output{ '.$key.' } = $'.$key.';' );
    die $@ if $@;
  }
}
my $new = $cgi->param( 'new' );
foreach my $key( keys %$new ){
  my $val = $$new{ $key };
  eval( 'our $'.$key." = '$val';" );
  die $@ if $@;
}
print "Content-type: text/json\n\n"
  , encode_json( $output )
  ,
;
