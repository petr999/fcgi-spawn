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
use IO::Socket;
use Const::Fast;
use Sub::Name;
use POSIX 'WNOHANG';

use FCGI::Spawn::BinUtils ':testutils';

use Test::More;
use Carp;
use Tie::IxHash;

const( my $timeout => defined( $ENV{ TIMEOUT } ) ? $ENV{ TIMEOUT } : 30 );
const( my $etc_test => 'etc-test', );
tie( my %general_preset => 'Tie::IxHash', );
const( %general_preset
  => ( 'conf' => '', 'cmd_args' => [ qw/-pl -t 10 -stl 10/ ], ), );
const( my $conf_presets => { 'call_out' => { 'cmd_args' => [ qw/-pl -e/ ], }, 
    map( { $_ => \%general_preset, }
      qw/general un_clean_main stats x_stats log_rotate max_requests
        fcgi pre_load time_limit save_env/,
    ),
    'chroot'        => { 'cgi_dir' => "/$etc_test/cgi", },
  }, );
const( my $b_conf => realpath( dirname( __FILE__ )."/../../../$etc_test" ) );

my %bnames =  ( 'etc_test' => $etc_test,
                'pid_fname' => 'fcgi_spawn.pid', 'log_fname' => 'fcgi_spawn.log',
                #'sock_name' => "spawner.sock", # TODO: local socket
                'sock_name' => "127.0.0.1:8888",
                'cmd_args_first' => [ "-Ilib", "bin/fcgi_spawn", ],
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
has( qw/conf is ro isa Str initializer init_conf default/
  => '', );

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
  my $times = ( @_ > 0 ) ? shift : $timeout; # for kill-proc-dead.t only
  my $rv = kill 'TERM' => $pid;
  diag( "TERM wait RV: $rv\n" ) if $debug;
  unless( $rv < 0 ){
    foreach my $i ( 1..$times ){
      $rv = waitpid $pid => WNOHANG;
      sleep 1;
      diag( "TERM wait RV: $rv "."kill0: ".kill( 0 => $pid )."\n" ) if $debug;
      if( is_process_dead( $pid ) ){
        $rv = 1; last;
      } else {
        $rv = 0;
      }
    }
    unless( $rv ){ 
      foreach my $i ( 1..$times ){
        kill 'KILL' => $pid unless $rv;
        sleep 1;
        $rv = waitpid $pid => 0;
        if( $debug ){
          diag( "KILL wait RV: $rv "."kill0: ".kill( 0 => $pid )."\n" );
        }
        if( is_process_dead( $pid ) ){ $rv = 1; last; }
        else { $rv = 0; }
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
  kill_proc_dead( $pid => $timeout, );
  my $rv = 0;
  foreach my $i ( 1..$timeout ){
    if( $self -> sock_try_serv ){
      $rv = 1;
      last;
    } else {
      diag( "$i\n" ) if $debug;
      sleep 1;
    }
  }
  return $rv;
}

sub sock_try_serv{
  my $self = shift;
  my $sock_name = $self -> get_sock_name;
  my $rv = 0;
  my( $addr, $port ) = $self -> addr_port;
  if( defined $addr ){
    $addr = gethostbyname( $addr ) unless $addr =~ m/^(\d{1,3}\.){3}\d{1,3}$/;
    my $struct_addr = sockaddr_in( $port, inet_aton( $addr ) ) or croak $!;
    socket(my $h, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or croak $!;
    setsockopt($h, SOL_SOCKET, SO_REUSEADDR, 1) or croak $!;
    if( $rv = bind( $h, $struct_addr ) ){
        close( $h );
    }
  } else {
    $rv = 1;
  }
  return $rv;
}

sub addr_port{
  my $self = shift;
  my $sock_name = $self -> get_sock_name;
  my @rv = &is_sock_tcp( $sock_name, );
  my( $addr => $port, ) = @rv;
  unless( defined( $addr ) and length( $addr )
      and defined( $port ) and length( $port )
    ){
      @rv = undef;
  }
  return @rv;
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
  my $cmd_args = $self -> get_cmd_args;
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
    if( $sock = $class->new(
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
}

1;
