#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Serialize_Callout;

use Moose;
use MooseX::FollowPBP;

use JSON;
use Const::Fast;

extends( 'FCGI::Spawn::TestUtils::Client' );

has( '+parser' => ( 'default'  => \&init_callout_test, ), );

const( my @testout => qw/it is test/, );

sub init_callout_test {
  \&callout_test;
}

sub callout_test{
  my $stdout = shift;
  $stdout =~ s/^.*[\r\n]([^\r\n]+)$/$1/ms;
  my $out = decode_json( $stdout );
  return @$out ~~ @testout;
}

1;
