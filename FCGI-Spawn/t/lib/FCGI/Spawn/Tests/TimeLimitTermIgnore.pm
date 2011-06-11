package FCGI::Spawn::Tests::TimeLimitTermIgnore;

use Moose;
use MooseX::FollowPBP;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::Tests::TimeLimit', );

has('+descr' => (
        'default' =>
            'Different value limit CGI execution time if CGI ignores TERM',
    ),
);

__PACKAGE__->meta->make_immutable;

sub on_time_out {
    my ( $self, $died => $pid, ) = @_;
    if   ($died) { $self->set_failure( "Process was dead: $pid", ); }
    else         { kill_proc_dead($pid); }
}

sub make_cgi_basename { my $self = shift; $self->get_name(@_); }

1;
