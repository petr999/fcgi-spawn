package FCGI::Spawn::TestKit::CgiFast;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Basic', );

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  push( @$rv => ( qw/serialize serialize_cf serialize_post_cf/, ), );
  return $rv;
}

1;
