package FCGI::Spawn::TestKit::Utilized;

use Moose;
use MooseX::FollowPBP;

use Test::More;
use Try::Tiny;

use FCGI::Spawn::TestUtils;


extends( 'FCGI::Spawn::TestKit' );

has( qw/util    is rw   isa/ => 'FCGI::Spawn::TestUtils', );

override( 'BUILDARGS' => \&override_buildargs, );
augment( 'testify' => \&unspawn_if_pid, );

__PACKAGE__->meta->make_immutable;

sub override_buildargs{
  my $class = shift;
  my $args = super();
  my $name = $$args{ 'name' };
  my $util = FCGI::Spawn::TestUtils -> new( $name );
  $$args{ 'util' } = $util;
  $args;
}

sub test_obj{
  my( $self, $class ) = @_;
  my $util = $self -> get_util;
  my $obj = $self -> SUPER::test_obj( $class => ( 'util' => $util, ), );
}

sub spawn{
  my $self = shift;
  my $name = $self -> get_name;
  my $util = $self -> get_util;
  my $rv = 0;
  ok( my $ppid = get_fork_pid( $util -> spawn_fcgi )
    => "Spawner initialisation named '$name'" );
  if( ok( ( my $pid = $util -> read_pidfile( $ppid ) ) => 'FCGI Spawned', ) ){
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

sub stop_serv{
  my $self = shift;
  my $util = $self -> get_util;
  my $pid = $util -> get_pid;
  $util -> kill_procsock;
}

sub unspawn_if_pid{
  my $self = shift;
  my $meta = $self -> meta;
  if( defined $meta -> find_attribute_by_name( 'util' ) ){
    my $util = $self -> get_util;
    if( defined( $util ) ){
      my $pid = $util ->get_pid;
      if( defined( $pid ) and $pid > 0 ){
        try{
          $self -> unspawn;
        } catch {
          diag( "No unspawn: $_", );
        }
      }
    }
  }
}

1;
