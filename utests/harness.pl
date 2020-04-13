#!/usr/bin/perl

use Test::Harness;

use strict;
use warnings;

runtests(
    "test-JsonUtils.pl",
    "test-packet_unpack.pl",
    "test-json_pack.pl",
    "test-process.pl"
);
