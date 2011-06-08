#!/usr/bin/perl

package FCGI::Spawn::TestUtils;

use Moose;
use MooseX::FollowPBP;

use Perl6::Export::Attrs;

use File::Temp;
use English qw/$UID $GID/;
use File::Basename qw/dirname/;
use Cwd qw/realpath/;
use POSIX ":sys_wait_h";
use Const::Fast;
use Sub::Name;
use POSIX 'WNOHANG';
use Test::More;
use Carp;
use Tie::IxHash;
use Try::Tiny;
use IO::Socket;

use FCGI::Spawn::BinUtils ':testutils';


const( my $timeout => defined( $ENV{ TIMEOUT } ) ? $ENV{ TIMEOUT } : 30 );
const( my $etc_test => 't/etc-test', );
const( my $mmf_basename
  => "fcgi_spawn_" . rand( 100500 ) . "_scoreboard.lck", );
tie( my %general_preset => 'Tie::IxHash', );
const( %general_preset
  => ( 'conf' => '', 'cmd_args' => [ qw/-pl -t 10 -stl 10/ ], ), );
const( my $conf_presets => { 'call_out' => { 'cmd_args' => [ qw/-pl -e/, ], },
    map( { $_ => \%general_preset, } 
      qw/general un_clean_main stats x_stats
        log_rotate max_requests fcgi pre_load time_limit save_env/,
    ),
    'mod_perl_handlers' => { 'cmd_args' => [ '-pl' ], },
    'chroot'        => { 'cgi_dir' => "/$etc_test/cgi",
      'cmd_args' => [ '-mmf' => "$etc_test/$mmf_basename", ],
    },
  }, );
const( my $b_conf
  => realpath( dirname( __FILE__ )."/../../../../$etc_test" ) );

my %bnames =  ( 'etc_test' => $etc_test,
  'pid_fname' => 'fcgi_spawn.pid', 'log_fname' => 'fcgi_spawn.log',
  #'sock_name' => "spawner.sock", # TODO: local socket
  'sock_name' => "127.0.0.1:8888",
  'cmd_args_first' => [ "-Iblib/lib" => "bin/fcgi_spawn",
    "-mmf" => "$etc_test/$mmf_basename", '-cm', ],
  map{ $_ => 'nobody' } qw/user group/,
);
foreach( qw/pid log/ ){
  my $key = $_."_fname";
  $bnames{ $key } = join '/', $b_conf => $bnames{ $key };
}
$bnames{ 'cgi_dir' } = join '/', $b_conf => 'cgi';

has( qw/timeout is ro isa Int default/ => $timeout, );
has( qw/pid is rw isa Int/ );
has( qw/cmd_args is ro isa ArrayRef default/ => sub{ []; }, );
has( qw/conf is ro isa Str initializer init_conf default/ => '', );

foreach my $p_name ( keys %bnames ){
  my $b_default = $bnames{ $p_name };
  my $ref = ref $b_default;
  my $isa = $ref ? ucfirst( lc( $ref ) ).'Ref' : 'Str' ;
  my $default;
  if( $ref ){ $default = subname( "init_$p_name" => sub{ $b_default }, ); }
  else { $default = $b_default; }
  has $p_name => ( qw/is ro/,    'isa' => $isa, 'default' => $default, );
}

__PACKAGE__->meta->make_immutable;

my $debug = defined( $ENV{ 'DEBUG' } ) ? $ENV{ 'DEBUG' } : 0;

sub BUILDARGS{
  my $class = shift;
  my $rv = {};
  if( @_ > 1 ){
    $rv = { @_ };
  } elsif( @_ > 0 ){
    my $arg = shift;
    if( ( defined ref $arg ) and 'HASH' eq ref $arg ){
      $rv = $arg;
    } else {
      $rv = { 'conf' => $arg };
    }
  }
  my $conf = defined( $$rv{ 'conf' } ) ? $$rv{ 'conf' } : '' ;
  if( defined $$conf_presets{ $conf } ){
    my $presets = $$conf_presets{ $conf };
    foreach my $conf_key ( keys %$presets ){
      if( defined $$presets{ $conf_key }
          and ( not( defined( $$rv{ $conf_key } ) )
            or 'conf' eq $conf_key
          )
        ){
        $$rv{ $conf_key } = $$presets{ $conf_key };
      }
    }
  }
  return $rv;
}

sub BUILD{
    my $self = shift;
    $self -> rm_files_if_exists;
    return $self;
};

