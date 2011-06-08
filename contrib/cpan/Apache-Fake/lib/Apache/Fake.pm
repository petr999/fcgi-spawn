#
#  Apache::Fake - fake a mod_perl environment
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
package Apache::Fake;
use strict;
use warnings;
require 5.6.0;

BEGIN {
  $Apache::Fake::VERSION = 0.10;
  foreach my $module( @{ [ qw% Apache2/Response Apache2/RequestRec
      Apache2/RequestUtil Apache2/RequestIO APR/Pool APR/Table
      Apache2/SizeLimit ModPerl/RegistryLoader ModPerl/Registry Apache2/Const
      ModPerl ModPerl/Util Apache/Cookie Apache2/Cookie APR/Request
      APR/Request/Apache2 Apache2/Request ModPerl/Const APR/Date Apache2/Upload
      Apache Apache/Constants Apache/Request Apache/Log Apache/Table mod_perl
      Apache/Status Apache2/ServerUtil
    % ] } ){ $INC{ "$module.pm" } = $INC{ 'Apache/Fake.pm' }; }
}

1;

package mod_perl;
use strict;
use warnings;
BEGIN {
  $mod_perl::VERSION = 1.27;
}

package Apache::Log;
use strict;
use warnings;

use constant 'EMERG' => 0; use constant 'ALERT' => 1; use constant 'CRIT' => 2;
use constant 'ERR' => 3; use constant 'WARNING' => 4; use constant 'NOTICE' => 5;
use constant 'INFO' => 6; use constant 'DEBUG' => 7;

package Apache::Server;
use strict;
use warnings;

our( $Starting => $ReStarting, ) = ( 0 => 0, );

sub new{
  my ($caller, $r) = @_;
  my $class = ref($caller) || $caller;
  return bless { 'request' => $r, }, $class;
}

sub server_admin{ return $_[ 0 ] ->{ 'request' }->{ 'ADMIN' }; }
sub server_hostname{ return $_[ 0 ] -> { 'request' } -> { 'HOST' }; }
sub port{ return $_[ 0 ] ->{ 'request' } -> { 'LOCAL_PORT' }; }
sub is_virtual{ return $_[ 0 ] -> { 'request' } -> { 'VIRTUAL' }; }
sub names{ return @{ $_[ 0 ] -> { 'request' } -> { 'ALIASES' } }; }
sub dir_config{ return ( shift ) -> { 'request' } -> dir_config( @_ ); }
sub warn{ return ( shift ) -> { 'request' } -> warn( @_ ); }
sub log_error{ return ( shift ) -> { 'request' } -> log_error( @_ ); }
sub uid{ return getuid(); }
sub gid{ return getgid(); }

sub loglevel{
  my ($self, $level) = @_;
  $$self{ 'LOG_LEVEL' } = $level if defined $level;
  $$self{ 'LOG_LEVEL' };
}

package Apache::Connection;
use strict;
use warnings;

use Socket;

sub new{
  my ( $caller => $r, ) = @_;
  my $class = ref( $caller ) || $caller;
  return bless( { request => $r, } => $class, );
}

sub remote_host{ $_[ 0 ]->{'request'}->{'REMOTE_HOST'}; }

sub remote_ip{
  my( $self => $val, ) = @_;
  if( defined $val ){
    $self  ->  { 'request' } -> { 'REMOTE_ADDR' } = $val;
    undef $self -> { 'request' } -> { 'REMOTE_HOST' };
  }
  $self -> { 'request' } -> { 'REMOTE_ADDR' };
}

sub local_addr{
  my $self = shift;
  pack_sockaddr_in( inet_aton( $self -> { 'request' } -> { 'LOCAL_ADDR' }, )
    => $self -> { 'request' } -> { 'LOCAL_PORT' }, );
}

sub remote_addr{
  my $self = shift;
  pack_sockaddr_in( inet_aton( $self -> { 'request' } -> { 'REMOTE_ADDR' }, )
    => $self -> { 'request' } -> { 'REMOTE_PORT' }, );
}

sub remote_logname{ $_[ 0 ] -> { 'request' } -> remote_logname(); }

sub user{
  my($self => $val, ) = @_;
  $self -> { 'request' } -> { 'USER' } = $val if defined $val;
  $self -> { 'request' } -> { 'USER' };
}

sub auth_type{ $_[ 0 ] -> {'request' } -> { 'AUTH_TYPE' }; }

sub fileno{
  my ( $self => $dir, ) = @_;
  my $rv = ( defined( $dir ) && !$dir) ? 'FD_IN' : 'FD_OUT';
  $rv = $self->{ 'request' }->{ $rv };
  return $rv;
}

package Apache::Table;
use strict;
use warnings;

sub new{
  my $caller = shift;
  if( @_ > 0 ){ if( @_ % 2 ){ if( not defined $_ [ 0 ] ){ $_[ 0 ] = ''; }
      push @_, undef; }
  }
  my %content = @_; my $class = ref($caller) || $caller;
  my $rv;
  if( 'HASH' eq ref $_[0] ){ $rv = bless( $_[0], $class ); }
  else { $rv = bless {%content}, $class; }
}

sub set{
  my $self = shift;
  $self->{ shift } = shift;
}

sub get{
  my( $self => $key, ) = @_;
  my $rv = $$self{ $key };
  return $rv unless  'ARRAY' eq ref $rv;
  return @$rv;
}

sub add{
  my( $self => @add, ) = @_;
  while( @add >= 2 ){
    my( $key => $val ) = map{ shift @add; } 0..1;
    if(  not defined $$self{ $key } ){ $$self{ $key } = $val;
    } elsif(  'ARRAY' ne ref $$self{$key} ){
      $$self{ $key } = [ $$self{ $key } => $val, ];
    } else { push( @{ $$self{$key} } => $val, );
    }
  }
}

package Apache2::SizeLimit;
use strict;
use warnings;

our $MAX_UNSHARED_SIZE;

1;

package ModPerl::RegistryLoader;
use strict;
use warnings;

sub new{
  bless {}, shift;
}

sub handler{
}

package Apache::SubRequest;
use strict;
use warnings;

use base 'Apache';

sub new{
  my ( $caller => $conf, ) = @_;
  my $class = ref( $caller ) || $caller;
  my $r = bless( {%$conf} => $class, );
  $$r{ 'MAIN' } = $$conf{ 'MAIN' } || $conf;
  return $r;
}

