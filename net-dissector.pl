#!/usr/bin/perl

# Author: Dimitar Petkov > dimitar.petkov.ddp@gmail.com

use FindBin;
BEGIN {push @INC, "$FindBin::Bin/libs"}

require Net::PcapUtils; #./libs/Net/PcapUtils.pm
require JsonUtils;
require PacketProcessor;

use JSON;
use Getopt::Long;

use strict;
use warnings;

# Autoflush STDOUT
$| = 1;

#---------------------------------------------------------------------------
# Signal handlers

use sigtrap qw/handler sig_handler normal-signals/;

sub sig_handler {
    die "Exiting on signal '".$!."'\n";
}

#---------------------------------------------------------------------------
# CLI Options

sub print_usage { 
    print 
        "\n"
        ."Usage: ".$0." [OPTIONS] CONFIG_FILE\n"
        ."  Dissects sniffed Network packets and outputs parsed fields in JSON format."
        ."\n\n"
        ."CONFIG_FILE: \n"
        ."  A JSON formatted configuration file, that determines how captured data should be parsed \n"
        ."  and outputted."
        ."\n\n"
        ."Options:\n"
        ."  -l, --list                    List all available network devices end exit.\n"
        ."\n"
        ."  -i, --interface=INTERFACE     Network Interface to sniff on. Either -i or -r must be specified.\n"
        ."                                  Example (Windows): -i \\Device\\NPF_{00000000-0000-0000-0000-000000000000}\n"
        ."                                  Example (Linux):   -i eth0\n"
        ."  -s, --savefile=FILE           A pcap file to read. Either -i or -r must be specified.\n"
        ."  -p, --promisc                 Brings the Interface to promiscuous mode. Default behavior.\n"
        ."  -nop, --nopromisc             Disables promiscuous mode for the Interface.\n"
        ."  -f, --filter=FILTER           Filter to pass to libpcap.\n"
        ."                                  Example: --filter='port 53' - capture DNS traffic only.\n"
        ."\n"
        ."  -h, --help                    Print this help message and exit.\n";
}

sub get_alldevs {
    my %devinfo;
    my $err = "";
    Net::Pcap::pcap_findalldevs(\%devinfo, \$err) or die "Error finding all devices: $err \n";
    return %devinfo;
}

my $help = '';
my $list = 0;
my $interface = '';
my $savefile = '';
my $promisc = 1;
my $filter = '';
GetOptions (
    'help' => \$help, 
    'list' => \$list, 
    'interface=s' => \$interface, 
    'savefile=s' => \$savefile, 
    'promisc!' => \$promisc,
    'filter=s' => \$filter );

my ($config_fname) = @ARGV;

#---------------------------------------------------------------------------
# List Interfaces

my %devinfo = get_alldevs();

if ($list) {
    for my $dev (keys %devinfo) {
        print "$dev $devinfo{$dev}\n";
    }
    exit 0;
}

#---------------------------------------------------------------------------
# Help

if ($help) {
    print_usage();
    exit 0; 
}

if (!defined $config_fname) {
    print "--------------------------\n";
    print "ERROR: Missing CONFIG_FILE\n";
    print "--------------------------\n";
    print_usage();
    exit 1; 
}

if (($interface eq "" and $savefile eq "")) {
    print "----------------------------------------\n";
    print "ERROR: Either -i or -s must be specified\n";
    print "----------------------------------------\n";
    print_usage();
    exit 1; 
}

if ($interface ne "" and $savefile ne "") {
    print "----------------------------------------------------\n";
    print "ERROR: Both -i or -s cannot be used at the same time\n";
    print "----------------------------------------------------\n";
    print_usage();
    exit 1; 
}

#---------------------------------------------------------------------------
# Main

my $config = JsonUtils::fparse($config_fname);

my $err_msg = Net::PcapUtils::loop(
    \&PacketProcessor::process, USERDATA => $config,
    DEV => $interface,
    SAVEFILE => $savefile,
    PROMISC => $promisc,
    FILTER => $filter,
    SNAPLEN => 65536 );

# Unless an error has occured, Net::PcapUtils::loop should not return
print STDERR $err_msg."\n";
exit 1;



