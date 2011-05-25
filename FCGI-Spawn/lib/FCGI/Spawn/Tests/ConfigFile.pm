package FCGI::Spawn::Tests::ConfigFile;

use Moose;
use MooseX::FollowPBP;

use Test::More;

use FCGI::Spawn::ConfigFile;

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'Trying to read config file', ), );

__PACKAGE__->meta->make_immutable;

sub check{ 
  my $self = shift;
  my $conf;
  my $rv = 0;
  if( ok( $conf = FCGI::Spawn::ConfigFile->new()
        => 'Config file object creation', )
    ){
    my $descr = $self -> get_descr;
    $rv = ok( $conf->read_fsp_config_file() => $descr, );
  }
  return $rv;
}

1;
