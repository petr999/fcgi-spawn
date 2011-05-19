package FCGI::Spawn::Tests::XStatsDependence;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has( '+descr' => ( 'default' => 'x_stats templates recompilation by dependence', ) );

sub make_cgi{
  my( $self => $name, $cgi => $cgi_dir, ) = @_;
  my $tmpl_fn = join '/', $cgi_dir => 'xsd_changeable.tmpl';
  $self -> write_file_contents( \$name => $tmpl_fn, );
}

1;
