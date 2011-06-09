#
#  Apache::Fake - fake a mod_perl environment
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
package Apache::Fake;
use strict;
require 5.6.0;
BEGIN {
	$Apache::Fake::VERSION = 0.10;
	$INC{'Apache.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'Apache/Constants.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'Apache/Request.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'Apache/Log.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'Apache/Table.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'Apache/Status.pm'} = $INC{'Apache/Fake.pm'};
	$INC{'mod_perl.pm'} = $INC{'Apache/Fake.pm'};
}

package mod_perl;
use strict;
BEGIN {
	$mod_perl::VERSION = 1.27;
}

package Apache::Log;
use strict;
use constant EMERG => 0;
use constant ALERT => 1;
use constant CRIT => 2;
use constant ERR => 3;
use constant WARNING => 4;
use constant NOTICE => 5;
use constant INFO => 6;
use constant DEBUG => 7;

package Apache::Server;
use strict;

use vars qw($Starting $ReStarting);
$Starting = 0;
$ReStarting = 0;

sub new {
    my ($caller, $r) = @_;
    my $class = ref($caller) || $caller;

    return bless {request => $r}, $class;
}

sub server_admin { (shift)->{'request'}->{'ADMIN'} }
sub server_hostname { (shift)->{'request'}->{'HOST'} }
sub port { (shift)->{'request'}->{'LOCAL_PORT'} }
sub is_virtual { (shift)->{'request'}->{'VIRTUAL'} }
sub names { @{ (shift)->{'request'}->{'ALIASES'} } }
sub dir_config { (shift)->{'request'}->dir_config(@_) }
sub warn { (shift)->{'request'}->warn(@_) }
sub log_error { (shift)->{'request'}->log_error(@_) }
sub uid { getuid() }
sub gid { getgid() }
sub loglevel {
	my ($self, $level) = @_;
	$$self{'LOG_LEVEL'} = $level if defined $level;
	$$self{'LOG_LEVEL'};
}

package Apache::Connection;
use strict;
use Socket;

sub new {
    my ($caller, $r) = @_;
    my $class = ref($caller) || $caller;

    return bless {request => $r}, $class;
}

sub remote_host { (shift)->{'request'}->{'REMOTE_HOST'} }
sub remote_ip {
    my ($self, $val) = @_;
    if (defined $val) {
    	$self->{'request'}->{'REMOTE_ADDR'} = $val;
	undef $self->{'request'}->{'REMOTE_HOST'};
    }
    $self->{'request'}->{'REMOTE_ADDR'};
}
sub local_addr {
    my $self = shift;
    pack_sockaddr_in(inet_aton($self->{'request'}->{'LOCAL_ADDR'}),
    	$self->{'request'}->{'LOCAL_PORT'});
}
sub remote_addr {
    my $self = shift;
    pack_sockaddr_in(inet_aton($self->{'request'}->{'REMOTE_ADDR'}),
    	$self->{'request'}->{'REMOTE_PORT'});
}
sub remote_logname { (shift)->{'request'}->remote_logname(); }
sub user {
    my ($self, $val) = @_;
    $self->{'request'}->{'USER'} = $val if defined $val;
    $self->{'request'}->{'USER'};
}
sub auth_type { (shift)->{'request'}->{'AUTH_TYPE'}; }
sub fileno {
	my ($self, $dir) = @_;
	if (defined $dir && !$dir) {
		return $self->{'request'}->{'FD_IN'};
	} else {
		return $self->{'request'}->{'FD_OUT'};
	}
}

package Apache::Table;
use strict;
sub new {
    my ($caller,%content) = @_;
    my $class = ref($caller) || $caller;

    return bless {%content}, $class;
}

sub get {
    my ($self, $key) = @_;
    return $$self{$key} unless ref($$self{$key}) eq 'ARRAY';
    return @{$$self{$key}};
}

sub add {
    my ($self, @add) = @_;
    while (@add >= 2) {
    	my $key = shift @add;
	my $val = shift @add;
	if (!exists $$self{$key}) {
	    $$self{$key} = $val;
	} elsif (ref($$self{$key}) ne 'ARRAY') {
	    $$self{$key} = [ $$self{$key}, $val ];
	} else {
	    push @{$$self{$key}}, $val;
	}
    }
}

package Apache::SubRequest;
use strict;
@Apache::SubRequest::ISA = 'Apache';

sub new {
    my ($caller, $conf) = @_;
    my $class = ref($caller) || $caller;

    my $r = bless {%$conf}, $class;

    $$r{'MAIN'} = $$conf{'MAIN'} || $conf;
    return $r;
}

sub run {
    my $self = shift;
    # TODO
    $self->warn('not yet implemented');
}

package Apache::Request;
use strict;
use CGI qw(-private_tempfiles);
@Apache::Request::ISA = 'Apache';

sub new {
    my ($caller, $r, %options) = @_;
    my $class = ref($caller) || $caller;
    return Apache->request if ref(Apache->request) eq $class;

    $CGI::POST_MAX = $options{'POST_MAX'} || 0;
    $CGI::DISABLE_UPLOADS = $options{'DISABLE_UPLOADS'} || 0;
    $r->warn('Upload hooks not implemented') if $options{'UPLOAD_HOOK'};
    $ENV{'TMPDIR'} = $options{'TEMP_DIR'} if $options{'TEMP_DIR'};
    my $q = $$r{'CGI'} = new CGI;
    $$r{'UPLOADS'} = { map { $_ => undef } grep { my $x; $x = $q->param($_) && ref($x) && fileno($x) } $q->param };

    $r = bless $r, $class;
    Apache->request($r);
    return $r;
}

*instance = \&new;

sub parse { }

sub param { (shift)->{'CGI'}->param(@_) }

sub upload {
	my ($self, $name) = @_;
	my $q = $$self{'CGI'};
	my $next = [ grep { $_ ne $name } keys %{$$self{'UPLOADS'}} ];
	if (defined $name) {
		return new Apache::Upload($q,$name,$next) if exists $$self{'UPLOADS'}{$name};
		return;
	}
	return map { new Apache::Upload($q,$_,$next) } keys %{$$self{'UPLOADS'}} if wantarray;
	return new Apache::Upload($q,(keys %{$$self{'UPLOADS'}})[0],$next);
}

package Apache::Upload;
use strict;

sub new {
    my ($caller, $q, $name, $next) = @_;
    my $class = ref($caller) || $caller;

    return bless {CGI => $q, NAME => $name, NEXT => $next}, $class;
}

sub name { (shift)->{'NAME'} }
sub filename {
	my $self = shift;
	$$self{'CGI'}->param($$self{'NAME'});
}
*fh = \&filename;
sub size { ((shift)->fh->stat)[7] }
sub info {
	my ($self, $key) = @_;
	return $$self{'CGI'}->uploadInfo($$self{'NAME'})->{$key} if defined $key;
	return new Apache::Table($$self{'CGI'}->uploadInfo($$self{'NAME'}));
}
sub type { (shift)->info('Content-Type') }
sub next {
	my $self = shift;
	my @next = @{$$self{'NEXT'}};
	my $name = shift @next || return undef;
	return new Apache::Upload($$self{'CGI'}, $name, \@next);
}
sub tempname {
	my $self = shift;
	return $$self{'CGI'}->tmpFileName($$self{'NAME'});
}
sub link {
	my ($self, $fn) = @_;
	link($self->tempname,$fn);
}

package Apache::Constants;
use vars qw (%EXPORT_TAGS @EXPORT_OK $EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);

my @common = qw(OK
		DECLINED
		DONE
		NOT_FOUND
		FORBIDDEN
		AUTH_REQUIRED
		SERVER_ERROR);

use constant OK => 0;
use constant DECLINED => -1;
use constant DONE => -2;
use constant NOT_FOUND => 404;
use constant FORBIDDEN => 403;
use constant AUTH_REQUIRED => 401;
use constant SERVER_ERROR => 500;

my(@methods) = qw(M_CONNECT
		  M_DELETE
		  M_GET
		  M_INVALID
		  M_OPTIONS
		  M_POST
		  M_PUT
		  M_TRACE
		  M_PATCH
		  M_PROPFIND
		  M_PROPPATCH
		  M_MKCOL
		  M_COPY
		  M_MOVE
		  M_LOCK
		  M_UNLOCK
		  M_HEAD
		  METHODS);

use constant M_CONNECT => 0;
use constant M_DELETE => 1;
use constant M_GET => 2;
use constant M_INVALID => 3;
use constant M_OPTIONS => 4;
use constant M_POST => 5;
use constant M_PUT => 6;
use constant M_TRACE => 7;
use constant M_PATCH => 8;
use constant M_PROPFIND => 9;
use constant M_PROPPATCH => 10;
use constant M_MKCOL => 11;
use constant M_COPY => 12;
use constant M_MOVE => 13;
use constant M_LOCK => 14;
use constant M_UNLOCK => 15;
use constant M_HEAD => 16;
use constant METHODS => 17;

my(@options)    = qw(OPT_NONE OPT_INDEXES OPT_INCLUDES 
		     OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC
		     OPT_SYM_OWNER OPT_MULTI OPT_ALL);

my(@server)     = qw(MODULE_MAGIC_NUMBER
		     SERVER_VERSION SERVER_BUILT);

my(@response)   = qw(DOCUMENT_FOLLOWS
		     MOVED
		     REDIRECT
		     USE_LOCAL_COPY
		     BAD_REQUEST
		     BAD_GATEWAY 
		     RESPONSE_CODES
		     NOT_IMPLEMENTED
		     NOT_AUTHORITATIVE
		     CONTINUE);

my(@satisfy)    = qw(SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC);

my(@remotehost) = qw(REMOTE_HOST
		     REMOTE_NAME
		     REMOTE_NOLOOKUP
		     REMOTE_DOUBLE_REV);

use constant REMOTE_HOST       => 0;
use constant REMOTE_NAME       => 1;
use constant REMOTE_NOLOOKUP   => 2;
use constant REMOTE_DOUBLE_REV => 3;

my(@http)       = qw(HTTP_OK
		     HTTP_MOVED_TEMPORARILY
		     HTTP_MOVED_PERMANENTLY
		     HTTP_METHOD_NOT_ALLOWED 
		     HTTP_NOT_MODIFIED
		     HTTP_UNAUTHORIZED
		     HTTP_FORBIDDEN
		     HTTP_NOT_FOUND
		     HTTP_BAD_REQUEST
		     HTTP_INTERNAL_SERVER_ERROR
		     HTTP_NOT_ACCEPTABLE 
		     HTTP_NO_CONTENT
		     HTTP_PRECONDITION_FAILED
		     HTTP_SERVICE_UNAVAILABLE
		     HTTP_VARIANT_ALSO_VARIES);

use constant HTTP_OK                    => 200;
use constant HTTP_MOVED_TEMPORARILY     => 302;
use constant HTTP_MOVED_PERMANENTLY     => 301;
use constant HTTP_METHOD_NOT_ALLOWED    => 405;
use constant HTTP_NOT_MODIFIED          => 304;
use constant HTTP_UNAUTHORIZED          => 401;
use constant HTTP_FORBIDDEN             => 403;
use constant HTTP_NOT_FOUND             => 404;
use constant HTTP_BAD_REQUEST           => 400;
use constant HTTP_INTERNAL_SERVER_ERROR => 500;
use constant HTTP_NOT_ACCEPTABLE        => 406;
use constant HTTP_NO_CONTENT            => 204;
use constant HTTP_PRECONDITION_FAILED   => 412;
use constant HTTP_SERVICE_UNAVAILABLE   => 503;
use constant HTTP_VARIANT_ALSO_VARIES   => 506;

my(@config)     = qw(DECLINE_CMD);
my(@types)      = qw(DIR_MAGIC_TYPE);
my(@override)    = qw(
		      OR_NONE
		      OR_LIMIT
		      OR_OPTIONS
		      OR_FILEINFO
		      OR_AUTHCFG
		      OR_INDEXES
		      OR_UNSET
		      OR_ALL
		      ACCESS_CONF
		      RSRC_CONF);
my(@args_how)    = qw(
		      RAW_ARGS
		      TAKE1
		      TAKE2
		      ITERATE
		      ITERATE2
		      FLAG
		      NO_ARGS
		      TAKE12
		      TAKE3
		      TAKE23
		      TAKE123);

my $rc = [@common, @response];

%EXPORT_TAGS = (
		common     => \@common,
		config     => \@config,
		response   => $rc,
		http       => \@http,
		options    => \@options,
		methods    => \@methods,
		remotehost => \@remotehost,
		satisfy    => \@satisfy,
		server     => \@server,				   
		types      => \@types, 
		args_how   => \@args_how,
		override   => \@override,
		response_codes => $rc,
		);

@EXPORT_OK = (
	      @response,
	      @http,
	      @options,
	      @methods,
	      @remotehost,
	      @satisfy,
	      @server,
	      @config,
	      @types,
	      @args_how,
	      @override,
	      ); 

*EXPORT = \@common;

package Apache;
use strict;
use HTTP::Status qw();
use CGI::Carp qw(fatalsToBrowser);
use Apache::Constants;
use IO::Handle;

my $request;
sub request
{
    my ($caller, $r) = @_;
    $request = $r if defined $r;
    $request || bless {}, 'Apache';
}


sub as_string { ''.shift }
sub main { (shift)->{'MAIN'} }
sub prev { (shift)->{'PREV'} }
sub next { (shift)->{'NEXT'} }
sub last {
	my ($self) = shift;
	$self = $self->{'NEXT'} while $self->{'NEXT'};
	$self;
}
sub is_main { 1 }
sub is_initial_req { 1 }
sub allowed { }

sub lookup_uri {
    my ($self, $uri) = @_;
    my $sr = new Apache::SubRequest(%{$self});
    $self->warn('not yet implemented');
    # TODO
    # emulate by setting $sr->{'PATH_INFO'}, {'FILE'} and {'URI'} and running through
    # most of new()
}
sub lookup_file {
    my ($self, $file) = @_;
    my $sr = new Apache::SubRequest(%{$self});
    $self->warn('not yet implemented');
    # TODO
    # emulate by setting $sr->{'PATH_INFO'}, {'FILE'} and {'URI'} and running through
    # most of new()
}

sub method {
	my ($self, $method) = @_;
	$$self{'METHOD'} = $method if defined $method;
	$$self{'METHOD'};
}

my %methods = (
	'GET' => Apache::Constants::M_GET,
	'HEAD' => Apache::Constants::M_HEAD,
	'POST' => Apache::Constants::M_POST,
	Apache::Constants::M_GET => 'GET',
	Apache::Constants::M_HEAD => 'HEAD',
	Apache::Constants::M_POST => 'POST',
);

sub method_number {
	my ($self, $method) = @_;
	$$self{'METHOD'} = $methods{$method} if defined $method;
	$methods{$$self{'METHOD'}};
}

sub bytes_sent { -1 }

sub the_request {
	my $self = shift;
	$$self{'METHOD'}.' '.$$self{'URI'}.(length($self->args)?'?'.$self->args:'')
		.($$self{'PROTOCOL'} ne 'HTTP/0.9'?' '.$$self{'PROTOCOL'}:'');
}

sub proxyreq { undef }
sub header_only { (shift)->{'METHOD'} eq 'HEAD' }
sub protocol { (shift)->{'PROTOCOL'} }
sub hostname { (shift)->{'HOST'} }
sub request_time { (shift)->{'TIME'} }

sub uri {
	my ($self, $uri) = @_;
	$$self{'URI'} = $uri if defined $uri;
	$$self{'URI'};
}

sub filename {
	my ($self, $file) = @_;
	$$self{'FILE'} = $file if defined $file;
	$$self{'FILE'};
}

sub path_info {
	my ($self, $uri) = @_;
	$$self{'PATH_INFO'} = $uri if defined $uri;
	$$self{'PATH_INFO'};
}

sub args {
    my($self, $val) = @_;
    $$self{'ARGS'} = $val if defined $val;
    return $$self{'ARGS'} unless wantarray;
    return map { unescape_url_info($_) } split /[=&;]/, $$self{'ARGS'}, -1;
}

sub headers_in {
    my ($self, $key) = @_;
    if (wantarray) {
    	return %{$$self{'HEADERS_IN'}};
    } elsif (defined $key) {
    	return $$self{'HEADERS_IN'}{ucfirst(lc($key))};
    } else {
    	my $h = new Apache::Table(($self->headers_in));
    }
}

sub header_in {
    my ($self, $key, $val) = @_;
    $$self{'HEADERS_IN'}{ucfirst(lc($key))} = $val if defined $val;
    $$self{'HEADERS_IN'}{$key};
}

sub content {
    my ($self) = @_;
    if (exists $$self{'ENV'}{'CONTENT_LENGTH'} && $$self{'ENV'}{'CONTENT_TYPE'} eq 'application/x-www-form-urlencoded') {
	my $content;
	$self->read($content,$$self{'ENV'}{'CONTENT_LENGTH'});
	delete $$self{'ENV'}{'CONTENT_LENGTH'};
    	return $content unless wantarray;
    	return map { unescape_url_info($_) } split /[=&;]/, $content, -1;
    }
    undef;
}

sub read {
	my ($self, $buf, $cnt, $off) = @_;
    	my $content = '';
	$off ||= 0;
	$self->soft_timeout('read timed out');
	while ($cnt > 0) {
	    my $len = read(STDIN,$cnt,$off+length($buf));
	    $$self{'ABORTED'} = 1, die 'read error' if $len <= 0;
	    $cnt -= $len; # FIXME: is this neccesary?
	}
}

sub get_remote_host { my $self = shift; $self->{'REMOTE_HOST'} || $self->{'REMOTE_ADDR'} }
sub get_remote_logname { (shift)->{'REMOTE_IDENT'} }

sub connection { new Apache::Connection(@_) }

sub dir_config {
    my ($self, $key) = @_;
    if (wantarray) {
    	return %{$$self{'VAR'}};
    } elsif (defined $key) {
    	return $$self{'VAR'}{$key};
    } else {
    	my $h = new Apache::Table(($self->dir_config));
    }
}

sub requires { (shift)->{'REQUIRES'} }
sub auth_type { (shift)->{'AUTH_TYPE'} }
sub auth_name { 'default' }
sub document_root { (shift)->{'DOCUMENT_ROOT'} }
sub allow_options { -1 }
sub get_server_port { (shift)->{'LOCAL_PORT'} }

sub get_handlers {
	my ($self, $key) = @_;
 	@{$$self{'HANDLERS'}{$key}};
}
sub set_handlers {
	my ($self, $key, @rest) = @_;
 	@{$$self{'HANDLERS'}{$key}} = @rest;
}
sub push_handlers {
	my ($self, $key, $handler) = @_;
 	unshift @{$$self{'HANDLERS'}{$key}}, $handler;
}

sub send_http_header {
	my ($self,$cttype) = @_;
	return if (exists $$self{'HEADERS_SENT'});
	$$self{'HEADERS_OUT'}{'Content-type'} = $cttype || $$self{'CONTENT_TYPE'};
	$self->print($self->protocol." ".$self->status_line);
	#$self->warn($self->status_line);
	$self->print("\n");
	foreach my $header (keys %{$$self{'EHEADERS_OUT'}}) {
		$self->print($header.': '.$$self{'EHEADERS_OUT'}{$header}."\n");
		#$self->warn($header.': '.$$self{'EHEADERS_OUT'}{$header});
	}
	foreach my $header (keys %{$$self{'HEADERS_OUT'}}) {
		$self->print($header.': '.$$self{'HEADERS_OUT'}{$header}."\n");
		#$self->warn($header.': '.$$self{'HEADERS_OUT'}{$header});
	}
	$self->print("\n");
	$$self{'HEADERS_SENT'} = undef;
}

# these will never be implemented
sub get_basic_auth_pw { -1 }    # basic auth handled by webserver
sub note_basic_auth_failure { } # basic auth handled by webserver

sub handler { 'perl-script' } # TODO: maybe emulate some common handlers
sub notes {
	my ($self, $key, $value) = @_;
	if (@_ == 3) {
		$$self{'NOTES'}{$key} = ''.$value;
	} elsif (@_ == 1) {
		return %{$$self{'NOTES'}} if (wantarray);
		return new Apache::Table($$self{'NOTES'});
		
	}
	return $$self{'NOTES'}{$key};
}
sub pnotes {
	my ($self, $key, $value) = @_;
	if (@_ == 3) {
		$$self{'PNOTES'}{$key} = $value;
	} elsif (@_ == 1) {
		return %{$$self{'PNOTES'}} if (wantarray);
		return new Apache::Table($$self{'PNOTES'});
		
	}
	return $$self{'PNOTES'}{$key};
}

sub subprocess_env {
	my ($self, $key, $value) = @_;
	if (@_ == 3) {
		$$self{'ENV'}{$key} = $value;
	} elsif (@_ == 1) {
		return %{$$self{'ENV'}} if (wantarray);
		return new Apache::Table($$self{'ENV'});
		
	}
	return $$self{'ENV'}{$key};
}

sub content_type {
	my ($self, $ctt) = @_;
	$$self{'CONTENT_TYPE'} = $ctt if defined $ctt;
	$$self{'CONTENT_TYPE'};
}

sub content_encoding {
	my $self = shift;
	$self->header_out('Content-encoding',@_);
}

sub content_languages {
	my ($self, $vals) = @_;
	if (defined $vals) {
		return [split(/,\s*/,$self->header_out('Content-languages',join(',',@$vals)))];
	} else {
		return [split(/,\s*/,$self->header_out('Content-languages'))];
	}
}

sub status {
	my ($self, $status) = @_;
	$$self{'STATUS_CODE'} = $status if defined $status;
	$$self{'STATUS_CODE'};
}

sub status_line {
	my ($self, $line) = @_;
	$$self{'STATUS_LINE'} = $line if defined $line;
	if (exists $$self{'STATUS_LINE'}) {
		return $$self{'STATUS_LINE'};
	} else {
		return $$self{'STATUS_CODE'}.' '.HTTP::Status::status_message($$self{'STATUS_CODE'});
	}
	
}

sub headers_out {
	my ($self) = @_;
	return %{$$self{'HEADERS_OUT'}} if (wantarray);
	return new Apache::Table($$self{'HEADERS_OUT'});
}

sub header_out {
	my ($self, $key, $value) = @_;
	$$self{'HEADERS_OUT'}{$key} = $value if defined $value;
	$$self{'HEADERS_OUT'}{$key};
}

sub err_headers_out {
	my ($self) = @_;
	return %{$$self{'EHEADERS_OUT'}} if (wantarray);
	return new Apache::Table($$self{'EHEADERS_OUT'});
}

sub err_header_out {
	my ($self, $key, $value) = @_;
	$$self{'EHEADERS_OUT'}{$key} = $value;
}

sub no_cache {
	my ($self, $val) = @_;
	if ($val) {
		$self->header_out('Pragma','no-cache');
	} else {
		delete $$self{'HEADERS_OUT'}{'Pragma'};
	}
}

sub print {
	my $self = shift;
	foreach my $arg (@_) {
		$arg = $$arg if ref($arg) eq 'SCALAR';
	}
	CORE::print @_;
}

*CORE::GLOBAL::print = \&print;

sub rflush { flush STDOUT; flush STDERR; }

sub send_fd {
	my ($self, $fh) = @_;
	my $buf;
	while (CORE::read($fh,$buf,16384) > 0) {
		CORE::print $buf;
	}
}

sub internal_redirect {
	my ($self, $place) = @_;
	$self->warn("not implemented yet!");
	# TODO!
}

sub custom_response {
	my ($self, $uri) = @_;
	$self->warn("not implemented yet!");
	# TODO!
}

sub soft_timeout {
	my ($self, $message) = @_;
	$SIG{'ALRM'} = sub { $$self{'ABORTED'} = $message; };
	alarm(120);
}

sub hard_timeout {
	my ($self, $message) = @_;
	$SIG{'ALRM'} = sub { print STDERR $message,"\n"; exit(-1); };
	alarm(120);
}

sub kill_timeout {
	alarm(0);
}

sub reset_timeout {
	alarm(120);
}

sub post_connection {
	my ($self, $code) = @_;
	push @{$$self{'HANDLERS'}{'PerlCleanupHandler'}}, $code;
}

*register_cleanup = \&post_connection;

sub send_cgi_header {
	my ($self, $lines) = @_;
	my @lines = split(m/\s*\n\s*/,$lines);
	foreach my $line (@lines) {
		last if $line eq '';
		$self->header_out(($line =~ m/^([^:]+):\s*(.*)$/));
	}
	$self->send_http_header;
}

sub log_reason {
	my ($self, $reason, $file) = @_;
	$self->log_error("Failed: $file - $reason");
}

sub log_error {
	my ($self, $message) = @_;
	carp("$message");
}

sub warn {
	my ($self, $message) = @_;
	$self->log_error($message) if $$self{'LOG_LEVEL'} >= Apache::Log::WARNING;
}

sub unescape_url {
    my $string = shift;
    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $string;
}

sub unescape_url_info {
    my $string = shift;
    $string =~ s/\+/ /g;
    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $string;
}

my %hooks = (
#	'PostRead' => undef,
#	'Trans' => undef,
#	'HeaderParser' => undef,
#	'Access' => undef,
#	'Authen' => undef,
#	'Authz' => undef,
#	'Type' => undef,
#	'Fixup' => undef,
	'' => undef,
#	'Log' => undef,
#	'Cleanup' => undef,
#	'Init' => undef,
#	'ChildInit' => undef,
);

sub perl_hook { exists $hooks{shift} }

sub exit { shift; flush STDOUT; flush STDERR; exit(@_); }

package Apache::Fake;
use strict;
use Socket;
use Apache::Constants;
use Apache::ConfigFile;

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

sub new
{
    my ($caller, %conf) = @_;
    $conf{'dir_conf'} = '.htaccess' unless exists $conf{'dir_conf'};

    $ENV{'MOD_PERL'} = 'mod_perl/1.27';
    $ENV{'GATEWAY_INTERFACE'} = 'CGI-Perl/1.1';


    if (exists $conf{'handler_cgi'}) {
    	die 'virtual_root missing' unless exists $conf{'virtual_root'};
	$ENV{'PATH_TRANSLATED'} = $conf{'virtual_root'}.$ENV{'PATH_INFO'};
	$ENV{'PATH_INFO'} = $conf{'handler_cgi'}.$ENV{'PATH_INFO'};
    }

    # setup request parameters:
    # environment
    $conf{'ENV'} = {%ENV};

    # request URI
    $conf{'URI'} = #$conf{'ENV'}{'SERVER_NAME'}.
    	#($conf{'ENV'}{'SERVER_PORT'} != 80?':'.$conf{'ENV'}{'SERVER_PORT'}:'').
	$conf{'ENV'}{'PATH_INFO'};

    # physical filename
    $conf{'FILE'} = $conf{'ENV'}{'PATH_TRANSLATED'};
    while ($conf{'FILE'} && ! -e $conf{'FILE'}) {
    	$conf{'FILE'} =~ s/\/[^\/]*$//;
    }
    $conf{'FILE'} = '/' unless $conf{'FILE'};

    # (virtual) host name
    $conf{'HOST'} = $conf{'ENV'}{'SERVER_NAME'};

    # http method
    $conf{'METHOD'} = $conf{'ENV'}{'REQUEST_METHOD'};

    # http protocol
    $conf{'PROTOCOL'} = $conf{'ENV'}{'SERVER_PROTOCOL'};

    # path info
    $conf{'PATH_INFO'} = substr($conf{'ENV'}{'PATH_TRANSLATED'},length($conf{'FILE'}));
    $conf{'ENV'}{'PATH_INFO'} = $conf{'PATH_INFO'};

    # time
    $conf{'TIME'} = time();

    # result status
    $conf{'STATUS_CODE'} = 200;

    # cleanup
    $conf{'CLEANUP'} = [];

    # log level
    $conf{'LOG_LEVEL'} = Apache::Log::INFO;

    # args
    $conf{'ARGS'} = $conf{'ENV'}{'QUERY_STRING'};

    # notes
    $conf{'NOTES'} = {};
    $conf{'PNOTES'} = {};

    # remote host
    $conf{'REMOTE_HOST'} = $conf{'ENV'}{'REMOTE_HOST'};

    # authentication information
    $conf{'USER'} = $conf{'ENV'}{'REMOTE_USER'};
    $conf{'AUTH_TYPE'} = $conf{'ENV'}{'AUTH_TYPE'};

    # ip addresses/ports
    my $sa;
    if ($sa = getsockname(STDIN)) {
    	($conf{'LOCAL_PORT'}, $conf{'LOCAL_ADDR'}) = sockaddr_in($sa);
    	$conf{'LOCAL_ADDR'} = inet_ntoa($conf{'LOCAL_ADDR'});
    } else {
    	$conf{'LOCAL_ADDR'} = gethostbyname($conf{'HOST'});
	$conf{'LOCAL_PORT'} = $conf{'ENV'}{'SERVER_PORT'};
    }

    if ($sa = getpeername(STDIN)) {
    	($conf{'REMOTE_PORT'}, $conf{'REMOTE_ADDR'}) = sockaddr_in($sa);
    	$conf{'REMOTE_ADDR'} = inet_ntoa($conf{'REMOTE_ADDR'});
    } else {
	$conf{'REMOTE_ADDR'} = $conf{'ENV'}{'REMOTE_ADDR'};
	$conf{'REMOTE_PORT'} = -1;
    }

    # connection
    $conf{'ABORTED'} = 0;
    $conf{'FD_IN'} = fileno(STDIN);
    $conf{'FD_OUT'} = fileno(STDOUT);

    # remote ident
    $conf{'REMOTE_IDENT'} = $conf{'ENV'}{'REMOTE_IDENT'};

    # headers
    my %headers;
    foreach my $hdr (keys %ENV) {
    	if ($hdr =~ m/^HTTP_(.*)$/) {
    		my $name = ucfirst(lc($1));
    		$name =~ s/_/-/g;
		$headers{$name} = $conf{'ENV'}{$hdr};
	}
    }
    $conf{'HEADERS_IN'} = \%headers;

    $conf{'HEADERS_OUT'} = {};
    $conf{'CONTENT_TYPE'} = 'text/plain';

    $conf{'EHEADERS_OUT'} = {};

    # get settings from config file(s)
    my @modules;
    my $vars = new Apache::Table();
    my $handlers = {};
    my $docroot;
    my $admin;
    my $aliases = [];
    my $requires = [];

    my $ctx;
    my $loc;
    my $rest;
    my $addContext = sub {
	return unless $ctx;
	push @modules, map { join(" ",@{$_}) } $ctx->cmd_config_array('PerlModule');
	#$self->warn("modules: ").join(",",@modules)."\n";
	%$vars = (%$vars, $ctx->cmd_config_hash('PerlSetVar'));
	foreach my $var ($ctx->cmd_config_array('PerlAddVar')) {
		#$self->warn("adding @$var\n");
		$vars->add(@$var);
	}
	# TODO: more Perl*Handlers
	($$handlers{'PerlHandler'}) = map { @{$_} } $ctx->cmd_config_array('PerlHandler') if $ctx->cmd_config_array('PerlHandler');
	($docroot) = map { @{$_} } $ctx->cmd_config_array('DocumentRoot') if $ctx->cmd_config_array('DocumentRoot');
	($admin) = map { @{$_} } $ctx->cmd_config_array('ServerAdmin') if $ctx->cmd_config_array('ServerAdmin');
	$aliases = [ map { @{$_} } $ctx->cmd_config_array('ServerAlias') ] if $ctx->cmd_config_array('ServerAlias');
	$requires = [ map { @{$_} } $ctx->cmd_config_array('requires') ] if $ctx->cmd_config_array('requires');
    };

    $conf{'VIRTUAL'} = 0;

    if (exists $conf{'httpd_conf'}) {
	$ctx = Apache::ConfigFile->read($conf{'httpd_conf'});
	&$addContext;

	my $ctx2 = $ctx;
	$ctx = $ctx->cmd_context(ServerName => $conf{'ENV'}{'SERVER_NAME'});
	$conf{'VIRTUAL'} = 1 if ($ctx && $ctx2 ne $ctx);
	&$addContext;

	$loc = '/';
	$rest = substr($conf{'ENV'}{'PATH_INFO'},1);

	$ctx = $ctx->cmd_context(Location => '/');
	&$addContext;

	while (length($rest)) {
		$rest =~ s/^(\/*[^\/]*)//;
		$loc .= $1;
		$ctx = $ctx->cmd_context(Location => $loc);
		&$addContext;
	}

	$loc = '/';
	$rest = $conf{'FILE'};

	$ctx = $ctx->cmd_context(Directory => '/');
	&$addContext;

	while (length($rest)) {
		$rest =~ s/^(\/*[^\/]*)//;
		$loc .= $1;
		$ctx = $ctx->cmd_context(Directory => $loc);
		&$addContext;
	}
    }

    my $dconf = $conf{'dir_conf'};
    $loc = '/'.$dconf;
    $rest = $conf{'FILE'};

    if (-f $loc) {
    	$ctx = Apache::ConfigFile->read($loc);
    	&$addContext;
    }

    while (length($rest)) {
	$rest =~ s/^(\/*[^\/]*)//;
	my $next = $1;
	$loc =~ s/\/$dconf$/$next\/$dconf/;
	next unless -f $loc;
	$ctx = Apache::ConfigFile->read($loc);
	&$addContext;
    }

    # document root
    $conf{'DOCUMENT_ROOT'} = $docroot;

    # PerlSetVar/PerlAddVar
    $conf{'VAR'} = $vars;
    #$self->warn("Vars: ").join(",",keys %$vars),"\n";

    # server admin
    $conf{'ADMIN'} = $admin;

    # access restrictions
    $conf{'REQUIRES'} = $requires;

    # server aliases
    $conf{'ALIASES'} = $aliases;

    # handlers
    $conf{'HANDLERS'} = $handlers;

    # create request object
    my $class = ref($caller) || $caller;

    my $r = bless {%conf}, 'Apache';

    Apache->request($r);

    # load PerlModules
    foreach my $mod (@modules) {
	eval('require '.$mod);
    	die ($@) if $@;
    }

    die 'no PerlHandler found, but we have: '.join(keys %$handlers) unless exists $$handlers{'PerlHandler'};

    my $eval_string = $$handlers{'PerlHandler'};
    if ($eval_string =~ m/->/) {
	$eval_string .= '($r)';
    } elsif ($eval_string =~ m/^[a-zA-Z_0-9:]+$/) {
	$eval_string .= '::handler($r)';
    } elsif ($eval_string !~ m/[{&]/) {
	die "unknown handler syntax: $eval_string";
    }

    %ENV = %{$conf{'ENV'}};

    #$r->warn("invoking: $eval_string");
    my $rc = eval($eval_string);
    die ($@) if $@;
    #$r->warn("rc = $rc");
    $r->status($rc) if $rc;
    $r->send_http_header;

    return $r;
}

1;
