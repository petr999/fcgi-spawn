package FCGI::Spawn::TestKit::Fcgi;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::TestKit::Basic', );

__PACKAGE__->meta->make_immutable;

sub init_tests_list{
  my $self = shift;
  my $rv = $self -> SUPER::init_tests_list();
  push( @$rv => ( qw/serialize serialize_post/, ), );
  return $rv;
}

1;
