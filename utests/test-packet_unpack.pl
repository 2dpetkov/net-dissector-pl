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

use PacketProcessor qw(packet_unpack);
use JsonUtils qw(sparse);

my $packet;
my $json_conf;
my $variables;

#================================
#--- value
#================================

$packet = undef;
$json_conf = '[
{"name":"var1", "value":123},
{"name":"var2", "value":"simple text"}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is_deeply(
    $variables,
    {var1=>123,var2=>"simple text"},
    "Parse value Variables"
) or diag explain $variables;

#================================
#--- expr
#================================

$packet = undef;
$json_conf = '[
{"name":"var1", "expr":123},
{"name":"var2", "expr":"39 + 3"},
{"name":"var3", "expr":"$var1 + $var2"},
{"name":"var4", "expr":"\"test str\""},
{"name":"var5", "expr":"other str"},
{"name":"var6", "expr":"substr(\"abcd\",1,2)"}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is_deeply(
    $variables,
    {
        var1=>123,
        var2=>42,
        var3=>165,
        var4=>"test str",
        var5=>"other str",
        var6=>"bc"
    },
    "Parse expression Variables"
) or diag explain $variables;

#================================
#--- regex
#================================

$packet = "123456789";
$json_conf = '[
{"name":"var1", "regex":"(\\\\d\\\\d\\\\d)"},
{"name":"var2", "regex":"^.*([6541]{3,}).*$"}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is_deeply(
    $variables,
    {var1=>[123,456,789],var2=>[456]},
    "Parse Simple regex Variables"
) or diag explain $variables;

#================================
#--- regex
#================================

$packet = 'POST www.test.url/what?p1=a&p2=b HTTP/1.1'."\r\n"
.'Connection: keep-alive'."\r\n"
.'Host: test.host'."\r\n"
.'Accept: text/html,*/*;q=0.8'."\r\n"
.'Content-Length: 5'."\r\n"
."\r\n"
.'ab123';
$json_conf = '[
{"name":"var1", "regex":"^POST (.*) HTTP/1.1\\\\r\\\\n"},
{"name":"var2", "regex":"[Hh]ost: ([^\\\\r\\\\n]*)"},
{"name":"var3", "regex":"[cC]ontent-[lL]ength: (\\\\d*)"},
{"name":"var4", "regex":"(\\\\r\\\\n){2}(.*)"}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is_deeply(
    $variables,
    {
        var1=>["www.test.url/what?p1=a&p2=b"],
        var2=>["test.host"],
        var3=>[5],
        var4=>["\r\n","ab123"]
    },
    "Parse regex Variables from HTTP Text"
) or diag explain $variables;

#================================
#--- offset and length
#================================

$packet = "Test 12345.";
$json_conf = '[
{"name":"var1"},
{"name":"var2","length":0},
{"name":"var3","length":5},
{"name":"var4","length":100},
{"name":"var5","offset":0},
{"name":"var6","offset":0,"length":0},
{"name":"var7","offset":0,"length":5},
{"name":"var8","offset":0,"length":100},
{"name":"var9","offset":5},
{"name":"var10","offset":5,"length":0},
{"name":"var11","offset":5,"length":5},
{"name":"var12","offset":5,"length":100},
{"name":"var13","offset":100},
{"name":"var14","offset":100,"length":0},
{"name":"var15","offset":100,"length":5},
{"name":"var16","offset":100,"length":100}]';
$variables = packet_unpack(sparse($json_conf),$packet);
is_deeply(
    $variables,
    {
        var1=>'Test 12345.',
        var2=>'',
        var3=>'Test ',
        var4=>'Test 12345.',
        var5=>'Test 12345.',
        var6=>'',
        var7=>'Test ',
        var8=>'Test 12345.',
        var9=>'12345.',
        var10=>'',
        var11=>'12345',
        var12=>'12345.',
        var13=>'',
        var14=>'',
        var15=>'',
        var16=>''
    },
    "Parse Offset+Length Variables"
) or diag explain $variables;

#================================
#--- variable offset and length
#================================

$packet = "12345 Test.";
$json_conf = '[
{"name":"offset","value":6},
{"name":"length","value":4},
{"name":"text","offset":"$offset","length":"$length"}]';
$variables = packet_unpack(sparse($json_conf),$packet);
is(
    $variables->{'text'},
    "Test",    
    "Parse variable Offset and Length Variables"
) or diag explain $variables;

#================================
#--- binary
#================================

$packet = pack("C*",0x7a,0x7a,0x7a,0x01,0xff);
$json_conf = '[
{"name":"var1", "offset":0, "length":2},
{"name":"var2", "offset":2, "length":1, "unpack":"C"},
{"name":"var3", "offset":2, "length":1, "unpack":"a"},
{"name":"var4", "offset":3, "length":1, "unpack":"C*"},
{"name":"var5", "offset":3, "length":2, "unpack":"n"},
{"name":"var6", "unpack":"x1 a2"}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is($variables->{'var1'},'zz',"Text unpack");
is($variables->{'var2'},0x7a,"Byte unpack");
is($variables->{'var3'},'z',"Letter unpack");
is($variables->{'var4'},1,"Binary unpack");
is($variables->{'var5'},0x01ff,"Binary Sequence unpack");
is($variables->{'var6'},'zz',"Template Offset and Length unpack");

