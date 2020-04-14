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

use FindBin;
BEGIN {push @INC, "$FindBin::Bin/../libs"}

use strict;
use warnings;

use JsonUtils qw(fparse sparse tojson);

my $json_phash;
my $json_str;

#================================
#--- parsing a config file
#================================

my $fname = "test-conf.json";
$json_phash = fparse($fname);
is_deeply(
    $json_phash,
    {
        input=>[
            {name=>"var_value", value=>"test 123"},
            {name=>"var_expr", expr=>"\${var1} * 10"},
            {
                name=>"var_unpack", 
                offset=>15, 
                length=>"\${other_var}", 
                unpack=>"H*"
            },
            {
                name=>"var_regex", 
                offset=>5, 
                length=>100, 
                regex=>"[hH]ost:(.*)\\r\\n"
            }],
        output=>[
            {
                condition=>"\$var_value == \"test 123\"",
                json=>"\$var_value"},
            {
                condition=>"\$var_expr == 20",
                json=>{val=>"\$var_value",int=>"\$var_expr"}
            },
            {
                condition=>1,
                json=>"\@var_regex"
            }]
    },
    "Parsing JSON '$fname' into perl hash"
) or diag explain $json_phash;

#================================
#--- parsing a string
#================================

$json_str = 
'{
    "input":[
        {"name":"var1","value":15},
        {
            "name":"var2",
            "offset":"${var1}",
            "length":9,
            "regex":"[hH]ost:(.*)\\\\r\\\\n"
        }
    ],
    "output":[
        {
            "condition":"$var == \"test\"",
            "json":{"val1":"$var","val2":"@val"}
        }
    ]   
}';
$json_phash = sparse($json_str);
is_deeply(
    $json_phash,
    {
        input=>[
            {name=>"var1",value=>15},
            {
                name=>"var2",
                offset=>"\${var1}",
                length=>9,
                regex=>"[hH]ost:(.*)\\r\\n"
            }
        ],
        output=>[
            {
                condition=>"\$var == \"test\"",
                json=>{val1=>"\$var",val2=>"\@val"}
            }
        ]
    },
    "Parsing a JSON string into perl hash"
) or diag explain $json_phash;

#================================
#--- parsing a hash
#================================

$json_phash = {param=>111};
$json_str = tojson($json_phash);
is( $json_str, '{"param":111}',
    "JSON string from perl hash - number");

$json_phash = {param=>"str value"};
$json_str = tojson($json_phash);
is( $json_str, '{"param":"str value"}',
    "JSON string from perl hash - string");

$json_phash = {param=>[1,"2",{three=>3}]};
$json_str = tojson($json_phash);
is( $json_str, '{"param":[1,"2",{"three":3}]}',
    "JSON string from perl hash - array");

$json_phash = {param=>{subp=>222}};
$json_str = tojson($json_phash);
is( $json_str, '{"param":{"subp":222}}',
    "JSON string from perl hash - subhash");


done_testing(6);
