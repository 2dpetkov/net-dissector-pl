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


package JsonUtils;

use JSON;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);


my $myclass;
BEGIN {
    $myclass = __PACKAGE__;
    $VERSION = "0.01";
}
sub Version () { "$myclass v$VERSION" }

BEGIN {
    @ISA = qw(Exporter);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)

    @EXPORT = qw(
    );

# Other items we are prepared to export if requested

    @EXPORT_OK = qw(
        fparse
        sparse
        tojson
    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
);

}

#---------------------------------------------------------------------------

sub fparse {
    my ($fname) = @_;
    
    my $fdata = do { #read the json file and return its content
        open (my $fh, "<:encoding(UTF-8)", $fname)
            or die "Cannot open JSON file '".$fname."': ".$!;
        local $/; #do not read line-by-line (e.g. read in 'slurp' mode)
        <$fh> #that's the result of the 'do BLOCK'
    };
    
    return sparse($fdata);
}

#---------------------------------------------------------------------------

sub sparse {
    my ($sdata) = @_;
    
    my $phash;
    eval { # decode_json may die with the ugly error in $@
        $phash = JSON::decode_json $sdata;
        1;
    } or die "Cannot parse JSON data:\n".$@;
    
    return $phash;
}

#---------------------------------------------------------------------------

sub tojson {
    my ($phash) = @_;
    
    my $sdata;
    eval {
        $sdata = JSON::encode_json $phash;
        1;
    } or die "Cannot convert perl hash to JSON string:\n".$@;
    
    return $sdata;
}

#---------------------------------------------------------------------------

1;
