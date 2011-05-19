#!/usr/bin/perl

package FCGI::Spawn::BinUtils;

use strict;
use warnings;

use Perl6::Export::Attrs;

sub _init_ipc {
  my( $ipc_ref => $mm_scratch  ) = @_;
  unless( defined $$ipc_ref ){
    eval{ require IPC::MM;
    1; } or die "IPC::MM: $@ $!";
    my $rv = $$ipc_ref = IPC::MM::mm_create( map{ $mm_scratch->{ $_ } } mm_size => 'mm_file', );
    $rv or die "IPC::MM init: $@ $!";
    my $uid = $mm_scratch->{ 'uid' };
    $rv = not IPC::MM::mm_permission( $$ipc_ref, '0600', $uid, -1);
    $rv or die "SHM unpermitted: $!"; # Return value invert
  }
}

sub make_shared :Export( :scripts :testutils ) {
  my( $refs, $mm_scratch, ) = @_;
  my( $ref, $ipc_ref ) = @$refs;
  &_init_ipc( $ipc_ref => $mm_scratch  );
  my $type = lc ref $ref; die unless length $type;
  my $method = "mm_make_$type";
  my $tie_class = 'IPC::MM::' . ucfirst $type;
  my $ipc_var = $IPC::MM::{ $method }->( $$ipc_ref );
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
  open( STDERR, ">>", $log_file ) or die "Opening log $log_file: $!";
  open( STDOUT, ">>", $log_file ) or die "Opening log $log_file: $!";
  open STDIN, "<", '/dev/null'   or die "Can't read /dev/null: $!";
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
              before kill it ( 1 by default, 9 disables the feature )
  -mmf      name of the lock file for the -t feature
  -mms      size of the shared memory segment for the -t feature
EOT
  CORE::exit;
}

sub is_sock_tcp :Export( :modules :testutils ){
  shift =~ /^[^\/]+:\d+$/;
}

1;
