#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Post::Serialize;

use Moose;
use MooseX::FollowPBP;

use URI::Escape;
use Sub::Name;

extends 'FCGI::Spawn::TestUtils::Client';

has( '+content' => ( 'default' => \&init_content, ), );
has( '+env' => ( 'default' => \&init_env, ), );

sub make_content{
  my $self = shift;
  my @seeding = $self -> make_seeding;
  return ( \join( "=", map{ uri_escape $_ } @seeding, ) => \@seeding, );
}

sub make_env{
  my( $content, $seed ) = @_;
  my $len = length( $$content );
  ( { qw/REQUEST_METHOD POST
          CONTENT_TYPE/ => 'application/x-www-form-urlencoded',
            qw/CONTENT_LENGTH/
      => $len, 'HTTP_CONTENT_LENGTH' => $len,
    } => $seed, );
}

sub init_env{
  \&make_env;
}

sub init_content{
  my $self = shift;
  return subname( ref( $self ).'_pre_make_content'
    => sub{ $self -> make_content( @_ ); }, );
}

1;
