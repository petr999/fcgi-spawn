#!/usr/bin/perl

package FCGI::Spawn::ConfigFile;

use strict;
use warnings;

use FindBin;
use Cwd qw/realpath/;
use Const::Fast;
use Carp;

use FCGI::Spawn::BinUtils qw/make_shared/;

const my $CONFIG_BASENAME => 'fcgi_spawn.conf';

sub new{ bless {} => shift; }

sub read_fsp_config_file {
  my $self = shift;
  my( $config_path, $config_file );
  $config_path = shift || realpath "$FindBin::Bin/../etc/fcgi_spawn";
  $config_file = "$config_path/$CONFIG_BASENAME";
  $self->read_fsp_config_file_by_name( $config_file );
}

sub read_fsp_config_file_by_name {
  my( $self, $config_file ) = @_;
  croak( "Opening $config_file: $!" )
    unless open( my $fcgi_config_fh, "<", $config_file );
  while( <$fcgi_config_fh> ){
    next if /^\s*(#|$)/;
    chomp; s/^\s+|\s+$//g;
    if( my( $key => @val, ) = split /\s+/, ){
      $self ->assign_pair( $key => \@val, $config_file, );
    }
  }
  close $fcgi_config_fh;
}

sub assign_pair{
  my $self = shift;
  my( $key => $val, $config_file ) = @_;
    $self->{ $key } = ( @$val > 1 ) ? $val : shift @$val;
}

1;
