#!/usr/bin/perl

# Copyright (C) 2015  Dimitar Petkov <dimitar.petkov.ddp@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


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
