#!/usr/bin/perl -w

use strict;
use warnings;


our $WebguiRoot;
BEGIN{
	use Cwd qw/realpath/; use File::Basename qw/dirname/;
	$WebguiRoot = realpath( dirname( __FILE__ )."/../" );
	my $wg_lib = realpath( "$WebguiRoot/lib" );
	unshift( @INC, $wg_lib ) unless grep { $_ eq $wg_lib } @INC;
}

use FCGI::Spawn::ModPerl;
use WebGUI;
my $r = FCGI::Spawn::ModPerl->new;
$r->{ VAR }->{ WebguiRoot } = $WebguiRoot;
WebGUI::handler(
  $r, "WebGUI.conf",
);

#print "Content-type: text/plain\n\n";
use Data::Dumper;
map{
   # print Dumper $_, $r->{ HEADERS_OUT }, $r->{ EHEADERS_OUT };
  if( $_ eq 'Response' ){
    #$r->send_http_header;
  }
  my $handlerName = "Perl$_"."Handler";
  if( defined( $r->{ HANDLERS }->{ $handlerName } )
    and 'ARRAY' eq ref $r->{ HANDLERS }->{ $handlerName }
  ){
    map{
      $_->();
    } @{ $r->{ HANDLERS }->{ $handlerName } }
  }
} qw/PostReadRequest Init Trans MapToStorage HeaderParser Access Authen Authz Type Fixup Response Log/;
