package FCGI::Spawn::Tests::Serialize;

use Moose;
use MooseX::FollowPBP;

use URI::Escape;
use Digest::MD5 'md5_base64';

extends( 'FCGI::Spawn::Tests::Fixed', );

has( '+env' => ( qw/lazy 1/, ), );
has( '+descr' => ( 'default' => 'Serialization', ), );

__PACKAGE__->meta->make_immutable;

sub make_env{
  my $self = shift;
  my $env = $self -> SUPER::make_env();
  my $seeding = $self -> make_test_seq;
  $$env{ 'QUERY_STRING' } = $$seeding;
  return $env;
}

sub make_test_seq{
  my $self = shift;
  my @seeding = %{ $self -> get_test_var };
  return \( join( "=", map{ uri_escape( $_ ) } @seeding, ) );
}

sub init_test_var{
  my $self = shift;
  my $seed = rand( 4294967295 );
  my $b64_seed = md5_base64 rand( 4294967295 );
  my $seeding = { $b64_seed => $seed, };
  return $seeding;
}

1;
