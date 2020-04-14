# net-dissector-pl
A Perl utility that uses LibPcap and a set of input JSON rules to parse packets captured on a network interface (or a .pcap file), and to extract certain elements of the stream into a set of JSON objects

## Dependencies
Dependencies are also listed in [dep.list](dep.list) and [utests/dep.list](utests/dep.list) for easier access on the console

### ./Net/PcapUtils.pm
[Net-PcapUtils](http://search.cpan.org/dist/Net-PcapUtils/PcapUtils.pm)

### on Linux
```
libjson-perl libnet-pcap-perl libclone-perl
```

### on Windows
On Windows, you can run this under WSL, but bear in mind that sniffing on network interfaces within WSL isn't easy, so you might want to parse already captured .pcap files

```
TODO
```

### Unit tests deps
```
libtest-output-perl
```

## Accessing the help of the tool
```
./net-dissector.pl -h
```

## Example usage
If your active network interface is eth0, run  
```
sudo ./net-dissector.pl -i eth0 -p examples/conf-example.json
```

Then open a web browser and access a website, that is not using HTTPS. The script will output some captured and dissected packets on the stdout.
The example JSON parser simply extracts some data from the captured HTTP (not HTTPS) requests (not responses), including some fields from the underlying TCP packets, and suggests a way to arrange them in the output.

## Running the Unit tests
```
cd utests;

./harnes.pl;
```

## From perl to exe
[PAR::Packer](https://metacpan.org/pod/PAR::Packer)
 
```
pp net-dissector.pl -o net-dissector.exe -M PerlIO::encoding -M Net::Pcap -M Net::PcapUtils -M AutoLoader -M Clone -I libs
```

## License

This project is licensed under the GNU GPLv3 - see the [LICENSE](LICENSE) file for details
