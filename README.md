# net-dissector-pl
A Perl utility that uses LibPcap and a set of input JSON rules to parse packets captured on a network interface (or a .pcap file), and to extract certain elements of the stream into a set of JSON objects

## Running on windows
On Windows, you can run this under WSL, but bear in mind that sniffing on network interfaces within WSL isn't easy, so you might want to parse already captured .pcap files

## Building Net::Pcap
[PerlMonks](https://www.perlmonks.org/?node_id=1012508)

## Npcap library (replacing WinPcap)
[NMap](https://nmap.org/npcap/)

## From perl to exe
[Meta CPAN](https://metacpan.org/pod/PAR::Packer)
 
```
pp net-dissector.pl -o net-dissector.exe -M PerlIO::encoding -M Net::Pcap -M Net::PcapUtils -M AutoLoader -M Clone -I libs
```

Build .exe and run with parameter

```
pp net-dissector.pl -o net-dissector.exe -M PerlIO::encoding -M Net::Pcap -M Net::PcapUtils -M AutoLoader -M Clone -I libs -r conf-example.json
```

Also

```
pp net-dissector.pl -o net-dissector.exe -I libs
```

## License

This project is licensed under the GNU GPLv3 - see the [LICENSE](LICENSE) file for details
