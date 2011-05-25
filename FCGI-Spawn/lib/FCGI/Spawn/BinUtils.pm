#!/usr/bin/perl

package FCGI::Spawn::BinUtils;

use strict;
use warnings;

use POSIX qw/WNOHANG/;
use English qw/$UID/;
use Perl6::Export::Attrs;
use Carp;

sub _init_ipc {
  my( $ipc_ref => $mm_scratch  ) = @_;
  unless( defined $$ipc_ref ){
    croak( "IPC::MMA: $@ $!" ) unless eval{ require IPC::MMA; 1; };
    my $rv = $$ipc_ref = IPC::MMA::mm_create( map{ $mm_scratch->{ $_ } } mm_size => 'mm_file', );
    croak( "IPC::MMA init: $@ $!" ) unless $rv;
    my $uid = $mm_scratch->{ 'uid' };
    unless( $UID ){
      $rv = not IPC::MMA::mm_permission( $$ipc_ref => '0600', $uid => -1,);
      croak( "SHM unpermitted for $uid: $!" ) unless $rv; # Return value invert
    }
  }
}

sub make_shared :Export( :scripts :testutils ) {
  my( $refs, $mm_scratch, ) = @_;
  my( $ref, $ipc_ref ) = @$refs;
  &_init_ipc( $ipc_ref => $mm_scratch  );
  my $type = lc ref $ref;
  croak( "Not a ref: $ref" ) unless $type;
  my $method = "mm_make_$type";
  my $tie_class = 'IPC::MMA::' . ucfirst $type;
  my $ipc_var = $IPC::MMA::{ $method }->( $$ipc_ref );
  tie( ( $type eq 'hash' ) ? %$ref : $$ref, $tie_class , $ipc_var );
}

sub sig_handle :Export( :scripts ) {
  my( $sig, $pid ) = @_;
  return sub{
    $sig = ( $sig eq 'INT' ) ? 'TERM' : $sig ;
    kill $sig => $pid ;
  };
}

sub re_open_log :Export( :scripts ) {
  my $log_file = shift;
  close STDERR if defined fileno STDERR;
  close STDOUT if defined fileno STDOUT;
  croak( "Opening log $log_file: $!" )
    unless open( STDERR, ">>", $log_file );
  croak( "Opening log $log_file: $!" )
    unless open( STDOUT, ">>", $log_file );
  croak( "Can't read /dev/null: $!" )
    unless open( STDIN, "<", '/dev/null' );
}

sub print_help_exit :Export( :scripts ) {
  print <<EOT;
Usage:
  -h, -?    display this help
  -c <config path>
            path to the config file(s)
  -l        log file
  -p        pid file
  -u        system user name
  -g        system group name
  -s        socket name with full path
  -e        redefine exit builtin perl function
  -pl       evaluate the preload scripts
  -nd       do not detach from console
  -t NN     set callout time limit to NN seconds
              ( 60 by default, 0 disables feature )
  -stl      wait NN seconds for called out process to terminate by time limit
              before kill it ( 1 by default, 0 disables the feature )
  -mmf      name of the lock file for the -t feature
  -mms      size of the shared memory segment for the -t feature
EOT
  CORE::exit;
}

sub is_sock_tcp :Export( :modules :testutils ){
  my $rv = shift =~ m/^([^:]+):([^:]+)$/;
  wantarray ? ( $1 => $2, ) : $rv;
}

sub is_process_dead :Export( :scripts :testmodules ) {
  my $pid = shift;
  waitpid $pid => WNOHANG;
  my $rv = ( -1 == waitpid $pid => WNOHANG,  )
     && ( 0 == kill 0 => $pid );
  return $rv;
}

1;
