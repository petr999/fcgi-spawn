package FCGI::Spawn::Tests::Chroot;

use Moose;
use MooseX::FollowPBP;

extends( 'FCGI::Spawn::Tests::Cgi' );

has( '+descr' => ( 'default' => 'Run CGI script in a chroot environment', ), );

1;
