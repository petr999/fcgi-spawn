#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Post::Serialize_CF;

use Moose;
use MooseX::FollowPBP;

extends(
          'FCGI::Spawn::TestUtils::Client::Post::Serialize',
          'FCGI::Spawn::TestUtils::Client::Serialize_CF',
);

1;
