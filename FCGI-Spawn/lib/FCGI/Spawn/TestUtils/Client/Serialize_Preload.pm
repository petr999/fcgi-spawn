#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Serialize_Preload;

use Moose;
use MooseX::FollowPBP;

use JSON;

extends( 'FCGI::Spawn::TestUtils::Client' );

has( '+parser' => ( 'default'  => \&init_preload_test, ), );

our @pids;

sub init_preload_test {
  \&preload_test;
}

sub preload_test{
  my $stdout = shift;
  $stdout =~ s/^.*[\r\n]([^\r\n]+)$/$1/ms;
  my( $scalar ) = @{ decode_json( $stdout ) };
  return $scalar eq 'ITISTEST';
}

1;
