package FCGI::Spawn::TestKit::General;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit' );

use FCGI::Spawn::TestUtils;

sub init_tests_list{
  my $conf_presets = retr_conf_presets();
  my @kits = ();
  while( my( $kit => $preset, ) = each( %$conf_presets ) ){
    if( $preset ~~ { 'conf' => '', } ){ push(  @kits => $kit, ); }
  }
  my @tests = ();
  foreach my $kit( @kits ){
    my $class = $self -> make_class_name();
  }
}

1;