#================================
#--- process entire HTTP request 
#================================

$packet = 
    pack("C*",
        0x70,0x54,0xf5,0x77,0xf1,0x74,0x00,0x1e,    #ethernet
        0x65,0x43,0x6a,0x72,0x08,0x00,              #ethernet
        
        0x45,0x00,0x02,0x1c,0xbc,0xee,0x40,0x00,    #IP
        0x40,0x06,0x6a,0x8c,0xc0,0xa8,0x64,0x0a,    #IP
        0x05,0x99,0xe7,0x15,                        #IP
        
        0xdb,0x65,0x00,0x50,0xe4,0xc5,0x43,0x19,    #TCP
        0xe6,0x23,0x3d,0x39,0x80,0x18,0x00,0xe5,    #TCP
        0x32,0xa4,0x00,0x00,0x01,0x01,0x08,0x0a,    #TCP
        0x01,0xa5,0x00,0x03,0x12,0x6f,0x8b,0x25,    #TCP
    ).
    'GET /viewvc/collab-maint/ext-maint/wireshark/trunk/debian/README.Debian?view=markup HTTP/1.1'."\r\n"
    .'Host: anonscm.debian.org'."\r\n"
    .'Connection: keep-alive'."\r\n"
    .'Cache-Control: max-age=0'."\r\n"
    .'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'."\r\n"
    .'User-Agent: Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36'."\r\n"
    .'Accept-Encoding: gzip, deflate, sdch'."\r\n"
    .'Accept-Language: en-US,en;q=0.8,bg;q=0.6,fr;q=0.4'."\r\n"
    .'If-None-Match: W/"25451"'."\r\n"
    ."\r\n";
$json_conf = '[
{"name":"eth_dest","offset":0,"length":6,"unpack":"H*"},
{"name":"eth_source","offset":6,"length":6,"unpack":"C6"},
{"name":"eth_type","offset":12,"length":2,"unpack":"n"},

{"name":"ip_ver_ihl","offset":14,"length":1,"unpack":"C"},
{"name":"ip_version","expr":"$ip_ver_ihl >> 4"},
{"name":"ip_ihl_bytes","expr":"($ip_ver_ihl & 0x0f)*32/8"},

{"name":"ip_ds_fields","offset":15,"length":1,"unpack":"C"},
{"name":"ip_dscp","expr":"$ip_ds_fields >> 2"},
{"name":"ip_ecn","expr":"$ip_ds_fields & 0x03"},

{"name":"ip_length","offset":16,"length":2,"unpack":"n"},
{"name":"ip_id","offset":18,"length":2,"unpack":"n"},

{"name":"ip_flags","offset":20,"length":1,"unpack":"C"},
{"name":"ip_df","expr":"($ip_flags >> 6) & 0x01"},
{"name":"ip_mf","expr":"($ip_flags >> 5) & 0x01"},
{"name":"ip_fragment_offset","offset":21,"length":1,"unpack":"C"},

{"name":"ip_ttl","offset":22,"length":1,"unpack":"C"},
{"name":"ip_protocol","offset":23,"length":1,"unpack":"C"},
{"name":"ip_header_chsum","offset":24,"length":2,"unpack":"n"},

{"name":"ip_src","offset":26,"length":4,"unpack":"C4"},
{"name":"ip_dest","offset":30,"length":4,"unpack":"C4"},

{"name":"ip_opts","offset":34,"length":"$ip_ihl_bytes-20","unpack":"C*"},

{"name":"tcp_start","expr":"14+$ip_ihl_bytes"},

{"name":"tcp_src_port","offset":"$tcp_start+0","length":2,"unpack":"n"},
{"name":"tcp_dest_port","offset":"$tcp_start+2","length":2,"unpack":"n"},
{"name":"tcp_seq_num","offset":"$tcp_start+4","length":4,"unpack":"N"},
{"name":"tcp_ack_num","offset":"$tcp_start+8","length":4,"unpack":"N"},

{"name":"tcp_hl_flags","offset":"$tcp_start+12","length":2,"unpack":"n"},
{"name":"tcp_hl_bytes","expr":"($tcp_hl_flags >> 12)*32/8"},
{"name":"tcp_flags","expr":"$tcp_hl_flags & 0x1ff"},
{"name":"tcp_ack","expr":"($tcp_flags >> 4) & 0x01"},
{"name":"tcp_psh","expr":"($tcp_flags >> 3) & 0x01"},
{"name":"tcp_rst","expr":"($tcp_flags >> 2) & 0x01"},
{"name":"tcp_syn","expr":"($tcp_flags >> 1) & 0x01"},
{"name":"tcp_fin","expr":"($tcp_flags >> 0) & 0x01"},

{"name":"tcp_win","offset":"$tcp_start+14","length":2,"unpack":"n"},
{"name":"tcp_chsum","offset":"$tcp_start+16","length":2,"unpack":"n"},

