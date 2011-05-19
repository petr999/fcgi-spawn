#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Basic;

use Moose;
use MooseX::FollowPBP;

use FCGI::Spawn::TestUtils;

extends( 'FCGI::Spawn::TestUtils::Client' );
my $p_default = cgi_output_parser( 'CGI' );
has( '+parser' => ( 'default'  => $p_default, ), );

1;
