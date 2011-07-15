package FCGI::Spawn::Tests::StatsDeed;

use Moose;
use MooseX::FollowPBP;

use Carp;
use Const::Fast;

const my $DEED_ORIG => 'stats_deed_orig';
const my $DEED_CHNG => 'stats_deed_chng';

extends( 'FCGI::Spawn::Tests::ChangeCgi', );

has( '+descr' => (
		'default' =>
            'CGI script that was did earlier should not appear in another CGI'
			. ' output on stats change',
    )
);
has( 'cgi_basename' => qw/is rw isa Str default/ => $DEED_ORIG );
has( 'env' => (qw/is rw isa HashRef required 1 lazy 1 builder make_env/));

__PACKAGE__->meta->make_immutable;

sub make_cgi_basename {
	my $self = shift;
	my $cgi_basename = $self->get_cgi_basename;
	return $cgi_basename;
}

sub make_cgi {
    my ($self => $name) = @_;
    my $cmp_vals  = $self->get_cmp_vals;

    my $util    = $self->get_util;
    my $cgi_dir = $util->get_cgi_dir;
    my $cgi     = "$cgi_dir/$DEED_ORIG.cgi";

    my $cgi_contents = <<EOT;
#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

print "Content-type: text/plain\n\n".encode_json( [ "ITISORIG" ] );
EOT
	my $appendix = ' ' x rand(25);
	$cgi_contents .= $appendix;
    $self->write_file_contents( \$cgi_contents => $cgi, );

	unless( $name eq $$cmp_vals[0] ) {
		$self->set_cgi_basename( $DEED_CHNG );
	}
	my $env = $self->make_env;
	$self->set_env($env);
}

1;
