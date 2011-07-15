package FCGI::Spawn::BinUtils;

use strict;
use warnings;

use POSIX qw/WNOHANG/;
use English qw/$UID/;
use Perl6::Export::Attrs;
use Carp;
use Const::Fast;

# convinience for stats/x_stats policies for comparison of former and current;
# used in statnames_to_policy()
const(
    my $POLICIES => {
        qw/dev 0 ino 1 mode 2 nlink 3 uid 4 gid 5 rdev 6
            size 7 atime 8 mtime 9 ctime 10 blksize 11 blocks 12/
    },
);

# Inits shared memory variable to be used for variables shareed among forks,
# needed for time_limit feature
# Takes     :   reference to a scalar to be initialized, and a HashRef filled
#               with 'mm_size', 'mm_file' attributes for file size in bytes
#               and its name, and 'uid' for mm_permission()
# Depends   :   on IPC::MMA and if current user id is 0 for mm_premission()
#               to succeed
# Changes   :   initialized MM variable in ${ $_[0] }
# Throws    :   if IPC::MMA not found or if user id is 0 but mm_permission did
#               not succeed.
# Returns   :   n/a
sub _init_ipc {
    my ( $ipc_ref => $mm_scratch ) = @_;
    unless ( defined $$ipc_ref ) { # keep from second time

        # Create sharing
        croak("IPC::MMA: $@ $!") unless eval { require IPC::MMA; 1; };
        my $rv = $$ipc_ref =
            IPC::MMA::mm_create( map { $mm_scratch->{ $_ } }
                'mm_size' => 'mm_file', );
        croak("IPC::MMA init: $@ $!") unless $rv;

        # mm_permission() stuff
        my $uid = $mm_scratch->{ 'uid' };
        unless ($UID) {
            $rv = not IPC::MMA::mm_permission(
                $$ipc_ref => '0600',
                $uid      => -1,
            );

            # This croak is needed for shm test in chroot testkit too
            croak("SHM unpermitted for $uid: $!")
                unless $rv;    # Return value invert
        }
    }
}

# Makes a variable shared among forks
# Takes     :   ArrayRef[Ref] of two refs: reference to a variable to
#               share, it is a reference to SCALAR, ARRAY, or HASH, and a
#               reference to shared memory variable initialized with
#               _init_ipc(); the second parameter $_[1]is a HashRef the same
#               as for _init_ipc()
# Changes   :   references in the first argument, $_[0]
# Throws    :   if first element of the ArrayRef the first argument is not a
#               reference
# Returns   :   n/a
sub make_shared : Export( :scripts :testutils ) {
    my ( $refs, $mm_scratch, ) = @_;
    my ( $ref, $ipc_ref ) = @$refs;

    # Init shared vars
    &_init_ipc( $ipc_ref => $mm_scratch );
    my $type = lc ref $ref;
    croak("Not a ref: $ref") unless $type;

    # Define method and class
    my $method    = "mm_make_$type";
    my $tie_class = 'IPC::MMA::' . ucfirst $type;

    # use them both
    my $ipc_var   = $IPC::MMA::{ $method }->($$ipc_ref);
    tie( ( $type eq 'hash' ) ? %$ref : $$ref, $tie_class, $ipc_var );
}

# Makes subroutine to kill a a given process with a  given  signal  but  kills
# with TERM if the signal is INT. Used to redirect TERM in the fcgi_spawn main
# loop to the spoawned pid and to make the incoming INT to be the TERM sent to
# that pid
# Takes     :   signal name and process id.
# Returns   :   sub to be assinged as a %SIG value(s).
sub sig_handle : Export( :scripts ) {
    my ( $sig, $pid ) = @_;
    return sub {
        $sig = ( $sig eq 'INT' ) ? 'TERM' : $sig;
        kill $sig => $pid;
    };
}

# (Re)opens a log, changes standard handles to it.
# Takes     :   log file name
# Changes   :   STDIN handle to < /dev/null
# Throws    :   if log file can not be open or /dev/null does not exist
# Returns   :   n/a
sub re_open_log : Export( :scripts ) {
    my $log_file = shift;

    # Closing standard output handles
    close STDERR if defined fileno STDERR;
    close STDOUT if defined fileno STDOUT;

    # Opening log anew
    croak("Opening log $log_file: $!")
        unless open( STDERR, ">>", $log_file );
    croak("Opening log $log_file: $!")
        unless open( STDOUT, ">>", $log_file );

    # Closing current input
    croak("Can't read /dev/null: $!")
        unless open( STDIN, "<", '/dev/null' );
}

