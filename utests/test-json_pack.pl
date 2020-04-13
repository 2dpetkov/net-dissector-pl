#!/usr/bin/perl

use Test::More;

use FindBin;
BEGIN {push @INC, "$FindBin::Bin/../libs"}

use strict;
use warnings;

use PacketProcessor qw(json_pack);
use JsonUtils qw(sparse);

my $variables;
my $json_conf;
my $packed;

#================================
#--- conditions
#================================

$variables = {};
$json_conf = '[{"condition":1,"json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Simple condition - true");

$variables = {};
$json_conf = '[{"condition":0,"json":"fail"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"Simple condition - false");

$variables = {var=>1};
$json_conf = '[{"condition":"$var","json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Simple condition - variable true");

$variables = {var=>0};
$json_conf = '[{"condition":"$var","json":"fail"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"Simple condition - variable false");

$variables = {var=>1};
$json_conf = '[{"condition":"$var","json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Simple condition - variable true");

$variables = {var=>0};
$json_conf = '[{"condition":"$var","json":"fail"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"Simple condition - variable false");

$variables = {var1=>2,var2=>3};
$json_conf = '[{"condition":"$var1 <= $var2","json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Complex condition - bool expression true");

$variables = {var1=>2,var2=>3};
$json_conf = '[{"condition":"$var1 > $var2","json":"fail"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"Complex condition - bool expression false");

$variables = {var1=>2,var2=>3};
$json_conf = '[{"condition":"$var1 + $var2 > 4","json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Complex condition - math expression true");

$variables = {var1=>2,var2=>3};
$json_conf = '[{"condition":"$var1 * $var2 < 4","json":"fail"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"Complex condition - math expression false");

$variables = {var1=>2,var2=>3};
$json_conf = '[{"condition":"($var1 == 2)&&($var2 != 2)","json":"success"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success"]',"Complex condition - true and true");

$variables = {var1=>2,var2=>3};
$json_conf = '[
    {"condition":1,"json":"success-1"},
    {"condition":0,"json":"fail-1"},
    {"condition":"$var1 > 2","json":"fail-2"},
    {"condition":"$var2 > 2","json":"success-2"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'["success-1","success-2"]',
    "Multiple conditions");

$variables = {};
$json_conf = '[
    {"condition":0,"json":"fail-1"},
    {"condition":0,"json":"fail-2"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[]',"No true condition");

#================================
#--- complex json - no variables
#================================

$variables = {};
$json_conf = '[{"condition":1,"json":{"var":"value"}}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[{"var":"value"}]',"JSON Object");

$variables = {};
$json_conf = '[
    {"condition":1,"json":{"var1":"value1"}},
    {"condition":1,"json":{"var2":2}}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[{"var1":"value1"},{"var2":2}]',"Two JSON Objects");

$variables = {};
$json_conf = '[{"condition":1,"json":{"obj":{"sub1":{"val":1}}}}]';
$packed = json_pack(sparse($json_conf),$variables);
is(
    $packed,
    '[{"obj":{"sub1":{"val":1}}}]',
    "Complex JSON Object"
);

$variables = {};
$json_conf = '[
    {"condition":1,"json":[1,"2",{"three":3}]},
    {"condition":1,"json":{"arr1":[1,"2",{"three":3}]}},
    {"condition":1,"json":{"arr2":[{"one":{"two":{"three":3}}}]}}]';
$packed = json_pack(sparse($json_conf),$variables);
is(
    $packed,
    '[[1,2,{"three":3}],{"arr1":[1,2,{"three":3}]},{"arr2":[{"one":{"two":{"three":3}}}]}]',
    "JSON Arrays"
);

#================================
#--- complex json - with variables
#================================

$variables = {var1=>123};
$json_conf = '[{"condition":1,"json":"$var1"}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[123]',"JSON with variable");

$variables = {var1=>123};
$json_conf = '[{"condition":1,"json":{"obj":"$var1"}}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[{"obj":123}]',"JSON object with variable");

$variables = {var1=>111,var2=>222};
$json_conf = '[{"condition":1,"json":{"obj":{"sub":"$var1+$var2"}}}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[{"obj":{"sub":333}}]',
    "Multilevel JSON objects with expression");

$variables = {var1=>3};
$json_conf = '[{"condition":1,"json":[1,2,"$var1"]}]';
$packed = json_pack(sparse($json_conf),$variables);
is($packed,'[[1,2,3]]',"JSON array with variable");

$variables = {var1=>1,var2=>2,var3=>3};
$json_conf = '[
    {
        "condition":1,
        "json":[
            {"obj1":["$var1","$var2","$var3"]},
            {"obj2":[{"one":"$var1"},"two","$var3"]},
            {"obj3":{"one":[1,{"all":["$var1+$var2*$var3"]}]}}
        ]
    }
]';
$packed = json_pack(sparse($json_conf),$variables);
is(
    $packed,
    '[[{"obj1":[1,2,3]},{"obj2":[{"one":1},"two",3]},{"obj3":{"one":[1,{"all":[7]}]}}]]',
    "JSON array with JSON objects with variables"
);


done_testing(22);
