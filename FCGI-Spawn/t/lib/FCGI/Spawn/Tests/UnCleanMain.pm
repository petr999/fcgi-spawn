package FCGI::Spawn::Tests::UnCleanMain;

use Moose;
use MooseX::FollowPBP;

use JSON;
use Digest::MD5 'md5_base64';
use Sub::Name;

use FCGI::Spawn::TestUtils;

extends('FCGI::Spawn::Tests::CleanMain');

with( 'FCGI::Spawn::Tests::RoleNegative', );

has( '+descr' =>
        ( 'default' => 'Not cleaning global variables from CGI programs', ),
);

__PACKAGE__->meta->make_immutable;

1;
