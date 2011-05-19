package FCGI::Spawn::Tests::Cgi;

use Moose;
use MooseX::FollowPBP;

use Carp;
use FCGI::Client;
use IO::Socket;
use Test::More;
use JSON;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests' );

has( 'env' => ( qw/is ro    isa HashRef   required 1 lazy 1 builder make_env/ ) );
has( 'content' => ( qw/is ro    isa ScalarRef   required 1 lazy 1 builder make_content/, ) );
has( qw/is_response_json    is ro isa Int default 1/, );

sub make_env{
  my $self = shift;
  # env is lazy cause util is needed here and to reini
  my $cgi = $self -> make_cgi_name;
  my $env = { 'SCRIPT_FILENAME' => $cgi, qw/REQUEST_METHOD GET/, };
  return $env;
}

sub make_content{
 return \'';
}

sub make_cgi_name{
  my $self = shift;
  my $name = $self -> init_name;
  my $util = $self -> get_util;
  my $cgi_dir = $util -> get_cgi_dir;
  my $cgi = "$cgi_dir/$name.cgi";
  return $cgi;
}

sub check{
  my $self = shift;
  my( $out => $err, ) = $self -> request;
  my $rv = $self -> parse( $out, $err );
  my $descr = $self -> get_descr;
  unless( $rv ){ $descr .= ": $$err"; }
  ok( $rv => $descr, );
  return ( $rv => $err, );
}

sub request{
  my $self = shift;
  my $conn = $self -> cli_conn;
  my( $env, $content ) = ( $self -> get_env, $self -> get_content );
  $content = $content -> ( $self, ) if 'CODE' eq ref $content;
  $env = $env -> ( $self, ) if 'CODE' eq ref $env;
  my( $stdout => $stderr, ) = $conn -> request( $env, $$content );
  ( \$stdout => \$stderr, );
}

sub cli_conn{
  my $self = shift;
  my $util = $self -> get_util;
  my $sock = $self -> make_sock;
  my $timeout = $util -> get_timeout;
  my $conn = FCGI::Client::Connection -> new( 'sock' => $sock, 'timeout' => $timeout, );
  croak $! unless defined( $conn ) or not $conn;
  return $conn;
}

sub make_sock{
  my $self = shift;
  my $util = $self -> get_util;
  my $sock = $util -> sock_client;
}


sub parse{
  my( $self, ( $out => $err ), ) = @_;
  croak( "Parse error: $$err", ) if defined( $$err ) and length( $$err );
  croak( "No HTTP header in stdout: $$out" )
    unless $$out =~ s/^([^\r\n]+\r?\n\r?)+\r?\n\r?(.*)$/$2/ms;
  unless( defined $$err ){ $$err = ''; }
  if( $self -> get_is_response_json ){ $out = decode_json( $$out ); }
  my $rv = $self -> enparse( $out => $err, );
  unless( defined $rv ){ $rv = 1; }
  return $rv;
}

1;
