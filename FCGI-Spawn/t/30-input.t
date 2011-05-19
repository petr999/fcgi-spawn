#!/usr/bin/perl -w

use strict;
use warnings;

use lib 'lib';

use Try::Tiny;
use Test::More;
use Tie::IxHash;
use POSIX 'WNOHANG';

if( use_ok( 'FCGI::Spawn::TestUtils' ) ){
my $util;
try{
    tie(
      my %config_dirs, 'Tie::IxHash', 
      '' => {
        'testname' => 'Test with FCGI.pm',
        'scripts_parsetests' => [
          qw/basic serialize post-serialize/
        ],
      },
      'cgi_fast' => {
        'testname' => 'Test with CGI::Fast',
        'scripts_parsetests' => [
          qw/basic serialize serialize_cf post-serialize_cf/
        ],
      },
      'mod_perl' => {
        'testname' => 'Test with mod_perl',
        'scripts_parsetests' => [
          qw/basic serialize post-serialize serialize_mp2 post-serialize_mp2/
        ],
      },
      'mod_perl_cgi_fast' => {
        'testname' => 'Test with mod_perl and CGI::Fast',
        'scripts_parsetests' => [
          qw/basic serialize serialize_cf/
        ],
      },
    );

    if( use_ok( 'FCGI::Spawn::TestUtils::Client' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Basic' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Serialize' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Serialize_CF' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Serialize_MP2' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Post::Serialize' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Post::Serialize_CF' ) 
        and use_ok( 'FCGI::Spawn::TestUtils::Client::Post::Serialize_MP2' ) 
      ){
      while( my( $config_dir => $cd_hash  ) = each %config_dirs ){
        $util = FCGI::Spawn::TestUtils -> new( 'conf' => $config_dir );
        ok( my $ppid = get_fork_pid( $util -> spawn_fcgi ) => "Spawner initialisation configured from '$config_dir'" );
        sleep 1;
        my $wp = waitpid( $ppid => WNOHANG ) != -1;
        my $testname = $$cd_hash{ 'testname' };
        if( $wp and my $pid = $util -> read_pidfile){
          foreach my $sp_test ( @{ $cd_hash -> { 'scripts_parsetests' } } ){
            die( "sp_test $sp_test: no match!" )
              unless $sp_test =~ /^(([^-]+)-)?([^-]+)$/;
            my( $class_mod, $cgi_fname ) = ( $2, $3 );
            my $descr = defined( $class_mod ) ? uc( $class_mod ) : 'GET';
            my @class = ();
            my $ccf_prime = 1; my @class_cgi_fname;
            foreach my $particle( split /_/, $cgi_fname ){ 
              my $pv = $ccf_prime ? ucfirst( $particle ) : uc( $particle );
              push( @class_cgi_fname, $pv );
              $ccf_prime = 0;
            }
            push( @class, ucfirst $class_mod )
              if defined( $class_mod ) and length $class_mod;
            push( @class, join( '_', @class_cgi_fname ) );
            my $class_name = join( '::',
              'FCGI::Spawn::TestUtils::Client' => @class, );
            if( ok( my $client = $class_name->new(
                  'util' => $util, )
                => "Client connection: $cgi_fname script"
              ) ){
              if( ( $cgi_fname eq 'basic' ) and ( $config_dir  eq 'cgi_fast' ) ){
                $client -> set_parser( cgi_output_parser( 'CGI' ) );
              }
              my( $stdout_rv, $stderr, ) = $client -> request;
              ok( $stdout_rv => "$testname ('$config_dir') $cgi_fname: $descr", );
              if( defined( $stderr ) and length $stderr ){
                ok( 0 => "STDERR: $stderr\n", );
              } else {
                ok( 1 => 'Error output is empty', );
              }
            }
          }
          $util->kill_procsock;
        }
      }
    }
 } catch { ok( 0 => "Testing CGI input failed: $@ $!" );
    $util -> kill_procsock;
 };
}

done_testing();
