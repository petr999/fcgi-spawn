#!/usr/bin/perl

package FCGI::Spawn::ConfigFile;

use FindBin;
use Cwd qw/realpath/;
use Const::Fast;

use Moose;
use MooseX::FollowPBP;

use FCGI::Spawn::BinUtils qw/make_shared/;


const my $CONFIG_BASENAME => 'fcgi_spawn.conf';
const my %PROPERTIES => ( qw/
    sock_chown              ArrayRef      sock_chmod Str
    maxlength               Int           max_requests     Int
    stats                   Bool          stats_policy     ArrayRef
    x_stats                 Bool          x_stats_policy   ArrayRef
    clean_inc_hash          Int           clean_main_space Bool
    clean_inc_subnamespace  Any           callout          CodeRef
    procname                Bool          save_env         Bool
    chroot_path             Str
  /,
  # not a config but may be passed to FCGI::Spawn->new
  qw/
    time_limit              Int           
    pid_callouts            HashRef
    sock_name               Str
  / );

while( my( $property, $is_a ) = each %PROPERTIES ){
  has(  $property  => ( 'is' => 'rw', 'isa' => $is_a, ) );
}

sub read_fsp_config_file {
  my $self = shift;
  my( $config_path, $config_file );
  $config_path = @_ ? shift : realpath "$FindBin::Bin/../etc";
  $config_file = "$config_path/$CONFIG_BASENAME";
  $self->read_fsp_config_file_by_name( $config_file );
}
sub read_fsp_config_file_by_name {
  my( $self, $config_file ) = @_;
  open( my $fcgi_config_fh, "<", $config_file ) or die "Opening $config_file: $!";
  while( <$fcgi_config_fh> ){
    next if /^\s*(#|$)/;
    chomp; s/^\s+|\s+$//g;
    if( my( $key, @val ) = split /\s+/, ){
      my $method_name = "set_$key";
      has(  $key  => ( 'is' => 'rw', 'isa' => 'Item', ) );
      $self->$method_name( ( @val > 1 ) ? \@val : shift @val );
    }
  }
  close $fcgi_config_fh;
}

# TBD __PACKAGE__->meta->make_immutable();

1;
