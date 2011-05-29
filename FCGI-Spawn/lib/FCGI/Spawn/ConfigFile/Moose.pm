#!/usr/bin/perl

package FCGI::Spawn::ConfigFile::Moose;

use Moose;
use MooseX::FollowPBP;

use FindBin;
use Cwd qw/realpath/;
use Const::Fast;
use Carp;

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
    chroot_path             Str           acceptor         Str
    time_limit              Int           sock_name        Str
    mod_perl                Int
  /,
  # not a config but may be passed to FCGI::Spawn->new
  qw/
    pid_callouts            HashRef       n_processes             Int
  / );

while( my( $property, $is_a ) = each %PROPERTIES ){
  has(  $property  => ( 'is' => 'rw', 'isa' => $is_a, ) );
}

extends( 'FCGI::Spawn::ConfigFile', );

__PACKAGE__->meta->make_immutable( 'replace_constructor' => 1, );

sub assign_pair{
  my $self = shift;
  my( $key => $val, $config_file ) = @_;
  if( defined $self -> meta -> find_attribute_by_name( $key ) ){
    my $method_name = "set_$key";
    $self->$method_name( ( @$val > 1 ) ? $val : shift @$val );
  } else { croak( "Unknown attribute defined in $config_file: $key" ); }
}

1;
