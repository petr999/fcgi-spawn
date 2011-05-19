#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Serialize_Max_Requests;

use Moose;
use MooseX::FollowPBP;

use JSON;

extends( 'FCGI::Spawn::TestUtils::Client' );

has( '+parser' => ( 'default'  => \&init_store_pids, ), );

our @pids;

sub init_store_pids {
  \&store_pids;
}

sub store_pids{
  my $stdout = shift;
  $stdout =~ s/^.*[\r\n]([^\r\n]+)$/$1/ms;
  my( $pid ) = @{ decode_json( $stdout ) };
  push @pids, $pid unless grep { $_ == $pid } @pids;
  return \@pids;
}

augment( 'parse' => \&enparse, );

1;
