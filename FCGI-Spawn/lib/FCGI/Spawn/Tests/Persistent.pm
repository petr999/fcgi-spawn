package FCGI::Spawn::Tests::Persistent;

use Moose;
use MooseX::FollowPBP;

use JSON;
use Carp;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests::Multiple' );

has( 'state' => ( qw/is rw/, ) );
has( qw/sngl_chng   is ro isa Bool required 1 default 1/, );

augment( 'parse' => \&enparse, );

sub enparse{
  my( $self, ( $out => $err, ), ) = @_;
  my $rv;
  if( $self -> is_state_saved ){
    $rv = $self->compare( $out );
  } else {
    if( $self->get_sngl_chng ){ $self -> change_persistence( $out ); 
    } else { $self -> set_state( $out ); }
    $rv = 1;
  }
  $rv;
}

sub compare{
  my( $self, $new_state ) = @_;
  my $old_state = $self -> get_state;
  my $rv = $old_state ~~ $new_state;
  unless( $rv ){ my $failure = $self -> errmsg( $new_state );
    $self -> set_failure( $failure );
  }
  $rv;
}

sub errmsg{
  my( $self, $new_state ) = @_;
  my $old_state = $self -> get_state;
  my( @olds, @news );
  my $os_ref = ref $old_state;
  my $ns_ref = ref $new_state;
  if( 'HASH' eq $os_ref ){
    @olds = %$old_state;
  } elsif( 'ARRAY' eq $os_ref ){
    @olds = @$old_state;
  } else {
    croak( "Bad old state: $old_state" );
  }
  if( 'HASH' eq $ns_ref ){
    @news = %$new_state;
  } elsif( 'ARRAY' eq $os_ref ){
    @news = @$new_state;
  } else {
    croak( "Bad newstate: $new_state" );
  }
  my %count = ();
  foreach my $elem( @olds, @news, ){
    $count{ $elem } ++;
  }
  my @diff = ();
  foreach my $elem( keys %count ){
    push( @diff, $elem ) if $count{ $elem } == 1;
  }
  my $err = ( @diff > 0 ) ? '' : "State difference: ".join ' ', @diff;
  return $err;
}

sub is_state_saved{
  my $self = shift;
  my $state = $self -> get_state;
  my $rv;
  my $ref = ref $state;
  if( defined( $ref ) and length $ref ){
    if( 'HASH' eq $ref ){
      $rv = keys( %$state ) > 0;
    } elsif( 'ARRAY' eq $ref ){
      $rv = @$state > 0;
    } else {
      croak( "Wrong state saved: $ref" );
    }
  } else {
    $rv = 0;
  }
  $rv;
}

1;
