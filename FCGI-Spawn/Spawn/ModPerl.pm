package Apache::ConfigFile;

use strict;
use warnings;

BEGIN{
  $INC{ 'Apache/ConfigFile.pm' } = $INC{ 'FCGI/Spawn/ModPerl.pm' };
}

1;


package FCGI::Spawn::ModPerl;


use strict;
use warnings;

use base qw/Apache::Fake/;

my $inc_key = __PACKAGE__; $inc_key =~ s%::%/%g; $inc_key .= '.pm';

map{
  if( ( $_ ne 'Apache/Fake.pm' )
      and ( $INC{ $_ } eq $INC{'Apache/Fake.pm'} )
    ){
    $INC{ $_ } = $INC{ $inc_key };
  }
} keys %INC;

map{ my $mod = $_; $mod =~ s%::%/%g; $mod .= '.pm'; $INC{ $mod } = $INC{ $inc_key };
} qw/Apache2::Response Apache2::RequestRec Apache2::RequestUtil Apache2::RequestIO APR::Pool APR::Table
      Apache2::SizeLimit ModPerl::RegistryLoader ModPerl::Registry Apache2::Const ModPerl ModPerl::Util
      Apache::Cookie Apache2::Cookie APR::Request APR::Request::Apache2 Apache2::Request ModPerl::Const
      APR::Date Apache2::Upload
  /;

1;

package Apache::Request;
use strict;
use warnings;

use Exporter;

our @ISA = qw/Apache Apache::Connection Exporter/;

our $VERSION = '2.10';

use CGI;

sub new{
  my $cgi_mod_perl = $CGI::MOD_PERL;
  # SUPER::new copy begin
    my ($caller, $r, %options) = @_;
    my $class = ref($caller) || $caller;
    return Apache->request if ref(Apache->request) eq $class;

    $CGI::POST_MAX = $options{'POST_MAX'} || 0;
    $CGI::DISABLE_UPLOADS = $options{'DISABLE_UPLOADS'} || 0;
    $r->warn('Upload hooks not implemented') if $options{'UPLOAD_HOOK'};
    $ENV{'TMPDIR'} = $options{'TEMP_DIR'} if $options{'TEMP_DIR'};
    $CGI::MOD_PERL = 0;
    CGI->_reset_globals;
    my $q = $$r{'CGI'} = new CGI;
    $CGI::MOD_PERL = $cgi_mod_perl;
    $$r{'UPLOADS'} = { map { $_ => undef } grep { my $x; $x = $q->param($_) && ref($x) && fileno($x) } $q->param };

    $r = bless $r, $class;
    Apache->request($r);
    map{ $r->{ $_ } = {}; } qw/NOTES PNOTES/;
    return $r;
  # $SUPER::new copy end
}

1;

package Apache;
use strict;
use warnings;

my $request;

sub request
{
    my ($caller, $r) = @_;
    $request = $r if defined $r;
    $request || FCGI::Spawn::ModPerl->new;
}
sub pool {
    return shift->request;
}
sub cleanup_request{
  undef $request;
  CGI->_reset_globals;
}
sub pnotes {
	my ($self, $key, $value) = @_;
	if (@_ == 3) {
		$$self{'PNOTES'}{$key} = $value;
	} elsif (@_ == 1) {
		return $$self{'PNOTES'} if 'Apache::Table' eq ref $$self{'PNOTES'};
		return new Apache::Table($$self{'PNOTES'});
	}
	return $$self{'PNOTES'}{$key};
}

sub post_connection {
	my ($self, $code) = @_;
	push( @{$$self{'HANDLERS'}{'PerlCleanupHandler'}}, $code )
    unless grep{ $code eq $_ } @{$$self{'HANDLERS'}{'PerlCleanupHandler'}};
}
*register_cleanup = \&post_connection;
*cleanup_register = *register_cleanup;

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
sub dir_config {
  my ($self, $key) = @_;
  if (defined $key) {
    return $$self{'VAR'}{$key};
  } elsif (wantarray) {
    return %{$$self{'VAR'}};
  } else {
    my $h = new Apache::Table(($self->dir_config));
  }
}
sub param { 
  my $self = shift;
  my @param;
  if( wantarray ){
    @param = $self->{'CGI'}->param(@_);
  } else {
    if( @_ > 0 ){
      my $param = $self->{'CGI'}->param(@_);
      @param = ( $param );
    } else {
      return $self->{'CGI'}->Vars;
    }
  }
  unless( @param > 0 ){
    if( $self->method eq "POST" ){
      @param = $self->{'CGI'}->url_param(@_);
    }
  }
  return wantarray? @param : shift @param;
}

1;

package Apache2::RequestUtil;
use strict;
use warnings;
use base qw/Apache::Request Apache::Connection/;

sub request{
  $_[ 1 ] = Apache->request;
  shift->new( @_ );
}
1;

package APR::Table;
use strict;
use warnings;

use base qw/Apache::Table/;

1;

package Apache::Table;
use strict;
use warnings;

sub new{
    my $caller = shift;
    if( @_ ){
      if( @_ % 2 ){
        if( not defined $_ [ 0 ] ){
          $_[ 0 ] = '';
        }
        push @_, undef;
      }
    }
    my %content = @_;
    my $class = ref($caller) || $caller;
    return bless( $_[0], $class ) if 'HASH' eq ref $_[0];

    return bless {%content}, $class;
}
sub set{
  my $self = shift;
  $self->{ shift } = shift;
}

1;

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

1;

package Apache2::ServerUtil;
use strict;
use warnings;

use base qw/Apache::Server/;

use FCGI::Spawn::ModPerl;

sub server{
  my $caller = shift;
  my $request = Apache::Request->request;
  $caller->SUPER::new( $request );
}
sub add_config{
}
sub add_version_component{
}

1;

package ModPerl::Registry;
use strict;
use warnings;

1;

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

1;

package ModPerl::Const;
use strict;
use warnings;

use Apache::Constants qw/:common :http/;

1;

package ModPerl;
use strict;
use warnings;

use base qw/Apache/;

1;

package ModPerl::Util;
use strict;
use warnings;

use base qw/ModPerl/;

use FCGI::Spawn::ModPerl;

sub exit{
  exit;
}

1;

package Apache::Cookie;
use strict;
use warnings;

use base qw/CGI::Cookie/;

1;

package Apache2::Cookie;
use strict;
use warnings;

use base qw/Apache::Cookie/;

1;

package Apache2::RequestRec;
use strict;
use warnings;

use base qw/Apache::Request/;

1;

package Apache2::Cookie;
use strict;
use warnings;

use base qw/CGI::Cookie/;

1;

package Apache2::Request;
use strict;
use warnings;

use base qw/Apache::Request/;

our $VERSION = '2.10';

1;

package APR::Date;
use strict;
use warnings;

use HTTP::Date qw/str2time/;

sub parse_http{
  return 1000000*str2time shift;
}

1;

package APR::Request;
use strict;
use warnings;

use base qw/Apache2::Request/;

sub jar{
  my $cookies = Apache2::Cookie->new->fetch;
  my $rv = { map{
      $_ =>
      $cookies->{ $_ }->value;
    } keys %$cookies
  };
  return $rv;
}
*param = *Apache::param;

1;

package APR::Request::Apache2;
use strict;
use warnings;

use base qw/APR::Request/;

sub handle{
  return bless $_[ 1 ], $_[ 0 ];
}

1;

package Apache2::Upload;
use strict;
use warnings;

use base qw/Apache::Upload/;

1;
