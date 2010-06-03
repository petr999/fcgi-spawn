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
  /;

1;

package Apache::Request;
use strict;
use warnings;

our @ISA = qw/Apache Apache::Connection/;

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

sub pool {
    return shift->request;
}

sub cleanup_request{
  undef $request;
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

sub server{
  bless {}, shift;
}
sub add_config{
}

1;

package ModPerl::Registry;
use strict;
use warnings;

1;

package Apache2::Const;
use strict;
use warnings;

use base qw/Apache::Constants/;

use constant OK => Apache::Constants::OK;

sub import{
  if( $_[ 0 ] eq '-compile' ){
    shift;
  }
}

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

1;
