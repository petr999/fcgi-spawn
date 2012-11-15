#!/usr/bin/perl

package FCGI::Spawn::ConfigFile;

use Mouse;

use FindBin;
use Cwd qw/realpath/;
use Readonly;

# FIXME: MooseX::FollowPBP


my Readonly $CONFIG_BASENAME = 'fcgi_spawn.conf';
my Readonly %PROPERTIES = ( qw/
    sock_chown              ArrayRef      sock_chmod Str
    maxlength               Int           max_requests     Int
    stats                   Bool          stats_policy     ArrayRef
    x_stats                 Bool          x_stats_policy   ArrayRef
    clean_inc_hash          Int           clean_main_space Bool
    clean_inc_subnamespace  Any           callout          CodeRef
    procname                Bool          save_env         Bool
  /,
  # not a config but should be passed to FCGI::Spawn->new
  qw/
    pid_callouts            HashRef
  / );

while( my( $property, $is_a ) = each %PROPERTIES ){
  has $property  => ( qw/is rw     isa/, $is_a, );
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
      if( defined $PROPERTIES{ $key } ){
        $self->$key( ( @val > 1 ) ? \@val : shift @val );
      } else {
        $self->{ $key } = shift @val ; # FCGI::ProcManager constructs from scalar values only
      }
    }
  }
  close $fcgi_config_fh;
}

__PACKAGE__->meta->make_immutable();

1;
