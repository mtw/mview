# Copyright (C) 1998-2015 Nigel P. Brown

# This file is part of MView. 
# MView is released under license GPLv2, or any later version.

###########################################################################
package Bio::Parse::Format::PIR;

use vars qw(@ISA);
use strict;

@ISA = qw(Bio::Parse::Record);


#PIR record types
my $PIR_Null     = '^\s*$';#'
my $PIR_SEQ      = '^\s*>';
my $PIR_SEQend   = $PIR_SEQ;


#Consume one entry-worth of input on text stream associated with $file and
#return a new PIR instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);

    while ($parent->{'text'}->getline(\$line)) {

	#start of entry
	if ($offset < 0) {
            $offset = $parent->{'text'}->startofline;
	    next;
	}

    }
    return 0   if $offset < 0;

    $bytes = $parent->{'text'}->tell - $offset;

    new Bio::Parse::Format::PIR(undef, $parent->{'text'}, $offset, $bytes);
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

	#SEQ lines
	if ($line =~ /$PIR_SEQ/o) {
	    $text->scan_until($PIR_SEQend, 'SEQ');
	    next;
	}

	#blank line or empty record: ignore
	if ($line =~ /$PIR_Null/o) {
	    next;
	}

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}


###########################################################################
package Bio::Parse::Format::PIR::SEQ;

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

    $self->{'prefix'} = '';
    $self->{'id'}     = '';
    $self->{'desc'}   = '';
    $self->{'seq'}    = '';

    while (defined ($line = $text->next_line(1))) {

	#read header line
	if ($line =~ /^\s*>\s*(..);(\S+)/o) {
	    $self->test_args(\$line, $1, $2);
	    (
	     $self->{'prefix'},
	     $self->{'id'},
	    ) = ($1, $2);

	    #force read of next line for description
	    $self->{'desc'} = $text->next_line(1);
            $self->{'desc'} = Bio::Parse::Record::strip_leading_space($self->{'desc'});
            $self->{'desc'} = Bio::Parse::Record::strip_trailing_space($self->{'desc'});

	    next;
	}

	#read sequence lines upto asterisk, if present
	if ($line =~ /([^\*]+)/) {
	    $self->{'seq'} .= $1;
	    next;
	}

	#ignore lone asterisk
	last    if $line =~ /\*/;

	#default
	$self->warn("unknown field: $line");

    }
    #strip internal whitespace from sequence
    $self->{'seq'} =~ s/\s//g;

    $self;
}

sub print_data {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    printf "$x%20s -> %s\n",   'prefix', $self->{'prefix'};
    printf "$x%20s -> %s\n",   'id',     $self->{'id'};
    printf "$x%20s -> '%s'\n", 'desc',   $self->{'desc'};
    printf "$x%20s -> %s\n",   'seq',    $self->{'seq'};
}


###########################################################################
1;
