#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client;

use Moose;
use MooseX::FollowPBP;

use FCGI::Client;
use JSON;
use Digest::MD5 'md5_base64';
use Test::More;
use Data::Dumper;

use FCGI::Spawn::TestUtils;

has( 'sock' => ( qw/is rw   isa IO::Socket/ ) );
has( 'conn' => ( qw/is rw   isa FCGI::Client::Connection/ ) );
has( 'util' => ( qw/is ro   required 1    isa/ => 'FCGI::Spawn::TestUtils', ) );
has( 'cgi_fname' => ( qw/is ro    required 1    isa Str   default/
  => \&make_cgi_fname, ) );
has( 'env' => ( qw/is ro    required 1    isa Ref
  default/ => \&make_env, ), );
has( 'content' => ( qw/is ro    required 1    isa Ref default/ => \&make_content, ) );
has( 'parser' => ( qw/is rw    required 1    isa CodeRef    default/
        => \&make_parser, ),
);
has( 'descr' => ( qw/is ro    required 1    isa Str   default GET/, ) );

my $debug = ( defined( $ENV{ 'DEBUG' } ) and $ENV{ 'DEBUG' } );

sub BUILD{
  my $self = shift;
  $self -> fc_connect;
}

sub make_cgi_fname{
  my @hier = split /::/, ref shift;
  lc( pop @hier, ) . '.cgi';
}

sub make_env{
  +{ qw/REQUEST_METHOD GET/ };
}

sub make_content{
  \'';
}

sub make_parser{
  return \&parsing;
}; 

sub parsing{
  my( $stdout, $seed ) = @_;
  $stdout =~ s/^.*[\r\n]([^\r\n]+)$/$1/ms;
  my $rv = ( $stdout = decode_json( $stdout ) )
    ?  ( %$stdout ~~ @$seed ) : 0;
  return $rv;
}

sub fc_connect{
  my $self = shift;
  $self -> make_sock;
  my( $sock, $util ) = ( $self -> get_sock,  $self -> get_util, );
  my $timeout = $util -> get_timeout;
  my $conn = FCGI::Client::Connection -> new( 'sock' => $sock, 'timeout' => $timeout, );
  die $! unless defined( $conn ) or not $conn;
  $self -> set_conn( $conn );
}

sub make_sock{
  my $self = shift;
  my $util = $self -> get_util;
  my $sock = $util -> sock_client;
  $self -> set_sock( $sock );
}

sub request{
  my $self = shift;
  my $cgi_fullname = join( '/',
    $self -> get_util -> get_cgi_dir => $self -> get_cgi_fname );
  my( $env, $content, $parser, $conn, ) = map{
    my $method = "get_$_"; $self -> $method;
  } qw/env content parser conn/;
  ( $content, my $seed ) = $content -> () if 'CODE' eq ref $content;
  ( $env, $seed ) = $env -> ( $content, $seed, ) if 'CODE' eq ref $env;
  $env = { %$env, 'SCRIPT_FILENAME'  => $cgi_fullname, };
  diag Dumper $env, $content if $debug;
  my( $stdout, $stderr ) = $conn -> request( $env, $$content );
  diag Dumper $stdout, $stderr if $debug;
  my $rv = $parser->( $stdout, $seed );
  $stderr = ( defined( $stderr ) ? $stderr : '' )
    . "\n" . $stdout unless $rv
  ;
  return( $rv => $stderr, );
}

sub make_seeding{
    my $seed = rand( 4294967295 );
    my $b64_seed = md5_base64 rand( 4294967295 );
    ( $b64_seed => $seed, );
}

1;