sub run{
  my $self = shift;
  # TODO
  $self -> warn( 'not yet implemented', );
}

package Apache::Request;
use strict;
use warnings;

use base 'Apache';

use CGI qw(-private_tempfiles);
use Sub::Alias;

our $VERSION = '2.10';

sub new{
  my $cgi_mod_perl = $CGI::MOD_PERL;
  # SUPER::new copy begin
    my ($caller, $r, %options, ) = @_;
    my $class = ref( $caller ) || $caller;
    return Apache->request if ref( Apache->request ) eq $class;
    $CGI::POST_MAX = $options{ 'POST_MAX' } || 0;
    $CGI::DISABLE_UPLOADS = $options{ 'DISABLE_UPLOADS' } || 0;
    if( $options{ 'UPLOAD_HOOK' } ){
      $r -> warn('Upload hooks not implemented');
    }
    if( $options{ 'TEMP_DIR' } ){ $ENV{ 'TMPDIR' } = $options{ 'TEMP_DIR' }; }
    $CGI::MOD_PERL = 0; CGI -> _reset_globals;
    my $q = $$r{ 'CGI' } = CGI -> new; $CGI::MOD_PERL = $cgi_mod_perl;
    $$r{ 'UPLOADS' } = { map { $_ => undef }
      grep { my $x; $x = $q -> param($_) && ref($x) && fileno($x) }
    $q -> param };
    $r = bless( $r => $class, ); Apache -> request( $r );
    map{ $r -> { $_ } = {}; } qw/NOTES PNOTES/; return $r;
  # $SUPER::new copy end
}

alias('instance' => 'new');

sub parse{}

sub upload{
  my ( $self => $name, ) = @_;
  my $q = $$self{ 'CGI' };
  my $next = [ grep { $_ ne $name } keys %{$$self{'UPLOADS'}} ];
  if( defined $name ){
    return new Apache::Upload( $q, $name, $next, )
      if defined $$self{ 'UPLOADS' }{ $name };
    return;
  }
  return map( { Apache::Upload -> new( $q, $_, $next, ); }
    keys( %{ $$self{ 'UPLOADS' } } ) ) if wantarray;
  return Apache::Upload -> new( $q,
    ( keys %{ $$self{ 'UPLOADS' } } )[ 0 ], $next, );
}

package Apache::Upload;
use strict;
use warnings;

use Sub::Alias;

sub new{
  my( $caller, $q, $name, $next, ) = @_;
  my $class = ref( $caller ) || $caller;
  return bless( { 'CGI' => $q, 'NAME' => $name, 'NEXT' => $next, }
    => $class, );
}

sub name{ $_[ 0 ] -> { 'NAME' }; }
sub filename{
  my $self = shift;
  $$self{ 'CGI' } -> param( $$self{ 'NAME' }, );
}

alias('fh' => 'filename');

sub size{ ( $_[ 0 ] -> fh -> stat )[ 7 ]; }

sub info{
  my( $self => $key, ) = @_;
  return $$self{ 'CGI' } -> uploadInfo( $$self{ 'NAME' }, ) -> { $key }
    if defined $key;
  return Apache::Table -> new(
    $$self{ 'CGI' } -> uploadInfo( $$self{ 'NAME' }, ) );
}

sub type{ $_[ 0 ] -> info( 'Content-Type' ); }

sub next{
  my $self = shift;
  my @next = @{ $$self{ 'NEXT' } };
  my $name = shift @next || return undef;
  return Apache::Upload -> new( $$self{ 'CGI' }, $name, \@next, );
}

sub tempname{
  my $self = shift;
  return $$self{ 'CGI' } -> tmpFileName( $$self{ 'NAME' }, );
}

sub link{
  my ($self, $fn) = @_;
  link( $self -> tempname => $fn, );
}

package Apache::Constants;
use strict;
use warnings;

use Exporter; our @ISA = qw/Exporter/;

my @common = qw/OK DECLINED DONE NOT_FOUND FORBIDDEN AUTH_REQUIRED
  SERVER_ERROR/;

use constant OK => 0; use constant DECLINED => -1; use constant DONE => -2;
use constant NOT_FOUND => 404; use constant FORBIDDEN => 403;
use constant AUTH_REQUIRED => 401; use constant SERVER_ERROR => 500;

my @methods = qw/M_CONNECT M_DELETE M_GET M_INVALID M_OPTIONS M_POST M_PUT
  M_TRACE M_PATCH M_PROPFIND M_PROPPATCH M_MKCOL M_COPY M_MOVE M_LOCK M_UNLOCK
  M_HEAD METHODS
/;

use constant 'M_CONNECT' => 0; use constant 'M_DELETE' => 1;
use constant 'M_GET' => 2; use constant 'M_INVALID' => 3;
use constant 'M_OPTIONS' => 4; use constant 'M_POST' => 5;
use constant 'M_PUT' => 6; use constant 'M_TRACE' => 7;
use constant 'M_PATCH' => 8; use constant 'M_PROPFIND' => 9;
use constant 'M_PROPPATCH' => 10; use constant 'M_MKCOL' => 11;
use constant 'M_COPY' => 12; use constant 'M_MOVE' => 13;
use constant 'M_LOCK' => 14; use constant 'M_UNLOCK' => 15;
use constant 'M_HEAD' => 16; use constant 'METHODS' => 17;

my @options = qw(OPT_NONE OPT_INDEXES OPT_INCLUDES 
  OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
  OPT_SYM_OWNER OPT_MULTI OPT_ALL);

my @server = qw(MODULE_MAGIC_NUMBER
  SERVER_VERSION SERVER_BUILT);

my @response = qw/DOCUMENT_FOLLOWS MOVED REDIRECT USE_LOCAL_COPY BAD_REQUEST
  BAD_GATEWAY RESPONSE_CODES NOT_IMPLEMENTED NOT_AUTHORITATIVE CONTINUE/;

my @satisfy = qw/SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC/;

my @remotehost = qw(REMOTE_HOST REMOTE_NAME REMOTE_NOLOOKUP REMOTE_DOUBLE_REV);

use constant REMOTE_HOST => 0; use constant REMOTE_NAME => 1;
use constant REMOTE_NOLOOKUP => 2; use constant REMOTE_DOUBLE_REV => 3;

