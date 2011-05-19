package FCGI::Spawn::Tests::CleanMain;

use Moose;
use MooseX::FollowPBP;

use JSON;
use Digest::MD5 'md5_base64';
use Sub::Name;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests::Persistent' );

has( '+state' => ( qw/isa HashRef/, ) );
has( 'old_content'  => ( qw/is rw   isa ArrayRef   default/
  => subname( 'init_old_content' => sub{ [] }, ), ), );
has( '+descr' => ( 'default' => 'Cleaning global variables from CGI programs', ), );
has( '+env' => ( qw/is rw/ ) );
has( '+content' => ( qw/isa CodeRef/, ), );
has( '+sngl_chng' => ( qw/default 0/, ), );


sub make_env{
  my $self = shift;
  my $orig_env = $self -> SUPER::make_env();
  my $env = { %$orig_env, qw/REQUEST_METHOD POST CONTENT_TYPE/
    => 'application/x-www-form-urlencoded' };
  return $env;
}

sub make_content{ return \&remake_content; }

sub remake_content{
  my $self = shift;
  my $old_content = $self -> get_old_content;
  my $new_content ={};
  my $rand_max = $self -> get_rand_max;
  foreach( 0..9 ){
    my $seed = md5_base64 rand( $rand_max );
    my $key_seed = md5_base64 rand( $rand_max );
    $key_seed =~ s/[^\w]//g;
    $key_seed = uc( $key_seed );
    $$new_content{ $key_seed } = $seed;
  }
  my $content = \( encode_json( { 'old' => $old_content, 'new' => $new_content, } ) );
  @$old_content = [ @$old_content, keys %$new_content, ];
  my $length = length( $$content );
  $self -> get_env -> { 'CONTENT_LENGTH' } = $length; # environment set here
  return $content;
}

1;
