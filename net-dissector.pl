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
        "Usage: ".$0." [OPTIONS] CONFIG_FILE\n"
        ."  Dissects sniffed Network packets and outputs parsed fields in JSON format."
        ."\n\n"
        ."CONFIG_FILE: \n"
        ."  A JSON formatted configuration file, that determines how captured data should be parsed \n"
        ."  and outputted."
        ."\n\n"
        ."Options:\n"
        ."  -i, --interface=INTERFACE     Network Interface to stiff on. Default: 'any'.\n"
        ."  -p, --promisc                 Brings the Interface to promiscuous mode. Default behavior.\n"
        ."  -nop, --nopromisc             Disables promiscuous mode for the Interface.\n"
        ."  -f, --filter=FILTER           Filter to pass to libpcap.\n"
        ."                                Example: --filter='port 53' - capture DNS traffic only.\n"
        ."  -h, --help                    Print this help message and exit.\n";
}

my $help = '';
my $interface = 'any';
my $promisc = 1;
my $filter = '';
GetOptions (
    'help' => \$help, 
    'interface=s' => \$interface, 
    'promisc!' => \$promisc,
    'filter=s' => \$filter );

my ($config_fname) = @ARGV;

if ($help or !defined $config_fname) {
    print_usage();
    exit 0; 
}

#---------------------------------------------------------------------------
# Main

my $config = JsonUtils::fparse($config_fname);

my $err_msg = Net::PcapUtils::loop(
    \&PacketProcessor::process, USERDATA => $config,
    DEV => $interface,
    PROMISC => $promisc,
    FILTER => $filter,
    SNAPLEN => 65536 );

# Unless an error has occured, Net::PcapUtils::loop should not return
print STDERR $err_msg."\n";
exit 1;



