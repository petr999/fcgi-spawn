package FCGI::Spawn::Tests::Fixed;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Cgi' );

has( qw/test_var    is ro isa Ref   required 1 builder init_test_var/ );

sub enparse{
  my( $self => ( $out => $err, ), ) = @_;
  my $test_var = $self -> get_test_var;
  $out ~~ $test_var;
}

1;
