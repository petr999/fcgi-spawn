package FCGI::Spawn::TestKit::ModPerl;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Basic', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  push( @$rv => ( qw/serialize serialize_post serialize_mp2 serialize_post_mp2/, ), );
  return $rv;
}

1;
