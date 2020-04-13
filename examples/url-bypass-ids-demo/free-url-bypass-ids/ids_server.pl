#!/usr/bin/perl

# Author: Dimitar Petkov > dimitar.petkov.ddp@gmail.com

use IO::Socket::INET;
use JSON;

use strict;
use warnings;

use Data::Dumper;

my ($host,$port) = (shift,shift);

die "Usage: ".$0." <host> <port>\n" 
    unless defined $host
    and defined $port;

my $socket = new IO::Socket::INET (
    LocalHost => $host,
    LocalPort => $port,
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
) or die "Cannot create socket: $!\n";

print "IDS Started\n";


while(1)
{
    my $client_socket = $socket->accept();

    my $line = "";
    while (<$client_socket>) {
        $line .= $_;
        if ($line =~ /\r\n$/) {
            #print $line;
            my $json = JSON::decode_json $line;
            #print Dumper($json);
            
            my $timestamp = $json->[0]->[0];
            
            my $ip_data = $json->[0]->[1];
            my $http_data = $json->[0]->[2];
            
            my $host_header = $http_data->{'HOST'}->[0];
            my $get_url = $http_data->{'GET-URL'}->[0];
            my $msisdn = $http_data->{'MSISDN'}->[0];

            unless ($get_url =~ /^http:\/\/$host_header.*/) {
                print "$timestamp: URL Bypass Attack detected from IP ["
                    .$ip_data->{'ip-src'}."], MSISND [".$msisdn."]\n";
            }
            
            $line = "";
        }
    }
}

$socket->close();