{"name":"tcp_urg_ptr","offset":"$tcp_start+18","length":2,"unpack":"n"},
{
    "name":"tcp_opts",
    "offset":"$tcp_start+20",
    "length":"$tcp_hl_bytes-20","unpack":"C*"
},

{"name":"data_start","expr":"$tcp_start+$tcp_hl_bytes"},

{
    "name":"host_header",
    "offset":"$data_start",
    "regex":".*[hH]ost: ([^\\\\r\\\\n]*)\\\\r\\\\n"
},
{
    "name":"get_url",
    "offset":"$data_start",
    "regex":"^GET (.*) HTTP/1.1\\\\r\\\\n"
},
{
    "name":"destination_url",
    "expr":"\"http://www.\".$host_header->[0].$get_url->[0]"
}]';
$variables = packet_unpack(sparse($json_conf),$packet);

is($variables->{'eth_dest'},'7054f577f174','Ethernet Destination Address');
is_deeply(
    $variables->{'eth_source'},
    [0x00,0x1e,0x65,0x43,0x6a,0x72],
    'Ethernet Source Address'
) or diag explain $variables->{'eth_source'};
is($variables->{'eth_type'},0x0800,"Ethernet Type");

is($variables->{'ip_ver_ihl'},0x45,"IP version & IHL");
is($variables->{'ip_version'},0x4,"IP version");
is($variables->{'ip_ihl_bytes'},20,"IP IHL in bytes");

is($variables->{'ip_ds_fields'},0x00,"IP Differentiated Services Fields");
is($variables->{'ip_dscp'},0x00,"IP DS Codepoint");
is($variables->{'ip_ecn'},0x00,"IP Explicit Congestion Notification");

is($variables->{'ip_length'},540,"IP Total Length");
is($variables->{'ip_id'},0xbcee,"IP Identification");

is($variables->{'ip_flags'},0x40,"IP Flags");
is($variables->{'ip_df'},0x01,"IP Don't Fragment'");
is($variables->{'ip_mf'},0x00,"IP More Fragments");
is($variables->{'ip_fragment_offset'},0x00,"IP Fragment Offset");

is($variables->{'ip_ttl'},64,"IP Time to Live");
is($variables->{'ip_protocol'},6,"IP Protocol (6=TCP)");
is($variables->{'ip_header_chsum'},0x6a8c,"IP Header Checksum");

is_deeply(
    $variables->{'ip_src'},
    [192,168,100,10],
    'IP Source Address'
) or diag explain $variables->{'ip_src'};
is_deeply(
    $variables->{'ip_dest'},
    [5,153,231,21],
    'IP Destination Address'
) or diag explain $variables->{'ip_dest'};

is_deeply(
    $variables->{'ip_opts'},
    [],
    "IP Options"
) or diag explain $variables->{'ip_opts'};

is($variables->{'tcp_start'},34,"TCP Start position");

is($variables->{'tcp_src_port'},56165,"TCP Source Port");
is($variables->{'tcp_dest_port'},80,"TCP Destination Port");
is($variables->{'tcp_seq_num'},0xe4c54319,"TCP Sequence Number");
is($variables->{'tcp_ack_num'},0xe6233d39,"TCP Acknowledgment Number");

is($variables->{'tcp_hl_flags'},0x8018,"TCP Header Length + Flags");
is($variables->{'tcp_hl_bytes'},32,"TCP Header Length in bytes");
is($variables->{'tcp_flags'},0x18,"TCP Flags");
is($variables->{'tcp_ack'},0x01,"TCP ACK");
is($variables->{'tcp_psh'},0x01,"TCP PSH");
is($variables->{'tcp_rst'},0x00,"TCP RST");
is($variables->{'tcp_syn'},0x00,"TCP SYN");
is($variables->{'tcp_fin'},0x00,"TCP FIN");

is($variables->{'tcp_win'},229,"TCP Windows Size");
is($variables->{'tcp_chsum'},0x32a4,"TCP Checksum");

is($variables->{'tcp_urg_ptr'},0x00,"TCP Checksum");
is_deeply(
    $variables->{'tcp_opts'},
    [0x01,0x01,0x08,0x0a,0x01,0xa5,0x00,0x03,0x12,0x6f,0x8b,0x25],
    'TCP Options'
) or diag explain $variables->{'tcp_opts'};

is($variables->{'data_start'},66,"Data Start position");

is_deeply(
    $variables->{'host_header'},
    ["anonscm.debian.org"],
    "HTTP Host Header"
) or diag explain $variables->{'host_header'};
is_deeply(
    $variables->{'get_url'},
    ["/viewvc/collab-maint/ext-maint/wireshark/trunk/debian/README.Debian?view=markup"],
    "HTTP URL"
) or diag explain $variables->{'get_url'};
is(
    $variables->{'destination_url'},
    "http://www.anonscm.debian.org/viewvc/collab-maint/ext-maint/wireshark/trunk/debian/README.Debian?view=markup",
    "HTTP Destination URL"
);

done_testing(54);
