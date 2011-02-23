#!/usr/bin/perl

use strict;
use warnings;

use English;
use lib 'lib';

use Test::More tests => 1;

use File::Basename qw/fileparse/;
use Cwd qw/realpath/;

sub spawn_and_stop{
  my( $bname, $dname, $sfx ) = fileparse( __FILE__, '.t' );
  $dname = realpath $dname;
  my $conf = "$dname/../etc-test/bname";
  my $pid = "$conf/fcgi_spawn.pid";
  $cmd = "bin/fcgi_spawn";
}

TODO: {
  local $TODO = 'requires FCGI.pm, IPC::MM  and an uid=0';
  ok( get_fork_rv( \&spawn_and_stop ) => 'Spawner initialisation' );
}