my @http = qw/HTTP_OK HTTP_MOVED_TEMPORARILY HTTP_MOVED_PERMANENTLY
  HTTP_METHOD_NOT_ALLOWED HTTP_NOT_MODIFIED HTTP_UNAUTHORIZED HTTP_FORBIDDEN
  HTTP_NOT_FOUND HTTP_BAD_REQUEST HTTP_INTERNAL_SERVER_ERROR
  HTTP_NOT_ACCEPTABLE HTTP_NO_CONTENT HTTP_PRECONDITION_FAILED HTTP_SERVICE_UNAVAILABLE
  HTTP_VARIANT_ALSO_VARIES
/;

use constant HTTP_OK => 200; use constant HTTP_MOVED_TEMPORARILY => 302;
use constant HTTP_MOVED_PERMANENTLY => 301;
use constant HTTP_METHOD_NOT_ALLOWED => 405;
use constant HTTP_NOT_MODIFIED => 304;
use constant HTTP_UNAUTHORIZED => 401;
use constant HTTP_FORBIDDEN => 403; use constant HTTP_NOT_FOUND => 404;
use constant HTTP_BAD_REQUEST => 400;
use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_ACCEPTABLE => 406; use constant HTTP_NO_CONTENT => 204;
use constant HTTP_PRECONDITION_FAILED => 412;
use constant HTTP_SERVICE_UNAVAILABLE => 503;
use constant HTTP_VARIANT_ALSO_VARIES => 506;

my @config = qw(DECLINE_CMD);
my @types = qw(DIR_MAGIC_TYPE);
my @override = qw/OR_NONE OR_LIMIT OR_OPTIONS OR_FILEINFO OR_AUTHCFG
  OR_INDEXES OR_UNSET OR_ALL ACCESS_CONF RSRC_CONF/;
my @args_how = qw/RAW_ARGS TAKE1 TAKE2 ITERATE ITERATE2 FLAG NO_ARGS TAKE12
  TAKE3 TAKE23 TAKE123/;

my $rc = [ @common => @response, ];

our %EXPORT_TAGS = (
  'common' => \@common, 'config' => \@config, 'response' => $rc,
  'http' => \@http, 'options' => \@options, 'methods' => \@methods,
  'remotehost' => \@remotehost, 'satisfy' => \@satisfy, 'server' => \@server,
  'types' => \@types, 'args_how' => \@args_how, 'override' => \@override,
  'response_codes' => $rc,
);
our @EXPORT_OK = ( @response, @http, @options, @methods, @remotehost, @satisfy,
  @server, @config, @types, @args_how, @override, ); 
our @EXPORT = @common;

package Apache2::RequestUtil;
use strict;
use warnings;
use base qw/Apache::Request Apache::Connection/;

sub request{ $_[ 1 ] = Apache->request; ( shift ) -> new( @_ ); }

package APR::Table;
use strict;
use warnings;

use base qw/Apache::Table/;

package Apache2::ServerUtil;
use strict;
use warnings;

use base qw/Apache::Server/;

use Apache::Fake;

sub server{
  my $caller = shift;
  my $request = Apache::Request->request;
  $caller->SUPER::new( $request );
}

sub add_config{ }
sub add_version_component{ }

package ModPerl::Registry;
use strict;
use warnings;

package Apache2::Const;
use strict;
use warnings;

use Apache::Constants qw/:common :http/;
our @ISA = qw/Apache::Constants/;

sub import{
  if( $_[ 0 ] eq '-compile' ){
    shift;
  }
}

package ModPerl::Const;
use strict;
use warnings;

use Apache::Constants qw/:common :http/;

package ModPerl;
use strict;
use warnings;

use base qw/Apache/;

package ModPerl::Util;
use strict;
use warnings;

use base qw/ModPerl/;

use Apache::Fake;

sub exit{
  exit;
}

package Apache::Cookie;
use strict;
use warnings;

use base qw/CGI::Cookie/;

package Apache2::Cookie;
use strict;
use warnings;

use base qw/Apache::Cookie/;

package Apache2::RequestRec;
use strict;
use warnings;

use base qw/Apache::Request/;

package Apache2::Cookie;
use strict;
use warnings;

use base qw/CGI::Cookie/;

package Apache2::Request;
use strict;
use warnings;

use base qw/Apache::Request/;

our $VERSION = '2.10';

package APR::Date;
use strict;
use warnings;

use HTTP::Date qw/str2time/;

sub parse_http{
  return 1_000_000 * str2time shift;
}

package APR::Request;
use strict;
use warnings;

use base qw/Apache2::Request/;

use Sub::Alias;

sub jar{
  my $cookies = Apache2::Cookie->new->fetch;
  my $rv = { map{
      $_ =>
      $cookies->{ $_ }->value;
    } keys %$cookies
  };
  return $rv;
}

alias('param' => 'Apache::param');

package APR::Request::Apache2;
use strict;
use warnings;

use base qw/APR::Request/;

sub handle{
  return bless $_[ 1 ], $_[ 0 ];
}

package Apache2::Upload;
use strict;
use warnings;

use base qw/Apache::Upload/;

package Apache;
use strict;
use warnings;

use HTTP::Status qw/status_message/;
use CGI::Carp qw(fatalsToBrowser);
use IO::Handle;
use Sub::Alias;

use Apache::Constants;

my $request;

sub request{
    my ($caller =>  $r, ) = @_;
    if( defined $r ){ $request = $r; }
    my $rv = defined( $request ) ? $request : Apache::Fake -> new;
    return $rv;
}

sub as_string{ ''.shift; }
sub main{ $_[ 0 ]->{ 'MAIN' }; }
sub prev{ $_[ 0 ]->{ 'PREV' }; }
sub next{ $_[ 0 ]->{ 'NEXT' }; }
sub is_main{ 1; }
sub is_initial_req{ 1; }
sub allowed{}
sub pool { return shift -> request; }
sub cleanup_request{ undef $request; CGI -> _reset_globals; }

sub last{
  my $self = shift;
  while( my $next = $self -> { 'NEXT' } ){ $self = $next; }
  return $self;
}

sub lookup_uri{
  my( $self => $uri, ) = @_;
  my $sr = Apache::SubRequest -> new( %{ $self }, );
  $self->warn( 'not yet implemented', );
  # TODO
  # emulate by setting $sr->{'PATH_INFO'}, {'FILE'} and {'URI'} and running through
  # most of new()
}
sub lookup_file{
  my( $self => $file, ) = @_;
  my $sr = Apache::SubRequest -> new( %{ $self }, );
  $self -> warn( 'not yet implemented', );
  # TODO
  # emulate by setting $sr->{'PATH_INFO'}, {'FILE'} and {'URI'} and running through
  # most of new()
}

