#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 29;
use Test::More::UTF8;

use_ok( 'Apache::Fake' );

# simulated packages
foreach ( qw?Apache2/Response Apache2/RequestRec
        Apache2/RequestUtil Apache2/RequestIO APR/Pool APR/Table
        Apache2/SizeLimit ModPerl/RegistryLoader ModPerl/Registry Apache2/Const
        ModPerl ModPerl/Util Apache/Cookie Apache2/Cookie APR/Request
        APR/Request/Apache2 Apache2/Request ModPerl/Const APR/Date Apache2/Upload
        Apache Apache/Constants Apache/Request Apache/Log Apache/Table mod_perl
        Apache/Status Apache2/ServerUtil? )
    {
    my $pkg = ( $_ =~ s%/%::%rg );
    use_ok( $pkg );
}

done_testing;
