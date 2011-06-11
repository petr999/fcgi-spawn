package XStats;

use strict;
use warnings;

use Perl6::Export::Attrs;
use File::Slurp;

my $fn;

sub make_tref : Export( :DEFAULT ) {
    my $tl_arr = [ read_file($fn) ];
    my $name   = '';
    if ( $$tl_arr[0] =~ m/<include\s+(.+)\s*>/ ) {
        $name = read_file($1);
    }
    my $tmpl = $$tl_arr[1];
    chomp $tmpl;
    my $rv = [ sprintf $tmpl => $name, ];
    return $rv;
}

sub make_sref : Export( :DEFAULT ) {
    my $tmpl = read_file($fn);
    my $rv = [ sprintf $tmpl => 'ITIS', ];
    return $rv;
}

sub set_fn : Export( :DEFAULT ) {
    $fn = shift;
}

1;
