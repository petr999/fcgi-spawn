package FCGI::Spawn::Tests::XStats;

use Moose;
use MooseX::FollowPBP;

use Carp;

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has( '+descr' => ( 'default' => 'x_stats templates recompilation', ) );

__PACKAGE__->meta->make_immutable;

sub make_cgi{
  my( $self => $name, $cgi => $cgi_dir, ) = @_;
  my $tmpl_fn = join '/', $cgi_dir => 'x_stats.tmpl';
  my $tmpl_contents = \"%s$name";
  $self -> write_file_contents( $tmpl_contents => $tmpl_fn, );
}

1;
