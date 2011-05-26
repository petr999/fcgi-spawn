package FCGI::Spawn::TestKit::Spawnable;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Test::More;
use Try::Tiny;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestKit::Utilized', );

augment( 'testify' => \&unspawn_if_pid, );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  croak unless my $class = ref( $self );
  my $name = $class -> make_name_from_class;
  my $rv =  [ 'spawn' => $name, ];
  return $rv;
}

sub spawn{
  my $self = shift;
  my $name = $self -> get_name;
  my $util = $self -> get_util;
  my $rv = 0;
  ok( my $ppid = get_fork_pid( $util -> spawn_fcgi )
    => "Spawner initialisation named '$name'" );
  if( ok( ( my $pid = $util -> read_pidfile( $ppid ) ) => "FCGI Spawned: pid $ppid", ) ){
    $util -> set_pid( $pid );
    $rv = 1;
  }
  return ( $rv => not $rv, );
}

sub unspawn{
  my $self = shift;
  my $util = $self -> get_util or croak( "No Fcgi Spawned to unspawn!", );
  my $rv = 0;
  my $pid = $util -> get_pid or croak( "No Fcgi PID spawned!", );
  ok( $rv = $self -> stop_serv => 'Stopping spawn', )
    or croak( "Can not stop pid: $pid" );
  $util -> set_pid( 0 );
  return ( $rv => not $rv, );
}

sub unspawn_if_pid{
  my $self = shift;
  my $meta = $self -> meta;
  if( defined $meta -> find_attribute_by_name( 'util' ) ){
    my $util = $self -> get_util;
    if( defined( $util ) ){
      my $pid = $util ->get_pid;
      if( defined( $pid ) and $pid > 0 ){
        try{ $self -> unspawn;
          } catch { diag( "No unspawn: $_", );
        }
      }
    }
  }
}

sub stop_serv{
  my $self = shift;
  my $util = $self -> get_util;
  my $pid = $util -> get_pid;
  $util -> kill_procsock;
}

1;
