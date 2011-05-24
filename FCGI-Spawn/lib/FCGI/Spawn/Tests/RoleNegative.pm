package FCGI::Spawn::Tests::RoleNegative;

use Moose::Role;
use MooseX::FollowPBP;

__PACKAGE__->meta->make_immutable;

sub BUILD{
  my $self = shift;
  my $env = $self ->get_env;
  $$env{ 'SCRIPT_FILENAME' } =~ s/\/un_([^\/]+)$/\/$1/;
}

1;
