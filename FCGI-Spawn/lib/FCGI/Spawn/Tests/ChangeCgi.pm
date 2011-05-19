package FCGI::Spawn::Tests::ChangeCgi;

use Moose;
use MooseX::FollowPBP;

use Carp;
use File::Slurp;
use File::Basename qw/dirname/;
use Sub::Name;

extends( 'FCGI::Spawn::Tests::Persistent', );

has( '+state' => ( qw/isa ArrayRef[Str]/, ) );
has( qw/cmp_vals    is ro isa ArrayRef[Str] required 1 builder init_cmp_vals/, );
has( qw/temp_files    is rw isa ArrayRef[Str]    default/
  => subname( 'init_temp_files' => sub{ []; }, ), );

augment( 'enparse' => \&change_cgi, );
override( 'check' => \&check_and_clean_temp_files );

sub BUILD{
  my $self = shift;
  $self -> orig_cgi;
}

sub check_and_clean_temp_files {
  my $self = shift;
  my $rv = super();
  $self -> clean_temp_files;
  return $rv;
}

sub clean_temp_files{
  my $self = shift;
  my @temp_files = ( @{ $self -> get_temp_files } );
  while( my $fn = pop @temp_files ){
    croak( "Deleting temporary file $fn: $!", ) unless unlink( $fn, ) ;
    $self -> set_temp_files( [ @temp_files, ], );
  }
}

sub init_cmp_vals{
  return [ qw/ORIG CHNG/, ];
}    

sub orig_cgi{
  my $self = shift;
  my $name = $self -> get_cmp_vals -> [ 0 ];
  $self -> write_cgi( $name );
}

sub change_persistence{
  my( $self, $decoded ) = @_;
  my $cmp_vals = $self -> get_cmp_vals;
  my $orig_name = $$cmp_vals [ 0 ];
  croak( "Wrong original state" ) unless $decoded ~~ [ "ITIS$orig_name", ];
  sleep 1;
  my $chng_name = $$cmp_vals [ 1 ];
  $self -> write_cgi( $chng_name, ); 
  $self -> set_state( [ "ITIS$chng_name", ], );
}

sub write_cgi{
  my $self = shift;
  my $env = $self -> get_env;
  my $cgi = $$env{ 'SCRIPT_FILENAME' };
  croak unless defined( $cgi ) and length( $cgi );
  my $cgi_dir = dirname( $cgi );
  $self -> make_cgi( @_, $cgi => $cgi_dir, );
}

sub make_cgi{
  croak( "Cgi changes must be defined in descendant class" );
}

sub write_file_contents{
  my( $self => ( $contents => $fn, ), ) = @_;
  write_file( $fn => $$contents, ); 
  my $temp_files = $self -> get_temp_files;
  $self -> set_temp_files( [ @$temp_files, $fn, ], )
    unless grep { $_ eq $fn } @$temp_files;
}

1;

