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


package PacketProcessor;

use Clone 'clone';

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
        process
        packet_unpack
        json_pack
    );

# Tags:

    %EXPORT_TAGS = (
    ALL         => [@EXPORT, @EXPORT_OK],
);

}

#---------------------------------------------------------------------------

sub process {
    my ($config, $header, $packet) = @_;

    my $pkt_variables = packet_unpack($config->{'input'}, $packet);
    my $str_json_out = json_pack($config->{'output'},$pkt_variables);
    
    print STDOUT $str_json_out."\r\n" if $str_json_out ne "[]";
}

#---------------------------------------------------------------------------

sub packet_unpack {
    my ($_config_variables,$_packet) = @_;
    my $_pkt_variables = {};
    my $_pkt_length = length($_packet);
    $_pkt_length = 0 unless defined $_pkt_length;
    
    # enables hackish magic - adding variables to the context
    no strict 'vars', 'refs';
    no warnings;
    foreach my $_conf_var (@{$_config_variables}) {
        my $_var_name = $_conf_var->{'name'};
        my $_var_value;
    
        my $_offset = eval $_conf_var->{'offset'};
        $_offset = 0 unless defined $_offset;
        $_offset = $_pkt_length if $_offset > $_pkt_length;
        
        my $_length = eval $_conf_var->{'length'};
        $_length = $_pkt_length - $_offset
            if !defined $_length 
            or $_length > $_pkt_length;
        
        if (defined $_conf_var->{'value'}) {
            $_var_value = $_conf_var->{'value'};
        } elsif (defined $_conf_var->{'expr'}) {
            $_var_value = eval $_conf_var->{'expr'};
            $_var_value = $_conf_var->{'expr'} unless defined $_var_value;
        } elsif (defined $_conf_var->{'regex'}) {
            my $_regex = $_conf_var->{'regex'};
            
            my @_matches = (
                (substr $_packet, $_offset, $_length) =~ m/$_regex/sg
            );
            
            $_var_value = \@_matches;
        } else { #unpack a sub-section of the packet
            my $_unpack = $_conf_var->{'unpack'};
            $_unpack = "a*" unless defined $_unpack;
            
            my @_unpacked = unpack(
                $_unpack, 
                substr($_packet, $_offset, $_length)
            );

            if(scalar @_unpacked == 1) {
                $_var_value = $_unpacked[0];
            } else {
                $_var_value = \@_unpacked;
            }
        }

        # Magic. Add the variable to the current context
        $$_var_name = $_var_value;
    
        $_pkt_variables->{$_var_name} = $_var_value;
    }
    
    return $_pkt_variables;
}

#---------------------------------------------------------------------------

sub json_pack {
    my ($_config_output,$_variables) = @_;
    
    # enables hackish magic - adding variables to the context
    no strict 'vars', 'refs';
    no warnings;
    while (my ($_var_name, $_var_value) = each (%{$_variables})) {
        $$_var_name = $_var_value;
    }
    
    sub _sub_populate_json{
        my ($_json_ref) = @_;
        
        if (ref($_json_ref) eq "REF") {
            _sub_populate_json($$_json_ref);
        } elsif (ref($_json_ref) eq "ARRAY") {
            for my $i (1 .. @{$_json_ref}) {
                my $_json_value_ref = \($_json_ref->[$i-1]);
                _sub_populate_json($_json_value_ref);
            }
        } elsif (ref($_json_ref) eq "HASH") {
            foreach my $_json_name (keys %{$_json_ref}) {
                my $_json_value_ref = \($_json_ref->{$_json_name});
                _sub_populate_json($_json_value_ref);
            }
        } else {
            my $_evaluated = eval $$_json_ref;
            $$_json_ref = $_evaluated if defined $_evaluated;
        }
    };
    
    my @_output;
    foreach my $_conf_out (@{$_config_output}) {
        if( eval $_conf_out->{'condition'} ) {
            my $_json_packed = clone $_conf_out->{'json'};
            
            if (!ref($_json_packed)) {
                _sub_populate_json(\$_json_packed);
            } else {
                _sub_populate_json($_json_packed);
            }
            
            push @_output, $_json_packed;
        }
    }
    
    return JsonUtils::tojson(\@_output);
}

#---------------------------------------------------------------------------

1;
