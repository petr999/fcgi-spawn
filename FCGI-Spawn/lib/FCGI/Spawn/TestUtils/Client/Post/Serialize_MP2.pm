#!/usr/bin/perl

package FCGI::Spawn::TestUtils::Client::Post::Serialize_MP2;

use Moose;
use MooseX::FollowPBP;

extends(
          'FCGI::Spawn::TestUtils::Client::Post::Serialize',
          'FCGI::Spawn::TestUtils::Client::Serialize_MP2' 
);

1;
