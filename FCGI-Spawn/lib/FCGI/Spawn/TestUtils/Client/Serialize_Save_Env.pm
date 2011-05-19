#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Serialize_Save_Env;

use Moose;
use MooseX::FollowPBP;

use JSON;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestUtils::Client' );

has( '+parser' => ( 'default'  => \&init_check_serv_env, ), );

our %prev_env;

sub init_check_serv_env{
  \&check_serv_env;
}

sub check_serv_env{
  my $stdout = shift;
  $stdout =~ s/^.*[\r\n]([^\r\n]+)$/$1/ms;
  my $out_env = decode_json( $stdout );
  my $rv = 1;
  if( keys( %prev_env ) > 0 ){
    $rv = %$out_env ~~ %prev_env;
  }
  %prev_env = %$out_env;
  return $rv;
}

1;
