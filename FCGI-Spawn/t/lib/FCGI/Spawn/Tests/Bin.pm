package FCGI::Spawn::Tests::Bin;

use Moose;
use MooseX::FollowPBP;

use English '$UID';
use Test::More;
use Try::Tiny;
use Const::Fast;

use FCGI::Spawn::TestUtils;
use FCGI::Spawn::BinUtils ':testutils';

extends( 'FCGI::Spawn::Tests', );

has( '+descr' => ( 'default' => 'run fcgi_spawn binary', ), );
has( qw/timeout is ro isa Int required 1 default/ =>
        ( defined $ENV{ 'TIMEOUT' } ) ? $ENV{ 'TIMEOUT' } : 30, );

__PACKAGE__->meta->make_immutable;

sub check {
    my $self       = shift;
    my @utils_args = (
        [   'sock_name' => join( '/',
                './t/etc-test' => 'spawner_' . rand(100000) . '.sock', ),
        ],
        [],    # TCP is the default in TestUtils
    );
    my @utils = map { FCGI::Spawn::TestUtils->new( @$_, ) } @utils_args;
    const( my $user => $utils[0]->get_user, );
    @utils = grep { sock_try_serv( $_->get_sock_name ); } @utils;
    my $rv = 1;
    unless ($UID) {
        ok( $rv =
                ( getpwnam($user) > 0 ) =>
                "System user $user is necessary to exist for this test if you are root",
        );
    }
    if ( use_ok( 'FCGI', ) and use_ok( 'IPC::MMA', ) ) {
        try {
            foreach my $util (@utils) {
                if ( defined $ENV{ 'DEBUG' } and $ENV{ 'DEBUG' } ) {
                    diag( $util->get_sock_name );
                }
                $self->start_logged( $util, );
                $self->start_foreground( $util, );
            }
        }
        catch {
            ok( 0 => 'Failed trying to start a binary', );
        };
    }
    return $rv;
}

sub start_logged {
    my ( $self => $util, ) = @_;
    my $rv = 1;
    my ( $pid_file, $log_file ) = retr_file_names($util);
    my $timeout = $self->get_timeout;
    my ( $pid => $ppid, );
    if ($rv) {
        $rv &&= not( -f $pid_file );
        ok( $rv => "Finding if pid file $pid_file doesn\'t exist", );
    }
    if ($rv) {
        $rv &&= $ppid = get_fork_pid( $util->spawn_fcgi, );
        ok( $rv => 'Spawner initialisation', );
    }
    diag("Sleeping $timeout seconds");
    sleep $timeout;
    if ($rv) {
        $pid = $util->read_pidfile( $ppid, );
        $rv &&= $pid;
        unless ($rv) { $util->inspect_log; }
        ok( $rv => "Reading pid file: $pid", );
    }
    if ($rv) {
        my ( $is_sock_tcp => $sock_name, ) =
            ( $util->retr_addr_port => $util->get_sock_name, );
        unless ($is_sock_tcp) {
            diag(     "Sleeping $timeout seconds to ensure socket"
                    . " has been created" );
            my $sock_rv = 0;
            foreach ( 0 .. $timeout ) {
                $sock_rv = ( -S $sock_name );
                last if $sock_rv;
                sleep 1;
            }
            $rv &&= $sock_rv;
            ok( $rv => "Socket file existence: $sock_name", );
        }
        my $kill_rv = $util->kill_procsock($pid);
        ok( $kill_rv => "Finding if process $pid was killed", );
        $rv &&= $kill_rv;
    }
    if ($rv) {
        diag(     "Sleeping $timeout seconds to ensure pid file $pid_file"
                . " has been deleted" );
        my $pid_rv;
        for ( 1 .. $timeout ) {
            $pid_rv = not( -f $pid_file );
            last if $pid_rv;
            sleep 1;
        }
        $rv &&= $pid_rv;
        ok( $rv => "Finding if pid file $pid_file was deleted by daemon", );
        my $log_rv = (
                    ( -f $log_file )
                and
                ( ( stat $log_file )[ statnames_to_policy('size')->[0] ] > 0 )
        );
        $rv &&= $log_rv;
        ok( $rv => 'Finding if log file was left by daemon', );
    }
    $self->finalise($util);
    return $rv;
}

sub start_foreground {
    my ( $self => $util, ) = @_;
    my $rv = 1;
    my $ppid;
    my $timeout = $self->get_timeout;
    my ( $pid_file, $log_file ) = retr_file_names($util);
    if ($rv) {
        $rv &&= not( -f $pid_file );
        ok( $rv => "Finding if pid $pid_file file doesn't exist", );
    }
    if ($rv) {
        $ppid = get_fork_pid( $util->spawn_fcgi( 1, ), );
        $rv &&= $ppid;
        ok( $rv => 'Spawner initialisation', );
    }
    if ($rv) {
        diag(     "Sleeping $timeout seconds to ensure daemon"
                . " is still running" );
        my $dead_rv = 1;
        foreach ( 1 .. $timeout ) {
            $dead_rv = not( is_process_dead( $ppid, ) );
            last unless $dead_rv;
            sleep 1;
        }
        $rv &&= $dead_rv;
        ok( $rv => "FCGI spawned: pid $ppid", );

        # Ctrl-C
        if ( $rv and kill( INT => $ppid, ) ) {
            diag(     "Sleeping $timeout seconds to ensure daemon"
                    . " is not running" );
            my $dead_rv = 0;
            foreach ( 0 .. $timeout ) {
                $dead_rv = is_process_dead( $ppid, );
                last if $dead_rv;
                sleep 1;
            }
            $rv &&= $dead_rv;
            $util->kill_procsock($ppid);
            ok( $rv => "FCGI pid $ppid stopped", );
            $rv &&= not( -f $pid_file );
            ok( $rv => "Finding if pid file $pid_file doesn't exist", );
        }
    }
    $self->finalise($util);
    return $rv;
}

sub finalise {
    my ( $self => $util, ) = @_;
    my $conf_dname = $util->get_conf;
    croak("Can not open dir: $conf_dname")
        unless opendir my $conf_dh => $conf_dname;
    my @fnames = ();
    while ( my $fn = readdir $conf_dh ) {
        $fn = "$conf_dname/$fn";
        if ( $fn =~ m/\.(lck|sem)$/ ) { push @fnames => $fn; }
    }
    closedir $conf_dh;
    cmp_ok( @fnames, '==', 0,
        "Files not left from binary run: " . join ', ' => @fnames );
    $util->rm_files_if_exists;
}

sub retr_file_names {
    my $util = shift;
    my ( $pid_file, $log_file ) = map {
        my $s_name = "get_$_" . "_fname";
        $util->$s_name;
    } qw/pid log/;
    return ( $pid_file, $log_file );
}

1;
