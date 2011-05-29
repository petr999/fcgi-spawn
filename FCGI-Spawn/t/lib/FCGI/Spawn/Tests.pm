package FCGI::Spawn::Tests;

use Moose;
use MooseX::FollowPBP;

use Try::Tiny;
use Test::More;

has( qw/failure    is rw   isa Str    default/ => '', );
has( qw/mandatory    is ro   isa Bool   required 1    default 0/, );
has( qw/name    is ro   required 1    isa Str   builder init_name/, );
has( qw/descr    is rw    isa Str/, );
has( qw/rand_max    is ro   isa Int   default 4294967295/ );
has( qw/util    is ro   isa FCGI::Spawn::TestUtils    required 0/, );

__PACKAGE__->meta->make_immutable;

sub init_name{ # ::Cgi use this sub for cgi's name
  my $self = shift;
  my $class = ref( $self ) ? ref( $self ) : $self;
  my $name = pop @{ [ split /::/, scalar $class ] };
  $name =~ s/(.)([A-Z])/$1_$2/g;
  $name = lc $name; 
}

sub check_out{
  my $self = shift;
  my( $rv => $fatal, ) = ( 0 => 0, );
  $rv = $self -> check();
  $fatal = ( $self -> get_mandatory and not $rv );
  ( $rv => $fatal, );
}

sub check{
  croak( 'Method must be implemented in a descendant class' );
}

1;
