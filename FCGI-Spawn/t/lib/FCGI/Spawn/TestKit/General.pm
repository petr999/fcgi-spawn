package FCGI::Spawn::TestKit::General;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Spawnable' );

use Carp;

use FCGI::Spawn::TestUtils;

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  my $conf_presets = retr_conf_presets();
  my $general_preset = $$conf_presets{ 'general' };
  my @kits = ();
  while( my( $kit => $preset, ) = each( %$conf_presets ) ){
    if( [ %$preset ] ~~ [ %$general_preset ] ){ push(  @kits => $kit, ); }
  }
  my %seen_tests = ();
  foreach my $kit( @kits ){
    next if grep { $_ eq $kit } qw/general/;
    $seen_tests{ $kit } = 1;
  }
  @kits = keys %seen_tests;
  my @tests = ();
  foreach my $kit( @kits ){
    my $kit_obj = FCGI::Spawn::TestKit::retr_obj_by_name( $kit );
    my $tests_list = $kit_obj -> get_tests;
    push( @tests => @$tests_list, );
  }
  %seen_tests = ();
  foreach my $test( @tests ){
    next if grep { $_ eq $test } qw/spawn unspawn/;
    $seen_tests{ $test } = 1;
  }
  @tests = grep{ 'general' ne $_ }
    ( @{ $self -> SUPER::init_tests_list } => keys( %seen_tests ), );
  return \@tests;
}

1;
