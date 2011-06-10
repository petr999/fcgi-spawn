#!/usr/bin/env perl

=pod

This test tries to load the Apache/Fake.pm and proves that it can simulate its
packages. Some of the trivial functions can be tested here, too.

=cut

use strict;
use warnings;

use Test::More tests => 30;
use Test::More::UTF8;

use POSIX qw/strftime setlocale LC_ALL/;

setlocale( LC_ALL, 'C' );

use_ok('Apache::Fake');

# simulated packages
foreach (
    qw?Apache2/Response Apache2/RequestRec
    Apache2/RequestUtil Apache2/RequestIO APR/Pool APR/Table
    Apache2/SizeLimit ModPerl/RegistryLoader ModPerl/Registry Apache2/Const
    ModPerl ModPerl/Util Apache/Cookie Apache2/Cookie APR/Request
    APR/Request/Apache2 Apache2/Request ModPerl/Const APR/Date Apache2/Upload
    Apache Apache/Constants Apache/Request Apache/Log Apache/Table mod_perl
    Apache/Status Apache2/ServerUtil?
    )
{
    my $pkg = ( $_ =~ s/\//::/rg );
    use_ok($pkg);
}

# Parse the current date
my $moment   = time();
my $cmp_time = $moment * 1_000_000;
my $chk_time = strftime( '%a, %d %b %G %T GMT' => gmtime $moment );
is( APR::Date::parse_http($chk_time) => $cmp_time, 'Parse HTTP time' );

done_testing;
