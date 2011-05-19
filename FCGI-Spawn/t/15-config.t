#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use FindBin;
use Cwd qw/realpath/;

use Test::More;

my $conf;

if( use_ok( 'FCGI::Spawn::ConfigFile' )
    and ok( $conf = FCGI::Spawn::ConfigFile->new() => 'Config initialisation' )
    and ok( $conf->read_fsp_config_file => 'Config reading' )
    and ok( $conf->read_fsp_config_file( realpath "$FindBin::Bin/../etc-test" )
      => 'Different config initialisation' )
  ){
    ok( $conf->get_sock_chown ~~ [ -1, 80 ], 'Array reading' );
    is( $conf->get_clean_inc_subnamespace => 'Bugzilla::Config', 'String reading' );
    is( $conf->get_sock_chmod => '0660', 'Number reading' );
}

done_testing;
