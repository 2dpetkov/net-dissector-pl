#!/usr/bin/perl

use Test::More;
use Test::Output;

use FindBin;
BEGIN {push @INC, "$FindBin::Bin/../libs"}

use strict;
use warnings;

use PacketProcessor qw(process);
use JsonUtils qw(fparse);

my $config;
my $packet;

#================================
#--- overall processing
#================================
my $fname = "test-process.json";
$config = JsonUtils::fparse($fname);
$packet = "123456789\r\nabcd";
stdout_is(
    sub {PacketProcessor::process($config,undef,$packet);},
    '["value 1",["123","456","789"],"test\\ntest","123456789\\r\\nabcd"]'."\r\n",
    "Processing a packet - special characters" );


done_testing(1);