sub method{
  my( $self => $method, ) = @_;
  if( defined $method ){ $$self{ 'METHOD' } = $method; }
  return $$self{ 'METHOD' };
}

my %methods = (
  'GET' => Apache::Constants::M_GET, 'HEAD' => Apache::Constants::M_HEAD,
  'POST' => Apache::Constants::M_POST,
  Apache::Constants::M_GET => 'GET', Apache::Constants::M_HEAD => 'HEAD',
  Apache::Constants::M_POST => 'POST',
);

sub method_number{
  my( $self => $method, ) = @_;
  if( defined $method ){ $$self{ 'METHOD' } = $methods{ $method }; }
  return $methods{ $$self{ 'METHOD' } };
}

sub bytes_sent{ -1; }

sub the_request{
  my $self = shift;
  $$self{ 'METHOD' } . ' ' . $$self{ 'URI' }
    . ( length($self->args) ? '?' . $self->args : '' )
    . ( ( $$self{ 'PROTOCOL' } ne 'HTTP/0.9' )
        ? ' ' . $$self{ 'PROTOCOL' } : '' );
}

sub proxyreq{ undef; }
sub header_only{ $_[ 0 ] -> { 'METHOD' } eq 'HEAD'; }
sub protocol{ $_[ 0 ] -> { 'PROTOCOL' }; }
sub hostname{ $_[ 0 ] -> { 'HOST' }; }
sub request_time{ $_[ 0 ] -> { 'TIME' }; }

sub uri{
  my( $self => $uri, ) = @_;
  if( defined $uri ){ $$self{ 'URI' } = $uri; }
  return $$self{ 'URI' };
}

sub filename{
  my( $self => $file, ) = @_;
  if( defined $file ){ $$self{ 'FILE' } = $file; }
  return $$self{ 'FILE' };
}

sub path_info{
  my ($self, $uri) = @_;
  if( defined $uri ){ $$self{ 'PATH_INFO' } = $uri; }
  return $$self{ 'PATH_INFO' };
}

sub args{
  my($self, $val) = @_;
  $$self{ 'ARGS' } = $val if defined $val;
  if( wantarray ){
    return map{ unescape_url_info($_) } split /[=&;]/, $$self{ 'ARGS' }, -1;
  } else {
    return $$self{ 'ARGS' };
  }
}

sub headers_in {
  my( $self => $key, ) = @_; my $rv;
  return %{ $$self{ 'HEADERS_IN' } } if wantarray; 
  if( defined $key ){
    $rv =  $$self{ 'HEADERS_IN' }{ ucfirst( lc( $key ) ) };
  } else{ $rv = Apache::Table -> new( ( $self->headers_in ) ); }
  return $rv;
}

sub header_in{
  my ($self, $key, $val, ) = @_;
  if( defined $val ){ $$self{ 'HEADERS_IN' }{ ucfirst( lc( $key ) ) } = $val; }
  $$self{ 'HEADERS_IN' }{$key};
}

sub content{
  my $self = shift;
  if( defined( $$self{ 'ENV' }{ 'CONTENT_LENGTH' } )
    and( $$self{ 'ENV' }{ 'CONTENT_TYPE' }
      eq 'application/x-www-form-urlencoded' )
    ){
    my $content;
    $self -> read( $content => $$self{ 'ENV' }{ 'CONTENT_LENGTH' }, );
    delete $$self{ 'ENV' }{ 'CONTENT_LENGTH' };
    if( wantarray ){
      return map{ unescape_url_info($_) } split /[=&;]/, $content, -1;
    } else {
      return $content;
    }
  }
  return undef;
}

sub read{
  my( $self, $buf, $cnt, $off, ) = @_;
  my $content = ''; $off ||= 0;
  $self -> soft_timeout( 'read timed out' );
  while( $cnt > 0 ){
    my $len = read( STDIN, $cnt, $off+length($buf), );
    $$self{ 'ABORTED' } = 1, die 'read error' if $len <= 0;
    $cnt -= $len; # FIXME: is this neccesary?
  }
}

sub get_remote_host{ my $self = shift; $self -> { 'REMOTE_HOST' } || $self -> { 'REMOTE_ADDR' }; }
sub get_remote_logname{ $_[ 0 ] -> { 'REMOTE_IDENT' }; }

sub connection{ Apache::Connection -> new( @_, ); }

sub dir_config {
  my( $self => $key, ) = @_;
  my $rv;
  if( defined $key ){
    $rv = $$self{ 'VAR' }{ $key };
  } elsif( wantarray ){
    $rv = [ %{ $$self{ 'VAR' } } ];
  } else {
    $rv = Apache::Table -> new( ( $self->dir_config, ), );
  }
  return ( 'ARRAY' eq ref( $rv ) ) ? @$rv : $rv;
}

sub requires{ $_[ 0 ] -> { 'REQUIRES' }; }
sub auth_type{ $_[ 0 ] -> { 'AUTH_TYPE' }; }
sub auth_name{ 'default'; }
sub document_root{ $_[ 0 ] -> { 'DOCUMENT_ROOT' }; }
sub allow_options{ -1; }
sub get_server_port{ $_[ 0 ] -> { 'LOCAL_PORT' }; }

sub get_handlers{
  my( $self => $key, ) = @_;
   @{ $$self{ 'HANDLERS' }{ $key } };
}
sub set_handlers{
  my( $self, $key, @rest, ) = @_;
   @{ $$self{'HANDLERS'}{$key} } = @rest;
}
sub push_handlers{
  my( $self, $key, $handler, ) = @_;
   unshift( @{ $$self{ 'HANDLERS' }{ $key } } => $handler, );
}

sub send_http_header{
  my( $self => $cttype, ) = @_;
  if( defined $$self{'HEADERS_SENT'} ){
    return;
  } else {
    $$self{ 'HEADERS_OUT' }{ 'Content-type' } = $cttype
      || $$self{ 'CONTENT_TYPE' };
    $self -> print( $self -> protocol." ".$self -> status_line );
    #$self -> warn($self -> status_line);
    $self -> print( "\n" );
    foreach my $header( keys %{ $$self{ 'EHEADERS_OUT' } } ){
      $self -> print( $header . ': ' . $$self{ 'EHEADERS_OUT' }{ $header } . "\n" );
      #$self -> warn($header.': '.$$self{ 'EHEADERS_OUT' }{$header});
    }
    foreach my $header( keys %{ $$self{ 'HEADERS_OUT' } } ){
      if( 'ARRAY' eq ref $$self{ 'HEADERS_OUT' }{$header} ){
        foreach( @{ $$self{ 'HEADERS_OUT' }{ $header } } ){
          $self -> print( $header . ': ' . $_ . "\n" );
        }
      } else {
        $self -> print( $header . ': ' . $$self{ 'HEADERS_OUT' }{ $header }
          . "\n" );
        #$self->warn($header.': '.$$self{'HEADERS_OUT'}{$header});
      }
    }
    $self->print( "\n" );
    $$self{ 'HEADERS_SENT' } = undef;
  }
}

