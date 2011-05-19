package FCGI::Spawn::Tests::SerializePost;

use Moose;
use MooseX::FollowPBP;

use URI::Escape;
use Digest::MD5 'md5_base64';

extends( 'FCGI::Spawn::Tests::Serialize', );
has( '+descr' => ( 'default' => 'Serialization via POST', ), );

has( '+test_var' =>( qw/is rw lazy 1/, ), );

sub make_env{ 
  my $self = shift;
  my $orig_env = $self -> SUPER::make_env();
  my $env = { %$orig_env, qw/REQUEST_METHOD POST CONTENT_TYPE/
    => 'application/x-www-form-urlencoded', };
  return $env;
}

sub make_content{
  my $self = shift;
  $content = $self -> make_test_seq;
  # env attr change
  $self -> get_env -> { 'CONTENT_LENGTH' } = length( $$content, );
  $content;
}

1;
