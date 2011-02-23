#!/usr/bin/perl

package FCGI::Spawn::BinUtils;

use strict;
use warnings;

use English qw/$UID/;

use base 'Exporter'; # FIXME Perl6::Export::Attrs

our @EXPORT_OK = qw/init_pid_callouts_share sig_handle re_open_log get_fork_rv
                    get_shared_scalar
                  /;

my $ipc;

sub _init_ipc {
  my $mm_scratch = shift;
  unless( defined $ipc ){
    eval{ require IPC::MM;
    1; } or die "IPC::MM: $@ $!";
    my $rv = $ipc = IPC::MM::mm_create( map{ $mm_scratch->{ $_ } } mm_size => 'mm_file', );
    $rv or die "IPC::MM init: $@ $!";
    my $uid = $mm_scratch->{ 'uid' };
    $rv = not IPC::MM::mm_permission( $ipc, '0600', $uid, -1);
    $rv or die "SHM unpermitted: $!"; # Return value invert
  }
}

sub _make_shared {
  my( $type, $mm_scratch ) = @_;
  &_init_ipc( $mm_scratch  );
  my $method = "mm_make_$type";
  my $tie_class = 'IPC::MM::'.ucfirst $type;
  my $ipc_var = $IPC::MM::{$method}->( $ipc );
  my $shared_var; $shared_var = {} if $type eq 'hash';
  tie( ( $type eq 'hash' ) ? %$shared_var : $shared_var, $tie_class , $ipc_var );
  return $shared_var;
}

sub init_pid_callouts_share {
  &_make_shared( 'hash' => shift, );
}

sub sig_handle {
  my( $sig, $pid ) = @_;
  return sub{
    $sig = ( $sig eq 'INT' ) ? 'TERM' : $sig ;
    kill $sig, $pid ;
  };
}

sub re_open_log {
  my $log_file = shift;
  close STDERR if defined fileno STDERR;
  close STDOUT if defined fileno STDOUT;
  open( STDERR, ">>", $log_file ) or die "Opening log $log_file: $!";
  open( STDOUT, ">>", $log_file ) or die "Opening log $log_file: $!";
  open STDIN, "<", '/dev/null'   or die "Can't read /dev/null: $!";
}

# These below are for tests

sub get_shared_scalar {
  eval{ require File::Temp;
  1; } or die "File::Temp: $@ $!";
  my $rv = _make_shared( 'scalar' => {  mm_file => File::Temp->new(),
      mm_size => 65535, 'uid' => $UID,
    }
  );
}

sub get_fork_rv {
  my $cref = shift;
  my $rv = &get_shared_scalar();
}

1;