# these will never be implemented
sub get_basic_auth_pw{ -1; }    # basic auth handled by webserver
sub note_basic_auth_failure{} # basic auth handled by webserver

sub handler { 'perl-script'; } # TODO: maybe emulate some common handlers

sub notes{
  my( $self, $key, $value, ) = @_;
  if( @_ == 3 ){
    $$self{ 'NOTES' }{ $key } = ''.$value;
  } elsif( @_ == 1 ){
    if( wantarray ){ return %{ $$self{ 'NOTES' } };
    } else {
      return Apache::Table -> new( $$self{ 'NOTES' }, );
    }
  }
  return $$self{ 'NOTES' }{ $key };
}

sub pnotes{
  my( $self, $key, $value, ) = @_;
  my $rv;
  if( @_ == 3 ) { $$self{ 'PNOTES' }{ $key } = $value; }
  elsif( @_ == 1 ){
    if( 'Apache::Table' eq ref $$self{ 'PNOTES' } ){
      $rv = $$self{ 'PNOTES' };
    } else { $rv =  Apache::Table -> new( $$self{ 'PNOTES' }, ); }
  }
  $rv //= $$self{ 'PNOTES' }{ $key };
  return $rv;
}

sub subprocess_env {
  my( $self, $key, $value, ) = @_;
  if( @_ == 3 ){
    $$self{ 'ENV' }{ $key } = $value;
  } elsif( @_ == 1 ){
    if( wantarray ){ return %{$$self{ 'ENV' }};
    } else {
      return Apache::Table -> new( $$self{ 'ENV' }, );
    }
  }
  return $$self{ 'ENV' }{ $key };
}

sub content_type{
  my ( $self => $ctt, ) = @_;
  if( defined $ctt ){
    $$self{ 'CONTENT_TYPE' } = $ctt;
  } else {
    return $$self{ 'CONTENT_TYPE' };
  }
}

sub content_encoding{
  my $self = shift;
  $self->header_out( 'Content-encoding', @_, );
}

sub content_languages{
  my( $self => $vals, ) = @_;
  if( defined $vals ){
    return [ split( /,\s*/, $self -> header_out( 'Content-languages',
      join( ',' => @$vals, ), ), ), ];
  } else {
    return [ split( /,\s*/, $self -> header_out( 'Content-languages', ), ), ];
  }
}

sub status{
  my( $self => $status, ) = @_;
  if( defined $status ){ $$self{ 'STATUS_CODE' } = $status; }
  else { return $$self{ 'STATUS_CODE' }; }
}

sub status_line{
  my( $self => $line, ) = @_;
  if( defined $line ){ $$self{ 'STATUS_LINE' } = $line; }
  if( defined $$self{ 'STATUS_LINE' } ){ return $$self{ 'STATUS_LINE' }; }
  else { return $$self{ 'STATUS_CODE' }. ' '
      . status_message( $$self{ 'STATUS_CODE' } ); }
}

sub headers_out{
  my ($self) = @_;
  if( wantarray ){
    return %{ $$self{ 'HEADERS_OUT' } };
  } else {
    return Apache::Table -> new( $$self{ 'HEADERS_OUT' }, );
  }
}

sub header_out{
  my( $self, $key, $value, ) = @_;
  if( defined $value ){
    if( defined $$self{ 'HEADERS_OUT' }{ $key } ){
      if( 'ARRAY' eq ref $$self{ 'HEADERS_OUT' }{ $key } ){
        push @{ $$self{ 'HEADERS_OUT' }{ $key } }, $value;
      } else {
        $$self{ 'HEADERS_OUT' }{ $key } = [
          $$self{ 'HEADERS_OUT' }{ $key },
          $value,
        ];
      }
    } else {
      $$self{ 'HEADERS_OUT' }{ $key } = $value;
    }
  }
  return $$self{ 'HEADERS_OUT' }{ $key };
}

sub err_headers_out{
  my $self = shift;
  if ( wantarray ){ return %{ $$self{ 'EHEADERS_OUT' } } ; }
  else{ return Apache::Table -> new( $$self{ 'EHEADERS_OUT' } ); }
}

sub err_header_out {
  my($self, $key, $value, ) = @_;
  $$self{ 'EHEADERS_OUT' }{ $key } = $value;
}

sub no_cache {
  my( $self => $val, ) = @_;
  if( $val ){ $self -> header_out( 'Pragma' => 'no-cache', ); }
  else { delete $$self{ 'HEADERS_OUT' }{ 'Pragma' }; }
}

sub print {
  my $self = shift;
  foreach my $arg ( @_, ){ if( 'SCALAR' eq ref $arg ){ $arg = $$arg; } }
  CORE::print @_;
}

*CORE::GLOBAL::print = \&print;

sub rflush { flush STDOUT; flush STDERR; }

sub send_fd {
  my ($self, $fh) = @_;
  my $buf;
  while( CORE::read( $fh => $buf, 16384 ) > 0 ){ CORE::print $buf; }
}

sub internal_redirect {
  my( $self => $place, ) = @_;
  $self -> warn( "not implemented yet!", );
  # TODO!
}

sub custom_response {
  my( $self => $uri, ) = @_;
  $self->warn( "not implemented yet!", );
  # TODO!
}

sub soft_timeout{
  my( $self => $message, ) = @_;
  $SIG{'ALRM'} = subname( 'soft_timeout_sig_alrm'
    => sub{ $$self{'ABORTED'} = $message; }, );
  alarm( 120 );
}

sub hard_timeout{
  my( $self =>  $message, ) = @_;
  $SIG{ 'ALRM' } = subname( 'hard_timeout_sig_alrm'
    => sub{ print STDERR $message,"\n"; exit(-1); }, );
  alarm(120);
}

sub kill_timeout{ alarm( 0 ); }
sub reset_timeout{ alarm( 120 ); }

