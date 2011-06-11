#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Digest::MD5 'md5_base64';

my %old_env = %ENV;

my %rand_env = ();
foreach( 0..9 ){
  my $seed = md5_base64 rand( 4294967295 );
  my $key_seed = md5_base64 rand( 4294967295 );
  $key_seed =~ s/[^\w]//g;
  $key_seed = uc( $key_seed );
  $rand_env{ $key_seed } = $seed;
}

%ENV = ( %rand_env => %ENV, );

print "Content-type: text/json\n\n"
  , encode_json( \%old_env ),
;
