#!/usr/bin/perl

# Author: Dimitar Petkov > dimitar.petkov.ddp@gmail.com

use strict;
use warnings;

use LWP::UserAgent;

my $host_header = shift;
my $resource = shift;
my $msisdn = shift;

die "Usage: ".$0." <host_header> <resource> <msisdn>\n"
    unless defined $host_header
    and defined $resource
    and defined $msisdn;

my $url = "http://$resource/?msisdn=$msisdn";

my $user_agent = new LWP::UserAgent;
$user_agent->proxy('http', "http://127.0.0.1:8080/");

my $request = new HTTP::Request 'GET' => "$url";
$request->header('Host' => "$host_header");
$request->header('MSISDN' => "$msisdn");

my $response = $user_agent->request($request);
if ($response->is_success) {
    print $response->content;
} else {
    print "Error: " . $response->status_line . "\n";
} 