sub cleanup_register {
  my ($self, $code) = @_;
  unless( grep{ $code eq $_ }
      @{ $$self{ 'HANDLERS' }{ 'PerlCleanupHandler' } }
    ){ push( @{ $$self{ 'HANDLERS' }{ 'PerlCleanupHandler' } } => $code, );
  }
}

alias('register_cleanup' => 'cleanup_register');

sub send_cgi_header{
  my( $self => $lines, ) = @_;
  my @lines = split( m/\s*\n\s*/ => $lines, );
  foreach my $line( @lines, ){
    last if $line eq '';
    $self -> header_out( ( $line =~ m/^([^:]+):\s*(.*)$/ ), );
  }
  $self -> send_http_header;
}

sub log_reason{
  my( $self, $reason, $file, ) = @_;
  $self -> log_error( "Failed: $file - $reason", );
}

sub log_error{ my ($self, $message) = @_; carp("$message"); }

sub warn{
  my( $self => $message, ) = @_;
  if( $$self{ 'LOG_LEVEL' } >= Apache::Log::WARNING ){
    $self -> log_error( $message, );
  }
}

sub unescape_url{
    my $string = shift;
    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $string;
}

sub unescape_url_info{
    my $string = shift;
    $string =~ s/\+/ /g;
    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $string;
}

my %hooks = (
#  'PostRead' => undef,
#  'Trans' => undef,
#  'HeaderParser' => undef,
#  'Access' => undef,
#  'Authen' => undef,
#  'Authz' => undef,
#  'Type' => undef,
#  'Fixup' => undef,
  '' => undef,
#  'Log' => undef,
#  'Cleanup' => undef,
#  'Init' => undef,
#  'ChildInit' => undef,
);

sub param{
  my $self = shift;
  my @param;
  if( wantarray ){ @param = $self -> { 'CGI' } -> param(@_); }
  else {
    if( @_ > 0 ){
      my $param = $self -> { 'CGI' } -> param( @_ ); @param = ( $param );
    }
    else { return $self -> { 'CGI' } -> Vars; }
  }
  if( ( @param == 0 ) and ( $self -> method eq "POST" ) ){
      @param = $self -> { 'CGI' } -> url_param( @_ );
  }
  return wantarray ? @param : shift @param;
}

sub perl_hook{ defined $hooks{ $_[ 0 ] }; }
sub exit{ shift; flush STDOUT; flush STDERR; exit( @_ ); }

package Apache::Fake;
use strict;
use Socket;
use Sub::Name;

Apache::Constants -> import;

my $with_config_file = 0;

sub import{
  shift;
  if( grep{ $_ =~ m/^config_?file$/ } @_ ){
    die $@ unless eval( "use Apache::ConfigFile; 1;" );
    $with_config_file = 1;
  }
}

#-----------------------------------------------------------------------

=head1 NAME

Apache::Fake - fake a mod_perl request object

=head1 VERSION

This document refers to version 0.10 of Apache::Fake, released
February 1, 2002.

=head1 SYNOPSIS

Case 1: Using a CGI script as Apache SetHandler

/cgi-bin/nph-modperl-emu.cgi:

    #!/usr/bin/perl
    use lib '/some/private/lib_path';
    use Apache::Fake;
    new Apache::Fake('httpd_conf' => '/some/private/httpd.conf',
      'dir_conf' => '.htaccess.emu');


In your httpd.conf or .htaccess, add something like this:

    Action modperl-emu /cgi-bin/nph-modperl-emu.cgi
    SetHandler modperl-emu

