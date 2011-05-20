#!/usr/bin/perl -w

use strict;
use warnings;

use lib 'lib';

use English '$UID';
use Test::More;
use FCGI::Spawn::TestUtils;
use POSIX qw/WNOHANG/;
use Try::Tiny;

use Data::Dumper;

my $util = FCGI::Spawn::TestUtils -> new;
my( $timeout, $user, ) = ( $util -> get_timeout, $util -> get_user );
my $cgi_dir = $util -> get_cgi_dir;
undef $util;
if( is( $UID => 0, 'User uid=0 is required to run this test' )
    and cmp_ok( getpwnam( $user ), '>', 0, "System user $user is necessary to exist for this test" )
    and use_ok( 'FCGI' ) and use_ok( 'IPC::MM' ) and use_ok( 'FCGI::Client' ) and use_ok( 'CGI' )
  ){
  try{
    foreach my $config_dir( '' => 'cgi_fast', ){
      diag( "Following tests config dir '$config_dir'" )
        if defined( $ENV{ 'DEBUG' } ) and $ENV{ 'DEBUG' };
      $util = FCGI::Spawn::TestUtils -> new( $config_dir, );
      ok( my $ppid = get_fork_pid( $util -> spawn_fcgi ) => "Spawner initialisation" );
      if( ok( $ppid, "FCGI Spawned" ) ){
        my $pid = $util -> read_pidfile( $ppid ); 
        if( ok( defined( $pid ) => "FCGI::Spawn has put a pid file: $pid" ) ){
          my $cgi_fname = 'basic.cgi';
            foreach my $sock_type( qw/INET/ ){ # TODO: UNIX and INET sockets
              my %requests = ( 'GET' => sub{
                  my( $conn, $cgi_fullname ) = @_;
                  $conn -> request( +{
                      qw/REQUEST_METHOD GET
                      SCRIPT_FILENAME/, $cgi_fullname,
                    }, '',
                  );
                }, 'POST' => sub{
                  my( $conn, $cgi_fullname ) = @_;
                  $conn -> request( +{
                      qw/REQUEST_METHOD POST
                      SCRIPT_FILENAME/, $cgi_fullname,
                    }, 'abcd=efgh',
                  );
                },
              );
              while( my( $rt_type, $request ) = each %requests ){
                my $sock = $util -> sock_client( $sock_type );
                my $conn;
                if( ok( $conn = FCGI::Client::Connection -> new( 'sock' => $sock, 'timeout' => $timeout, )
                    => 'Open connection socket',
                  ) ){
                    my $cgi_fullname = join '/', $cgi_dir => $cgi_fname;
                    my( $stdout, $stderr );
                    diag $cgi_fname if defined( $ENV{ 'DEBUG' } ) and $ENV{ 'DEBUG' };
                    ok( ( $stdout, $stderr ) = $request->( $conn, $cgi_fullname, )
                        =>  "Request $rt_type",
                    );
                    my $parsetest = ( length( $config_dir ) > 0 )
                      ? 'CGI::Fast' : 'CGI';
                    if( cmp_ok( length( $stdout ), '>', 0, "CGI output" ) 
                          and defined( $parsetest ) and ( 'CODE' eq ref $parsetest )
                      ){
                        $stdout =pop @{ [ split /\n/ => $stdout, ] };
                        is( $stdout => $parsetest, "CGI output parse" );
                    }
                    my $stderr_defined = defined $stderr;
                    ok( not( $stderr_defined  ) => "Error output"
                      .(  $stderr_defined ? ': '.$stderr : ' is empty'
                      ),
                    );
    
                  }
                  $sock -> close;
                }
              }
          ok( $util -> kill_procsock => "killing pid $pid" ) or die "$pid: not killed";
        }
      } else {
        last;
      }
      $util -> rm_files_if_exists;
    }
  } catch {
    ok( 0 => "Died while testing request $@ $!" );
  };
}
done_testing; # TODO: plan
