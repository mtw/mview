# Copyright (C) 1998-2015 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

###########################################################################
#
# MULTAS parsing consists of repeat records of:
#
# BLOCK
#    LIST
#    ALIGNMENT
#
#
###########################################################################
package Bio::Parse::Format::MULTAS;

use vars qw(@ISA);
use strict;

@ISA = qw(Bio::Parse::Record);


#delimit full MULTAS entry
my $MULTAS_START          = '^Block';
my $MULTAS_END            = undef;

my $MULTAS_Null           = '^\s*$';#'

#MULTAS record types
my $MULTAS_BLOCK          = $MULTAS_START;
my $MULTAS_BLOCKend       = "(?:$MULTAS_BLOCK|$MULTAS_Null)";
my $MULTAS_LIST           = '^\s*\d+\s+seqs';
#my $MULTAS_LISTmid        = "^(?:SEED|USER>>)";
my $MULTAS_LISTmid        = "^(?:SEED|USER)";
my $MULTAS_LISTend        = "(?:(?:>>){0}|$MULTAS_BLOCKend)";
my $MULTAS_ALIGNMENT      = '(?:>>){0}';
my $MULTAS_ALIGNMENTend   = $MULTAS_BLOCKend;


#Consume one entry-worth of input on text stream associated with $file and
#return a new MULTAS instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    while ($parent->{'text'}->getline(\$line)) {

	#start of entry
	if ($line =~ /$MULTAS_START/o and $offset < 0) {
            $offset = $parent->{'text'}->startofline;
	    next;
	}

	#end of entry
	#if ($line =~ /$MULTAS_END/o) {
	#    last;
	#}
    }
    return 0   if $offset < 0;

    $bytes = $parent->{'text'}->tell - $offset;

    new Bio::Parse::Format::MULTAS(undef, $parent->{'text'}, $offset, $bytes);
}

#Parse one entry
sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    while (defined ($line = $text->next_line)) {

	#BLOCK lines
	if ($line =~ /$MULTAS_BLOCK/o) {
	    $text->scan_until($MULTAS_BLOCKend, 'BLOCK');
	    next;
	}

	#blank line or empty record: ignore
	if ($line =~ /$MULTAS_Null/o) {
	    next;
	}

	#terminal line: ignore
	#if ($line =~ /$MULTAS_END/o) {
	#    next;
	#}

	#default
	$self->warn("unknown field: $line");
    }

    $self->test_records(qw(BLOCK));

    $self;#->examine;
}


###########################################################################
package Bio::Parse::Format::MULTAS::BLOCK;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    while (defined ($line = $text->next_line)) {

	#BLOCK number
	if ($line =~ /$MULTAS_BLOCK\s+(\d+)/) {
	    $self->{'number'} = $1;
	    next;
	}

	#LIST lines
	if ($line =~ /$MULTAS_LIST/o) {
	    $text->scan_while($MULTAS_LISTmid, 'LIST');
	    next;
	}

#	#LIST lines
#	if ($line =~ /$MULTAS_LIST/o) {
#	    $text->scan_until($MULTAS_LISTend, 'LIST');
#	    next;
#	}

	#ALIGNMENT lines
	if ($line =~ /$MULTAS_ALIGNMENT/o) {
	    $text->scan_until($MULTAS_ALIGNMENTend, 'ALIGNMENT');
	    next;
	}

	#blank line or empty record: ignore
	if ($line =~ /$MULTAS_Null/o) {
	    next;
	}

	#default
	$self->warn("unknown field: $line");
    }

    $self->test_records(qw(LIST ALIGNMENT));

    $self;#->examine;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %d\n", 'number', $self->{'number'};
}


###########################################################################
package Bio::Parse::Format::MULTAS::BLOCK::LIST;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    $self->{'count'} = 0;
    $self->{'hit'}   = [];

    #ranked search hits
    while (defined ($line = $text->next_line)) {

	if ($line =~ /\s*(\d+)\s+seqs/) {
	    $self->{'count'} = $1;
	    next;
	}

	if ($line =~ /\s*
	    ((?:SEED|USER))              #source of sequence
	    #\s*>>\s*
	    \s*>+\s*
	    ([^=]+)                      #identifier
	    \s*=\s*
	    (.*)                         #description
	    /xo) {

	    $self->test_args(\$line, $1, $2, $3);

	    push @{$self->{'hit'}},
	    {
	     'type'    => $1,
	     'id'      => $2,
	     'desc'    => $3,
	    };

	    #strip leading, trailing, internal white space
	    $self->{'hit'}->[$#{$self->{'hit'}}]->{'id'} =~ s/\s//g;

	    next;
	}

	#default
	$self->warn("unknown field: $line");
    }

    if ($self->{'count'} != @{$self->{'hit'}}) {
	$self->warn("stated ($self->{'count'}) and parsed (@{[scalar @{$self->{'hit'}}]}) sequence count mismatch");
    }

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %d\n", 'count', $self->{'count'};
    foreach my $hit (@{$self->{'hit'}}) {
	foreach my $field (sort keys %$hit) {
	    printf "$x%20s -> '%s'\n", $field,  $hit->{$field};
	}
    }
}


###########################################################################
package Bio::Parse::Format::MULTAS::BLOCK::ALIGNMENT;

use vars qw(@ISA);

@ISA = qw(Bio::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	Bio::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);

    $self = new Bio::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new Bio::Parse::Scanner($self);

    my (@tmp, $i);

    $self->{'seq'}    = [];
    $self->{'length'} = 0;
    $self->{'count'}  = 0;

    while (defined ($line = $text->next_line)) {

	chomp $line; @tmp = split(//, $line);

	for ($i=0; $i<@tmp; $i++) {
	    push @{$self->{'seq'}->[$i]}, $tmp[$i];
	}
    }

    $self->{'length'} = @{$self->{'seq'}->[0]};
    $self->{'count'}  = @{$self->{'seq'}};

    #check alignments all same length, then make string
    foreach $i (@{$self->{'seq'}}) {
	if (@$i != $self->{'length'}) {
	    $self->warn("alignment lengths differ");
	}
	$i = join('', @$i);
    }

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %d\n", 'count',  $self->{'count'};
    printf "$x%20s -> %d\n", 'length', $self->{'length'};
    for (my $i=0; $i<@{$self->{'seq'}}; $i++) {
	printf("$x%20s[%d] -> '%s'\n", 'seq', $i+1, $self->{'seq'}->[$i]);
    }
}


###########################################################################
1;