Access page just like under mod_perl. (http://host/real/page/here.html)


Case 2: Exclusively using PATH_INFO

/cgi-bin/nph-modperl-emu.cgi:

  #!/usr/bin/perl
  use lib '/some/private/lib_path';
  use Apache::Fake;

        new Apache::Fake('httpd_conf' => '/some/private/httpd.conf',
        'dir_conf' => '.htaccess.emu',
        'handler_cgi' => '/cgi-bin/nph-modperl-emu.cgi',
        'virtual_root' => '/some/private/document_root');

Access page like: http://host/cgi-bin/nph-modperl-emu.cgi/real/page/here.html


=head1 DESCRIPTION

This module fakes a mod_perl request object using the Common Gateway
Interface. Everything that works with mod_perl should work with Apache::Fake
as well. Apache::Fake parses apache-style config files for any relevant settings.
A working mod_perl configuration should work without any modifications given all
relevant config files are found. If not, you've found a bug.

Apache::Fake currently emulates the following modules: Apache, Apache::Request,
Apache::Table, Apache::Log, mod_perl. Re-use-ing these modules will do no harm,
since Apache::Fake sets %INC for these modules.

For documentation, refer to the mod_perl documentation.

Things planned, but not yet working, are: Subrequests, other handlers than
PerlHandler, internal_redirect, custom_response, $r->handler().

Things that never will work are: $->get_basic_auth_pw,
$r->note_basic_auth_failure.

=head1 CONSTRUCTOR

=over 4

=item new Apache::Fake([option => value, ...])

The constructor will parse an apache-style config file to retrieve any
relevant settings, like PerlHandler and PerlSetVar. It will also obey
local .htaccess-style config files. You can use the 'real' config files
or provide your own, stripped down versions. The most useful configuration
is to use the 'real' httpd.conf, but fake .htaccess files, so you can
provide PerlSetVar and PerlHandler even if the web server does not
recognize these keywords.

The following settings are used:

=over 4

=item httpd_conf => '/etc/apache/httpd.conf'

Path to the main config file. Default is undef, i.e. not used. Neccessary
for some subrequest functions.

=item dir_conf => '.htaccess'

File name of the per-directory config file. Default is '.htaccess'. Only
PerlSetVar, PerlModule and PerlHandler are used. <Files> sections are
currently ignored.

Caveat: The algorithm searching for a matching file will ascend the
physical path, not the logical. So it might miss some files, and find
additional ones. This can be considered a feature.


One of these two files is neccessary, since you need a PerlHandler
directive.

=item handler_cgi => '/cgi-bin/nph-mod_perl-handler.cgi'

URI of the handler script. If this parameter is given, 'virtual_root' must
be set as well, and Apache::Fake operates in PATH_INFO mode. In this mode,
all URLs go like: http://host/cgi-bin/nph-mod_perl-handler.cgi/real/path.

=item virtual_root => '/home/siteX/modperl_docs'

Path to the virtual root directory of your mod_perl documents/scripts. This
directory contains all files accessed through Apache::Fake. It should not be
inside your normal document root.

=back

=back

=head1 WARNING

This is alpha-quality software. It works for me and for some moderately complex
perl modules (the HTML::Mason suite). Not every aspect was tested or checked for
strict compatibility to mod_perl 1.27. Please report any problems you find via
http://rt.cpan.org.

=head1 TO DO

=over 4

=item * Emulate Perl*Handlers by calling them in sequence

=item * Emulate handler() by emulating some common handlers

=item * Emulate subrequests and redirects by doing our own URI->filename mapping. Then
PerlTransHandlers will work, too.

=item * Emulate custom_response via previous mapping

=item * Emulate internal redirects via previous mapping

=back

=head1 REQUIRED

perl 5.6.0, Apache::ConfigFile, CGI, CGI::Carp, HTTP::Status

=head1 ACKNOWLEDGEMENTS

This module was inspired by a posting on the HTML::Mason mailing list by
Alexey Tourbin (alexey_tourbin@mail.ru) and Apache::Emulator by Nigel
Wetters (nwetters@cpan.org), both of which were very limited in function.
Some ideas have been borrowed from both sources. 

=head1 AUTHOR

Jörg Walter E<lt>ehrlich@ich.bin.kein.hoschi.deE<gt>.

=head1 VERSION

0.10

=head1 SEE ALSO

L<Apache>, L<Apache::Request>

=cut

sub new{
  my( $caller => %conf, ) = @_;
  $ENV{ 'MOD_PERL' } = 'mod_perl/1.27';
  $ENV{ 'GATEWAY_INTERFACE' } = 'CGI-Perl/1.1';
  # setup request parameters:
  $conf{ 'ENV' } = \%ENV; # environment
  if( defined( $ENV{ 'SERVER_NAME' } )  or defined( $ENV{ 'SERVER_PORT' } )
      or defined( $ENV{ 'PATH_INFO' } )
    ){
    my( $name, $port, $info, ) = map{ ''; } 0..2;
    if( defined $ENV{ 'SERVER_NAME' } ){ $name = $ENV{ 'SERVER_NAME' }; }
    if( defined( $ENV{ 'SERVER_PORT' } ) and $ENV{ 'SERVER_PORT' } != 80 ){
      $port = ':' . $ENV{ 'SERVER_PORT' };
    }
    if( defined $ENV{ 'PATH_INFO' } ){ $info = $ENV{ 'PATH_INFO' }; }
    $conf{ 'URI' } = "$name$port$info";
  } # request URI
  if( defined $conf{ 'FILE' } ){
    $conf{ 'FILE' } = $conf{ 'ENV' }{ 'PATH_TRANSLATED' };
    while( $conf{ 'FILE' } and not( -e $conf{ 'FILE' } ) ){
      $conf{ 'FILE' } =~ s/\/[^\/]*$//;
    }
  } else { $conf{ 'FILE' } = '/'; } # physical filename
  if( defined $ENV{ 'SERVER_NAME' } ){
    $conf{ 'HOST' } = $ENV{ 'SERVER_NAME' };
  } # (virtual) host name
  if( defined $ENV{ 'REQUEST_METHOD' } ){
    $conf{ 'METHOD' } = $ENV{ 'REQUEST_METHOD' };
  } # http method
  if( defined $ENV{ 'SERVER_PROTOCOL' } ){
    $conf{ 'PROTOCOL' } = $conf{ 'ENV' }{ 'SERVER_PROTOCOL' };
  } # http protocol
  $conf{ 'TIME' } = time(); # time
  $conf{ 'STATUS_CODE' } = 200; # result status
  $conf{ 'CLEANUP' } = []; # cleanup
  $conf{ 'LOG_LEVEL' } = Apache::Log::INFO; # log level
  if( defined $ENV{ 'QUERY_STRING' } ){
    $conf{ 'ARGS' } = $ENV{ 'QUERY_STRING' };
  } # args
  $conf{ 'NOTES' } = {}; $conf{ 'PNOTES' } = {}; # notes
  if( $ENV{ 'REMOTE_HOST' } ){
    $conf{ 'REMOTE_HOST' } = $ENV{ 'REMOTE_HOST' };
  } # remote host
  if( defined $ENV{ 'REMOTE_USER' } ){
    $conf{ 'USER' } = $ENV{ 'REMOTE_USER' };
  }
  if( defined $ENV{ 'AUTH_TYPE' } ){
    $conf{ 'AUTH_TYPE' } = $ENV{ 'AUTH_TYPE' };
  } # auth info
  my $sa;
  if( $sa = getsockname( STDIN ) ){
    ( $conf{ 'LOCAL_PORT' } => $conf{ 'LOCAL_ADDR' }, ) = sockaddr_in( $sa );
    $conf{ 'LOCAL_ADDR' } = inet_ntoa( $conf{ 'LOCAL_ADDR' } );
  } else {
    if( defined $conf{ 'HOST' } ){
      $conf{ 'LOCAL_ADDR' } = gethostbyname( $conf{ 'HOST' } );
    }
    if( defined $ENV{ 'SERVER_PORT' } ){
      $conf{ 'LOCAL_PORT' } = $ENV{ 'SERVER_PORT' };
    }
  }
  if( $sa = getpeername( STDIN ) ){
    ( $conf{ 'REMOTE_PORT' } => $conf{ 'REMOTE_ADDR' }, ) = sockaddr_in($sa);
    $conf{ 'REMOTE_ADDR' } = inet_ntoa( $conf{ 'REMOTE_ADDR' } );
  } else {
    if( defined $ENV{ 'REMOTE_ADDR' } ){
      $conf{ 'REMOTE_ADDR' } = $ENV{ 'REMOTE_ADDR' };
    }
    $conf{ 'REMOTE_PORT' } = -1;
  } # ip addresses/ports
  $conf{ 'ABORTED' } = 0; # connection
  if( defined $ENV{ 'REMOTE_IDENT' } ){
    $conf{ 'REMOTE_IDENT' } = $conf{ 'ENV' }{ 'REMOTE_IDENT' };
  } # remote ident
  my %headers;
  foreach my $hdr( keys %ENV, ){
    if( $hdr =~ m/^HTTP_(.*)$/ ){
      my $name = ucfirst( lc( $1 ) ); $name =~ s/_/-/g;
      $headers{ $name } = $conf{ 'ENV' }{ $hdr };
    }
  }
  $conf{ 'HEADERS_IN' } = \%headers;
  $conf{ 'HEADERS_OUT' } = {};
  $conf{ 'CONTENT_TYPE' } = 'text/plain';
  $conf{ 'EHEADERS_OUT' } = {}; # headers
  # get settings from config file(s)
  my @modules; my $vars = Apache::Table -> new(); my $handlers = {};
  my( $docroot => $admin, ); my( $aliases => $requires, ) = ( [] => [], );
  my( $ctx, $loc, $rest, );
  my $addContext = subname( 'add_context' => sub{
    return unless $ctx;
    push( @modules => map { join( " " => @{ $_ }, ); } $ctx -> cmd_config_array( 'PerlModule', ), );
    #$self->warn("modules: ").join(",",@modules)."\n";
    %$vars = ( %$vars => $ctx -> cmd_config_hash( 'PerlSetVar', ), );
    foreach my $var( $ctx->cmd_config_array( 'PerlAddVar' ), ){
      #$self->warn("adding @$var\n");
      $vars->add( @$var, );
    }
    # TODO: more Perl*Handlers
    if( $ctx -> cmd_config_array( 'PerlHandler' ) ){
      ( $$handlers{ 'PerlHandler' } ) = map{ @{ $_ } }
        $ctx->cmd_config_array( 'PerlHandler', );
    }
    if( $ctx -> cmd_config_array( 'DocumentRoot', ) ){
      ( $docroot ) = map{ @{ $_ } }
        $ctx -> cmd_config_array( 'DocumentRoot', );
    }
    if( $ctx -> cmd_config_array( 'ServerAdmin', ) ){
      ( $admin ) = map{ @{ $_ } } $ctx -> cmd_config_array( 'ServerAdmin' );
    }
    if( $ctx -> cmd_config_array( 'ServerAlias', ) ){
      $aliases = [ map{ @{ $_ } }
        $ctx -> cmd_config_array( 'ServerAlias' ) ];
    }
    if( $ctx -> cmd_config_array( 'requires', ) ){
      $requires = [ map{ @{ $_ } } $ctx -> cmd_config_array( 'requires' ) ];
    }
  }, );
  $conf{ 'VIRTUAL' } = 0;
  if( defined $conf{ 'httpd_conf' } ){
    $ctx = Apache::ConfigFile -> read( $conf{ 'httpd_conf' }, );
    &$addContext; my $ctx2 = $ctx;
    $ctx = $ctx -> cmd_context( 'ServerName' => $ENV{ 'SERVER_NAME' }, );
    if( $ctx and( $ctx2 ne $ctx ) ){ $conf{ 'VIRTUAL' } = 1; }
    &$addContext; $loc = '/';
    $rest = substr( $conf{ 'ENV' }{ 'PATH_INFO' } => 1, );
    $ctx = $ctx -> cmd_context( 'Location' => '/', ); &$addContext;
    while( length( $rest ) ){
      $rest =~ s/^(\/*[^\/]*)//; $loc .= $1;
      $ctx = $ctx -> cmd_context(Location => $loc);
      &$addContext;
    }
    $loc = '/'; $rest = $conf{ 'FILE' };
    $ctx = $ctx -> cmd_context( 'Directory' => '/' ); &$addContext;
    while( length( $rest ) ){
      $rest =~ s/^(\/*[^\/]*)//; $loc .= $1;
      $ctx = $ctx -> cmd_context( 'Directory' => $loc, );
      &$addContext;
    }
  }
  my $dconf = ''; $loc = '/';
  if( defined $conf{ 'dir_conf' } ){
    $dconf = $conf{ 'dir_conf' };
    $loc .= $dconf;
  }
  $rest = '';
  if( defined $conf{ 'FILE' } ){ $rest = $conf{'FILE'}; }
  if( -f $loc ){ $ctx = Apache::ConfigFile -> read( $loc ); &$addContext; }
  while( length( $rest ) ){ $rest =~ s/^(\/*[^\/]*)//; my $next = $1;
    $loc =~ s/\/$dconf$/$next\/$dconf/;
    next unless -f $loc;
    $ctx = Apache::ConfigFile -> read( $loc ); &$addContext;
  }
  $conf{ 'DOCUMENT_ROOT' } = $docroot; # document root
  $conf{ 'VAR' } = $vars; # PerlSetVar/PerlAddVar
  #$self->warn("Vars: ").join(",",keys %$vars),"\n";
  $conf{ 'ADMIN' } = $admin; # server admin
  $conf{ 'REQUIRES' } = $requires; # access restrictions
  $conf{ 'ALIASES' } = $aliases; # server aliases
  $conf{ 'HANDLERS' } = $handlers; # handlers
  my $class = ref( $caller ) || $caller; # create request object
  my $r = bless( \%conf => 'Apache', );
  Apache -> request( $r );
  # load PerlModules
  foreach my $mod( @modules ){
    die( $@ ) unless eval( "require $mod; 1;", );
  }
  if( $with_config_file ){
    unless( defined $conf{ 'dir_conf' } ){ $conf{ 'dir_conf' } = '.htaccess'; }
    if( defined $conf{ 'handler_cgi' } ){
      die( 'virtual_root missing' ) unless defined $conf{ 'virtual_root' };
      $ENV{ 'PATH_TRANSLATED' } = $conf{ 'virtual_root' }
        . $ENV{ 'PATH_INFO' };
      $ENV{ 'PATH_INFO' } = $conf{ 'handler_cgi' } . $ENV{ 'PATH_INFO' };
    }
    $conf{ 'FD_IN' } = fileno( STDIN ); $conf{ 'FD_OUT' } = fileno( STDOUT );
    die( 'no PerlHandler found, but we have: ' . join( keys %$handlers ) )
      unless defined $$handlers{ 'PerlHandler' };
    my $eval_string = $$handlers{'PerlHandler'};
    if( $eval_string =~ m/->/ ){ $eval_string .= '($r)';
    } elsif( $eval_string =~ m/^[a-zA-Z_0-9:]+$/ ){
      $eval_string .= '::handler($r)';
    } elsif( $eval_string !~ m/[{&]/ ){
      die "unknown handler syntax: $eval_string";
    }
    #$r->warn("invoking: $eval_string");
    my $rc = eval($eval_string);
    die( $@ ) if $@;
    #$r->warn("rc = $rc");
    if( $rc ){ $r->status($rc); }
    $r->send_http_header;
  }
  return $r;
}

1;
