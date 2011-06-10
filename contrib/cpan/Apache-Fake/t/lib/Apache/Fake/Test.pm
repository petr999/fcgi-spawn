package Apache::Fake::Test;

use strict;
use warnings;

use IPC::Open3;
use Symbol 'gensym';
use IO::Select;
use Const::Fast;
use Perl6::Export::Attrs;

const( my $timeout => 30 );
const( my $buf_len => 16384 );

# Function
# Pipes variables from/to a file executed with perl interpreter
# Takes: perlfile name to be executed, and optional content to be piped to its
# STDIN
# Depends: on environment according to piped file contents
# Returns: STDOUT and STDERR contents
sub passthru_open3 : Export(:DEFAULT) {
    my ( $piped => $content ) = @_;
    $piped = "$^X $piped";

    # Open pipe
    my ( $write, $read, $err );
    $err = gensym();
    die("Can not open pipe: $!")
        unless open3( $write, $read, $err, $piped );
    my $str     = '';
    my $str_err = '';

    # Set up I/O selectors
    my $sel = IO::Select->new( $read, $err );
    my $wr_sel = IO::Select->new($write);
    if ( defined($content) and length $content ) {
        while ( my ($hdl) = $wr_sel->can_write($timeout) ) {
            print $hdl $content;
            last;
        }
    }

    # Read the command output
    while ( my @hdls = $sel->can_read ) {
        while ( my $hdl = shift @hdls ) {
            if ( $hdl ~~ $err ) {
                my $rv = read $hdl, $str_err, $buf_len, length $str_err;
            }
            elsif ( $hdl ~~ $read ) {
                my $rv = read $hdl, $str, $buf_len, length $str;
            }
            if ( eof $hdl ) { $sel->remove($hdl) }
        }
    }

    return ( $str => $str_err, );
}

1;