sub init_conf{
  my( $self, $value, $set, $attr, ) = @_;
  my $set_val = $b_conf;
  if( length $value ){ $set_val .= "/$value"; }
  $set -> ( $set_val, );
}

sub retr_conf_presets  :Export( :DEFAULT ){
  return $conf_presets;
}

sub share_var :Export( :DEFAULT ){
  my( $ref, $ipc_ref ) = @_;
  my $fn = File::Temp->new();
  my $rv = &make_shared( [ $ref => $ipc_ref ]
    => {  mm_file => $fn, mm_size => 65535, 'uid' => $UID, },
  );
  defined( $rv ) and not( $rv ) and croak "No shared scalar: $!";
}

sub get_fork_rv :Export( :DEFAULT ){
  my $cref = shift;
  my $pid = fork;
  if( defined $pid ){
    if( $pid ){
      waitpid $pid => 0;
      return $? >> 8;
    } else {
      exit &$cref;
    }
  } else {
    croak "Cannot fork: $!";
  }
}

sub get_fork_pid :Export( :DEFAULT ){ # leaves forked process as is
  my $cref = shift;
  my $pid = fork;
  if( defined $pid ){
    if( $pid ){
      return $pid;
    } else {
      &$cref;
      exit;
    }
  } else {
    croak "Cannot fork: $!";
  }
}

sub kill_proc_dead :Export( :DEFAULT ){
  my $pid = shift;
  my $times = ( @_ > 0 ) ? shift : $timeout; # for KillProcDead.pm only
  my $rv = kill 'TERM' => $pid;
  diag( "TERM wait RV: $rv\n" ) if $debug;
  unless( is_process_dead( $pid ) ){
    foreach my $i ( 1..$times ){
      $rv = waitpid $pid => WNOHANG;
      sleep 1;
      diag( "TERM wait RV: $rv "."kill0: ".kill( 0 => $pid )."\n" ) if $debug;
      $rv = is_process_dead( $pid );
      if( $debug ){ diag( "Dying termed pid $pid: $rv" ); }
      last if $rv;
    }
    unless( $rv ){ 
      kill( 'KILL' => $pid, );
      foreach my $i ( 1..$times ){
        sleep 1;
        $rv = is_process_dead( $pid );
        if( $debug ){ diag( "Dying killed pid $pid: $rv" ); }
        last if $rv;
      }
    }
  } else {
    waitpid  $pid => 0;
    $rv = 1;
  }
  return $rv;
}

sub kill_procsock{
  my $self = shift;
  my $pid = $self -> get_pid or croak "No pid";
  my $timeout = $self -> get_timeout;
  my $rv = kill_proc_dead( $pid => $timeout, );
  if( $rv ){
    foreach my $i ( 1..$timeout ){
      my $sock_name = $self -> get_sock_name;
      $rv = sock_try_serv( $sock_name );
      last if $rv;
      unless( $rv ){
        diag( "Trying to bind socket: $i\n" ) if $debug;
        sleep 1;
      }
    }
  }
  return $rv;
}

sub retr_addr_port{
  my $self = shift;
  my $sock_name = $self -> get_sock_name;
  addr_port( $sock_name );
}

sub spawn_fcgi{
  my $self = shift;
  my $nd = @_ > 0 ? shift : 0;
  my( $conf_dname, $log_fname, $pid_fname,
      $sock_name, $user, $group, $cmd_args_first ) = map{
      my $s_name = "get_$_";
      $self->$s_name;
  } qw/conf log_fname pid_fname
        sock_name user group cmd_args_first/;
  my $cmd_args = $self -> get_cmd_args;
  my @caf_new = (); my $skip_next = 0;
  foreach my $caf( @$cmd_args_first, ){
    if( $skip_next ){ $skip_next = 0; next; }
    if( grep{ $_ eq $caf } @$cmd_args ){ $skip_next = 1; }
    else { push( @caf_new => $caf, ); }
  }
  $cmd_args_first = \@caf_new;
  my @cmd = ( $^X, @$cmd_args_first );
  my @args = $nd 
    ? ( '-nd', )
    : ( '-l' => $log_fname, )
  ;
  @args = ( @args,
    "-s" => $sock_name, "-p" =>  $pid_fname, "-c" => $conf_dname,
  );
  if( $UID == 0 ){ push( @args, "-u" => $user, "-g" => $group, ); }
  else{ push( @args, "-u" => scalar getpwuid( $UID ),
    "-g" => scalar getgrgid( shift( @{ [ split( /\s+/, $GID ), ] }, ), ) ); 
  }
  push @args, @$cmd_args if @$cmd_args > 0;
  @cmd = ( @cmd, @args, );
  if( $debug ){ diag( join( ' ', @cmd ) . "\n" ); }
  return sub{ exec @cmd };
}

