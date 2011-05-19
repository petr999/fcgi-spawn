#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Serialize;

use Moose;
use MooseX::FollowPBP;

use URI::Escape;
use Sub::Name;

extends 'FCGI::Spawn::TestUtils::Client';

has '+env' => ( 'default'  => \&init_env );

sub make_env{
  my $self = shift;
  my @seeding = $self -> make_seeding;
  ( { qw/REQUEST_METHOD GET   QUERY_STRING/
      => join( "=", map{ uri_escape( $_ ) } @seeding, ),
    } =>  \@seeding, 
  );
}

sub init_env{
  my $self = shift;
  subname( ref( $self )."::pre_make_env"
    => sub{ $self -> make_env( @_ ); },
  );
}

1;
