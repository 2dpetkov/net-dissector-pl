#!/usr/bin/perl

# Author: Dimitar Petkov > dimitar.petkov.ddp@gmail.com

use strict;
use warnings;

{
package LightWebServer;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);


sub new {
    my ($class,$port,$family) = @_;
    my $self = $class->SUPER::new( $port, $family );

    @{$self->{'msisdn_whitelist'}} = qw(100 110 111);
    $self->{'urls'} = {
        'www.free.url' => "FREE URL accessed.",
        'www.paid.url' => "PAID URL accessed."
    };
    @{$self->{'free_urls'}} = qw(www.free.url);

    bless $self, $class;
    return $self;
}

sub header {
    my ($self,$header,$value) = @_;
    
    $self->{'headers'}->{lc $header} = $value;
}

sub handle_request {
    my ($self, $cgi) = @_;
    
    my $url = $cgi->path_info();
    $url =~ s/^http:\/\/([^\/]*).*/$1/;
    my $msisdn = $cgi->{'param'}->{'msisdn'}[0];
    my $host_header = $self->{'headers'}->{'host'};
    
    #print "Host:\t".$host_header."\n" if defined $host_header;
    #print "URL:\t".$url."\n" if defined $url;
    #print "MSISDN:\t".$msisdn."\n" if defined $msisdn;
    if (!defined $msisdn) {
        print STDERR "MSISDN NOT PROVIDED"."\n\n";
    } elsif (grep $_ eq $msisdn, @{$self->{'msisdn_whitelist'}}) {
        # Access whatever url is requested
        print $self->fetch_url($url)."\n";
    } else {
        # No credit. Only process if a free url requested
        if (grep $_ eq $host_header, @{$self->{'free_urls'}}) {
            print $self->fetch_url($url)."\n";
        } else {
            print "ACCESS DENIED!\n";
        }
    }
    
    $self->{'headers'} = {};
}

sub fetch_url {
    my ($self,$url) = @_;
    
    my $data = $self->{'urls'}->{$url};
    $data = "$url NOT FOUND." unless defined $data;
    
    return $data;
}

}

LightWebServer->new(8080)->run();
die "HTTP Server aborted.\n";
