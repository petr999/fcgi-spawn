package FCGI::Spawn::Tests::ConfigFile;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use FindBin;
use Cwd qw/realpath/;

use FCGI::Spawn::ConfigFile;
use FCGI::Spawn::ConfigFile::Moose;

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'Trying to read config file', ), );

__PACKAGE__->meta->make_immutable;

sub check{ 
  my $self = shift;
  my $conf;
  my $rv = 1;
  foreach my $sfx ( '' => 'Moose', ){
    my $class = "FCGI::Spawn::ConfigFile";
    if( length( $sfx ) ){ $class .= "::$sfx"; }
    if( $rv &&= ok( $conf = $class->new() => 'Config file object creation', ) ){
      my $descr = $self -> get_descr; $descr .= " with $sfx";
      my $config_path = realpath "$FindBin::Bin/../t/etc-test/clean_inc_sub_ns";
      $rv = ok( $conf->read_fsp_config_file( $config_path ) => $descr, );
      ok( $conf->{ 'clean_inc_subnamespace' } ~~ [ qw/CleanIncSubNs StatsCisns/ ], 'Array reading' );
      is( $conf->{ stats } => 0, 'Number reading' );
    }
  }
  return $rv;
}

1;
