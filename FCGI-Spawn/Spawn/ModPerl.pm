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
} qw/Apache2::Response Apache2::RequestRec Apache2::RequestUtil Apache2::RequestIO APR::Pool/;

1;

package Apache::Request;
use strict;
use warnings;

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
    return $r;
  # $SUPER::new copy end
}

1;

package Apache;
use strict;
use warnings;

sub cleanup_register {
    my( $self, $cref ) = @_;
    &$cref;
}

sub pool {
    return shift->request;
}

1;

package Apache2::RequestUtil;
use base qw/Apache::Request/;

# *request = *__PACKAGE__::new;
sub request{
  Apache::Request::new( @_ );
}

1;
