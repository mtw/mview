# Copyright (C) 1996-2015 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

######################################################################
package Bio::Parse::Message;

use strict;

#dump sorted list of all instance variables, or supplied list
sub examine {
    my $self = shift;
    my @keys = @_ ? @_ : sort keys %$self;
    my $key;
    print "Class $self\n";
    foreach $key (@keys) {
        printf "%16s => %s\n", $key,
	    defined $self->{$key} ? $self->{$key} : '';
    }
    $self;
}

#warn with error string
sub warn {
    my $self = shift;
    my $s = ref($self) ? ref($self) : $self;
    $s = "Warning $s: @_";
    chomp $s;
    warn "$s\n";
}

#exit with error string
sub die {
    my $self = shift;
    my $s = ref($self) ? ref($self) : $self;
    $s = "Died $s: @_";
    chomp $s;
    die "$s\n";
}


###########################################################################
1;