sub read_pidfile{
  my $self = shift;
  my $ppid = shift;
  my $timeout = $self -> get_timeout;
  my $rv = undef;
  my $pid_fname = $self -> get_pid_fname;
  foreach my $i ( 1..$timeout ){
    my ( $fsp_pid_fh, $pid, );
    if( open $fsp_pid_fh, '<', $pid_fname, ){
      if( defined( $pid = <$fsp_pid_fh> )
              and close $fsp_pid_fh
        ){
        undef $fsp_pid_fh;
        diag( "PID: $pid\n" ) if $debug;
        $self -> set_pid( $pid );
        $rv = $pid;
      }
      last;
    } else {
      my $wp = waitpid( $ppid => WNOHANG, ) != -1;
      unless( $wp or grep { $_ eq '-nd' } @{ $self -> get_cmd_args } ){
        $self -> inspect_log;
      }
      croak( "Logger pid $ppid died" ) unless $wp;
      sleep 1;
    }
  }
  return $rv;
}

sub inspect_log{
  my $self = shift;
  my $log_fname = $self -> get_log_fname;
  open( my $log_fh, "<", $log_fname, )
    or croak "No log file $log_fname: $!";
  while( <$log_fh> ){
      diag( $_ );
  }
}

sub sock_client{
  my( $self, $sock_type ) = @_;
  my $timeout = $self -> get_timeout;
  my $sock_name = $self -> get_sock_name;
  my @sock_name_addr = split /:/, $sock_name;
  if( @sock_name_addr == 2 ){
    $sock_type //= 'INET';
  } else {
    croak "Socket is not a tcp: $sock_name"
  }
  ; # TODO: local unix socket
  my $class = "IO::Socket::$sock_type";
  my $sock;
  foreach my $i ( 1..$timeout ){
    if( $sock = $class -> new(
        'PeerAddr' => $sock_name_addr[ 0 ],
        'PeerPort' => $sock_name_addr[ 1 ],
        'Type' => SOCK_STREAM, 'Timeout' => $timeout,
        )
      ){
      last;
    } else {
      sleep 1;
    }
  }
  croak $! unless defined( $sock ) or not $sock;
  return $sock;
}

sub rm_files_if_exists{
  my $self = shift;
  my @log_pid_fnames = map{
    my $s_name = "get_$_"."_fname"; $self -> $s_name;
  } qw/log pid/;
  foreach my $fname ( @log_pid_fnames ){
    if( -f $fname ){
      unlink( $fname ) or croak $!;
    }
  }
  my $sock_name = $self -> get_sock_name;
  if( defined( $sock_name ) and length( $sock_name ) and -S $sock_name ){
    croak "Cannot delete socket: $sock_name" unless unlink( $sock_name );
  }
  croak( "Open directory: $b_conf", ) unless opendir my $b_conf_dh => $b_conf;
  while( my $fn = readdir $b_conf_dh ){
    $fn = "$b_conf/$fn";
    if( $fn =~ m/\.lck$/ ){
      croak( "Deleting file: $fn" ) unless unlink $fn;
    } elsif( $fn =~ m/\.sem$/ ){
      croak( "Deleting file: $fn" ) unless unlink $fn;
    }
  }
  closedir $b_conf_dh;
}

sub sock_try_serv :Export( :DEFAULT ){
  my $sock_name = shift;
  my $rv;
  try{
    my( $addr, $port ) = addr_port( $sock_name );
    if( defined $addr ){
      $addr = gethostbyname( $addr ) unless $addr =~ m/^(\d{1,3}\.){3}\d{1,3}$/;
      croak( "sockarrd_in $sock_name: $@ $!" )
        unless my $struct_addr = sockaddr_in( $port, inet_aton( $addr ) );
      croak( "socket() for $sock_name: $@ $!" )
        unless socket( my $h, PF_INET, SOCK_STREAM, getprotobyname('tcp') );
      croak( "setsockopt() for $sock_name: $@ $!" )
        unless setsockopt( $h, SOL_SOCKET, SO_REUSEADDR, 1, );
      $rv = bind( $h, $struct_addr );
      close( $h );
    } else {
      croak( "Can not remove $sock_name" )
        if ( -S $sock_name ) and not unlink $sock_name;
      $rv = 1;
    }
  } catch {
    warn( "Trying to bind socket $sock_name: $_" );
    $rv = 0;
  };
  return $rv;
}

1;