# Prints help and exits
# Takes     :   n/a
# Returns   :   n/a
sub print_help_exit : Export( :scripts ) {
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

# Defines if socket is a TCP socket, can return host and port parts
# Takes     :   string to mean a socket, like 'host.net:5555', '1.2.3.4:5556'
#               or 'host.com:5557'
# Returns   :   in scalar context: TCP socket; in array context: host/addr
#               and port parts
sub is_sock_tcp : Export( :modules :testutils ) {
    my $rv = shift =~ m/^([^:]+):([^:]+)$/;
    wantarray ? ( $1 => $2, ) : $rv;
}

# Takes     :   process id
# Depends   :   on waitpid with WNOHANG and a kill 0 implementation in OS;
# Returns   :   Boolean is process dead
sub is_process_dead : Export( :scripts :testutils ) {
    my $pid = shift;
    waitpid $pid => WNOHANG;
    my $rv = ( -1 == waitpid $pid => WNOHANG, )
        && ( 0 == kill 0 => $pid );
    return $rv;
}

# Same as is_sock_tcp() but returns always array anbd has additional chacks
# Takes     :   Str the socket name
# Returns   :   Array (host/addr) and port from the socket name
sub addr_port : Export( :testutils ) {
    my $sock_name = shift;
    my @rv        = is_sock_tcp( $sock_name, );
    my ( $addr => $port, ) = @rv;
    unless (defined($addr)
        and length($addr)
        and defined($port)
        and length($port) )
    {
        @rv = undef;
    }
    return @rv;
}

# Static function
# Turns the stat() file attributes from names to numbers
# Takes     :   optional name(s) of policies to take into account when decide
#               if file changed or not
# Depends   :   on $POLICIES constant
# Returns   :   array reference filled with numbers corresponding policy(ies)'
#               names
sub statnames_to_policy : Export( :modules :testutils ) {
    my $rv =
        grep( { $_ eq 'all' } @_ )
        ? [ 0 .. 7, 9 .. 12 ]
        : [ map { $$POLICIES{ $_ }; } @_ ];
    return $rv;
}

1;

__END__

=pod

=head1 NAME

FCGI::Spawn::BinUtils – small static functions for FCGI::Spawn.

=head1 VERSION
This documentation refers to L<FCGI::Spawn> version 0.17.

=head1 SYNOPSIS

For use in modules:

    use FCGI::Spawn::BinUtils :modules;

    # Follow 'stats' policy
    my $policy = statnames_to_policies( 'mtime' );

    # Unlink socket if it is a UNIX socket
    my $sock_name = '/tmp/spawner.sock';
    my $is_sock_tcp = &is_sock_tcp($sock_name);
    unless( $is_sock_tcp ) { unlink $sock_name }

For use in scripts:

    use FCGI::Spawn::BinUtils :scripts;

    my($addr => $port) = addr_port( 'host.net:5558' );

    my( $shared, $ipc ); $shared={};
    make_shared( [ $shared => \$ipc, ] =>
        { mm_size => $mm_size, mm_file => $mm_file, uid => $uid, },
    );

    print_help_exit(); # exits here
    # delete the previous line or the following will not be executed
    re_open_log( '/path/to/file.log' );
    

=head1 DESCRIPTION

Some of the functions commonly used in L<FCGI::Spawn> require no
persistence/OOP but certain module(s) to interact with OS. Some of them are
useful for testing, too. Such a facilities sould be incapsulated in a
separate module.

=head1 FUNCIONS

=head2 statnames_to_policy( 'mtime', 'ctime', ... );

Convert the list of file inode attributes' names checked by stat() builtin to
the list of numbers for it described in the C<'stat'> .  In the case if the
special word 'all' if met on the list, all the attributes are checked besides
'atime' (8).

Also, you can define the order in which the C<'FCGI::Spawn::stats'> are
checked to reload perl modules: if the change is met, no further checks of
this list for particular module on particular request are made as a decision
to recompile that source is already taken.

This is the convenient way to define the modules reload policy, the
C<'FCGI::Spawn::stat_policy> object property, among with the need in modules'
reload itself by the C<'FCGI::Spawn::stats'> property checked as boolean only.

=head2 make_shared($refs => $mm_scratch);

where
    
    $refs = [ Ref, Ref ]; 

- uninitialized references to wanted varable (scalar or array or hash) to be
shared among forks, and to a scalar, the L<IPC::MMA> variable,
correspondently; That second variable should be of the same context as the
first.

    $mm_scratch = { 'mm_file' => '/path/to/mm_file.lck', 'mm_size' => 65535,
        'uid' => 12345,
    };

- HashRef defining values for C<'IPC::MMA::mm_create'> and
C<'IPC::MMA::mm_permission'>

=head2 re_open_log( '/path/to/file.log' );

Detach from current terminal and open the log from scratch. Can be used in
conmjunvtion with the log rotator, too.

=head2 print_help_exit();

Prints help on L<fcgi_spawn> and exits.

=head1 DIAGNOSTICS

Any problems with terminal handles: STDIN, STDOUT and STDERR can cause the
process to die. Also, L<IPC::MMA> function can have issues on use, like the
one known with mm_permission available only for root.

=head1 CONFIGURATION AND ENVIRONMENT

The whole C<make_shared> and C<_init_ipc> feature is supposed to be used only
if L<FCGI::Spawn/time_limit> knob is in use, and its implementations depends
on if the current user id is 0, too.

=head1 DEPENDENCIES

L<Carp>, L<POSIX>, L<English> included in Perl core distribution.

L<Perl6::Export::Attrs>, L<Const::Fast>, and an L<IPC::MMA> for the case if
you use the L<FCGI::Spawn/time_limit> feature, all available from CPAN.

=head1 BUGS AND LIMITATIONS

There may be known bugs and issues in this module. More info at:
L<http://bugs.vereshagin.org/product/FCGI%3A%3ASpawn> .

Please report problems to L<http://bugs.vereshagin.org> or to the L</AUTHOR>.
Patches are welcome.

=head1 AUTHOR

Peter Vereshagin <peter@vereshagin.org> (http://vereshagin.org).

More info about L<FCGI::Spawn>: http://fcgi-spawn.sf.net

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011 Peter Vereshagin <peter@vereshagin.org>.
All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut
