# -*- perl -*-
# Copyright (C) 1996-2013 Nigel P. Brown
# $Id: FASTA.pm,v 1.19 2013/10/20 22:01:51 npb Exp $

###########################################################################
#
# Base classes for FASTA family.
#
# FASTA parsing consists of 4 main record types:
#
#   HEADER       the header text (not much interesting)
#   RANK         the list of ordered hits and initn/init1/opt (scores)
#   MATCH        each hit's alignment with the query
#   TRAILER      trailing run-time data
#
# MATCH is further subdivided into:
#   SUM          the summary lines for each hit: name, description, scores
#   ALN          the aligned fragments
#
#
# Acknowledgements.
#
# Christophe Leroy, 22/8/97 for original fasta1 version.
#
###########################################################################
package NPB::Parse::Format::FASTA;

use vars qw(@ISA $GCG_JUNK);
use strict;

our $DEBUG = 0;

@ISA = qw(NPB::Parse::Record);

BEGIN { $GCG_JUNK = '(?:^\.\.|^\\\\)' }

use NPB::Parse::Format::FASTA1;
use NPB::Parse::Format::FASTA2;
use NPB::Parse::Format::FASTA3;
use NPB::Parse::Format::FASTA3X;
use NPB::Parse::Format::GCG_FASTA2;

my %VERSIONS = (
		@NPB::Parse::Format::FASTA1::VERSIONS,
		@NPB::Parse::Format::FASTA2::VERSIONS,
		@NPB::Parse::Format::FASTA3::VERSIONS,
		@NPB::Parse::Format::FASTA3X::VERSIONS,
                @NPB::Parse::Format::GCG_FASTA2::VERSIONS,
	       );

my $NULL        = '^\s*$';#for emacs';
    
my $FASTA_START = '^\s*\S+\s*[,:]\s+\d+\s+(?:aa|nt)';

my $ENTRY_START = "(?:"
    . $NPB::Parse::Format::FASTA1::ENTRY_START
    . "|"
    . $NPB::Parse::Format::FASTA2::ENTRY_START
    . "|"
    . $NPB::Parse::Format::FASTA3::ENTRY_START
    . "|"
    . $NPB::Parse::Format::FASTA3X::ENTRY_START
    . "|"
    . $NPB::Parse::Format::GCG_FASTA2::ENTRY_START
    . ")";
my $ENTRY_END = "(?:"
    . $NPB::Parse::Format::FASTA1::ENTRY_END
    . "|"
    . $NPB::Parse::Format::FASTA2::ENTRY_END
    . "|"
    . $NPB::Parse::Format::FASTA3::ENTRY_END
    . "|"
    . $NPB::Parse::Format::FASTA3X::ENTRY_END
    . "|"
    . $NPB::Parse::Format::GCG_FASTA2::ENTRY_END
    . ")";

my $HEADER_START = "(?:"
    . $NPB::Parse::Format::FASTA1::HEADER_START
    . "|"		      
    . $NPB::Parse::Format::FASTA2::HEADER_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3::HEADER_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::HEADER_START
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::HEADER_START
    . ")";		      
my $HEADER_END = "(?:"    
    . $NPB::Parse::Format::FASTA1::HEADER_END
    . "|"		      
    . $NPB::Parse::Format::FASTA2::HEADER_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3::HEADER_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::HEADER_END
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::HEADER_END
    . ")";

my $RANK_START = "(?:"
    . $NPB::Parse::Format::FASTA1::RANK_START
    . "|"		      
    . $NPB::Parse::Format::FASTA2::RANK_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3::RANK_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::RANK_START
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::RANK_START
    . ")";		      
my $RANK_END = "(?:"   
    . $NPB::Parse::Format::FASTA1::RANK_END
    . "|"		      
    . $NPB::Parse::Format::FASTA2::RANK_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3::RANK_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::RANK_END
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::RANK_END
    . ")";

my $MATCH_START = "(?:"
    . $NPB::Parse::Format::FASTA1::MATCH_START
    . "|"		      
    . $NPB::Parse::Format::FASTA2::MATCH_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3::MATCH_START
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::MATCH_START
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::MATCH_START
    . ")";
my $MATCH_END = "(?:"
    . $NPB::Parse::Format::FASTA1::MATCH_END
    . "|"		      
    . $NPB::Parse::Format::FASTA2::MATCH_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3::MATCH_END
    . "|"		      
    . $NPB::Parse::Format::FASTA3X::MATCH_END
    . "|"		      
    . $NPB::Parse::Format::GCG_FASTA2::MATCH_END
    . ")";

my $SUM_START = "(?:"
    . $NPB::Parse::Format::FASTA1::SUM_START
    . "|"			      
    . $NPB::Parse::Format::FASTA2::SUM_START
    . "|"			      
    . $NPB::Parse::Format::FASTA3::SUM_START
    . "|"			      
    . $NPB::Parse::Format::FASTA3X::SUM_START
    . "|"			      
    . $NPB::Parse::Format::GCG_FASTA2::SUM_START
    . ")";
my $SUM_END = "(?:"
    . $NPB::Parse::Format::FASTA1::SUM_END
    . "|"			      
    . $NPB::Parse::Format::FASTA2::SUM_END
    . "|"			      
    . $NPB::Parse::Format::FASTA3::SUM_END
    . "|"			      
    . $NPB::Parse::Format::FASTA3X::SUM_END
    . "|"			      
    . $NPB::Parse::Format::GCG_FASTA2::SUM_END
    . ")";

my $ALN_START = "(?:"
    . $NPB::Parse::Format::FASTA1::ALN_START
    . "|"			      
    . $NPB::Parse::Format::FASTA2::ALN_START
    . "|"			      
    . $NPB::Parse::Format::FASTA3::ALN_START
    . "|"			      
    . $NPB::Parse::Format::FASTA3X::ALN_START
    . "|"			      
    . $NPB::Parse::Format::GCG_FASTA2::ALN_START
    . ")";
my $ALN_END = "(?:"
    . $NPB::Parse::Format::FASTA1::ALN_END
    . "|"			      
    . $NPB::Parse::Format::FASTA2::ALN_END
    . "|"			      
    . $NPB::Parse::Format::FASTA3::ALN_END
    . "|"			      
    . $NPB::Parse::Format::FASTA3X::ALN_END
    . "|"			      
    . $NPB::Parse::Format::GCG_FASTA2::ALN_END
    . ")";

my $TRAILER_START = "(?:"
    . $NPB::Parse::Format::FASTA1::TRAILER_START
    . "|"
    . $NPB::Parse::Format::FASTA2::TRAILER_START
    . "|"
    . $NPB::Parse::Format::FASTA3::TRAILER_START
    . "|"
    . $NPB::Parse::Format::FASTA3X::TRAILER_START
    . "|"
    . $NPB::Parse::Format::GCG_FASTA2::TRAILER_START
    . ")";
my $TRAILER_END = "(?:"   
    . $NPB::Parse::Format::FASTA1::TRAILER_END
    . "|"
    . $NPB::Parse::Format::FASTA2::TRAILER_END
    . "|"
    . $NPB::Parse::Format::FASTA3::TRAILER_END
    . "|"
    . $NPB::Parse::Format::FASTA3X::TRAILER_END
    . "|"
    . $NPB::Parse::Format::GCG_FASTA2::TRAILER_END
    . ")";


#Generic get_entry() and new() constructors for all FASTA style parsers:
#determine program and version and coerce appropriate subclass.

#Consume one entry-worth of input on stream $fh associated with $file and
#return a new FASTA instance.
sub get_entry {
    my ($parent) = @_;
    my ($line, $offset, $bytes) = ('', -1, 0);
    my $fh   = $parent->{'fh'};
    my $text = $parent->{'text'};
    my ($type, $prog, $version, $class, $format) = ('NPB::Parse::Format::FASTA');
    my ($GCG, $self) = (0);
    my $start = '';

    while (defined ($line = <$fh>)) {

	#warn "($offset) >>$line";

        #start of entry
        if ($line =~ /$ENTRY_START/o and $offset < 0) {
            $offset = $fh->tell - length($line);
	    $start = $line;
	    #warn "STA $offset, $bytes, ($line)\n";
            #fall through for version tests

        } elsif ($line =~ /$ENTRY_END/o) {

	    if ($start =~ /$FASTA_START/o and $line =~ /^\s*L?ALIGN/) {
		#replace offset
		$offset = $fh->tell - length($line);
		$start = $line;
		#warn "STA $offset, $bytes, ($line)\n";
		#fall through for version tests

	    } elsif ($start =~ /^\s*LALIGN/o and
                     $line =~ /^\s*Comparison of:/) {
		#keep old offset
		$start = $line;
		#warn "STA $offset, $bytes, ($line)\n";
		#fall through for version tests

	    } else {
		#end of entry
		#warn "END $offset, $bytes, ($line)\n";
		last;
	    }
	} elsif ($offset < 0) {
	    next;
	}
	
	#escape iteration if we've hit the alignment section
	next    if $line =~ /$ALN_START/;

	#try to get program and version from header; these headers are
	#only present if stderr was collected. sigh.

	#try to determine program
	if ($line =~ /^\s*(\S+)\s+(?:searches|compares|produces|translates|performs)/) {
	    #FASTA family versions 2 upwards
	    $prog = $1;
	    next;
	} elsif ($line =~ /^\s*(\S+)\s+(?:searches|compares)/) {
	    #FASTA version 1
	    $prog = $1;
	    next;
	}
	
	#try to determine version from header
	if ($line =~ /^\s*version\s+(\d)\./) {
	    $version = $1;   #eg, version 3.4
	} elsif ($line =~ /^\s*version\s+(3\d)/) {
	    $version = '3X'; #eg, version 34
	} elsif ($line =~ /^\s*v(\d+)\.\d+\S\d+/) {
	    $version = $1;
	}
	
	#otherwise... stderr header was missing... look at stdout part
	#warn ">>$line";

	#try to determine FASTA version by minor differences
	if ($line =~ /The best scores are:\s+initn\s+init1\s+opt\s*$/) {
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 1          unless defined $version;
	    next;
	}

	if ($line =~ /The best scores are:\s+initn\s+init1\s+opt\s+z-sc/) {
	    #matches FASTA2,FASTA3,TFASTX3, but next rules commit first
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 2          unless defined $version;
	    next;
	}

	if ($line =~ /The best scores are:\s+init1\s+initn\s+opt\s+z-sc/) {
	    #matches GCG FASTA2
	    $prog    = 'FASTA'    unless defined $prog;    #guess!
	    $version = 2          unless defined $version;
	    $GCG = 1;
	    next;
	}

	if ($line =~ /ALIGN calculates/) {
	    #matches FASTA2/ALIGN
	    $prog    = 'ALIGN'     unless defined $prog;
	    $version = 2           unless defined $version;
	    next;
	}
	
	if ($line =~ /LALIGN finds/) {
	    #matches FASTA2/LALIGN with stderr
	    $prog    = 'LALIGN'    unless defined $prog;
	    $version = 2           unless defined $version;
	    next;
	}

	if ($line =~ /Comparison of:/) {
	    #matches FASTA2/LALIGN
	    $prog    = 'LALIGN'    unless defined $prog;
	    $version = 2           unless defined $version;
	    next;
	}

	if ($line =~ /SSEARCH searches/) {
	    #matches FASTA2/SSEARCH
	    $prog    = 'SSEARCH'   unless defined $prog;
	    $version = 2           unless defined $version;
	    next;
	}

	if ($line =~ /^(\S+)\s+\((\d+)/) {
	    $prog    = $1          unless defined $prog;
	    $version = $2          unless defined $version;
	    next;
	}

	if ($line =~ /frame-shift:/) {
	    $prog    = 'TFASTX';    #guess
	    next;
	}

	if ($line =~ /$GCG_JUNK/) {
	    #matches GCG
	    $GCG = 1;
	    next;
	}

    }
    return 0   if $offset < 0;

    $bytes = $fh->tell - $offset;

    unless (defined $prog and defined $version) {
	die "get_entry() top-level FASTA parser could not determine program/version\n";
    }

    unless (exists $VERSIONS{$version} and 
	    grep(/^$prog$/i, @{$VERSIONS{$version}}) > 0) {
	die "get_entry() parser for program '$prog' version '$version' not implemented\n";
    }

    $prog    = lc $prog;
    $format  = uc $prog;
    $version =~ s/-/_/g;

    if ($GCG) {
	$class = "NPB::Parse::Format::GCG_FASTA${version}::$prog";
    } else {
 	$class = "NPB::Parse::Format::FASTA${version}::$prog";
    }

    #reuse packages: tfastx,tfasty,tfastxy -> tfasta
    $class =~ s/::tfast([xy]|xy)$/::tfasta/;

    #reuse packages: fasty -> fastx
    $class =~ s/::fasty$/::fastx/;

    #reuse packages: fastf,fasts -> fastm
    $class =~ s/::fast[fs]$/::fastm/;

    #warn "\nprog=$prog  version=$version (GCG=$GCG) class=$class\n";

    ($prog = $class) =~ s/::/\//g; require "$prog.pm";

    #contruct specific parser
    no strict 'refs';
    $self = &{"${class}::new"}($class, undef, $text, $offset, $bytes);

    $self->{'format'}  = $format;
    $self->{'version'} = $version;

    $self;
}
	    
#Parse one entry: generic for all FASTA[12]
#(FASTA3 $MATCH_START definition conflicts)
sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    while (defined ($line = $text->next_line)) {

	#Header lines
	if ($line =~ /$HEADER_START/o) {
	    $text->scan_until($HEADER_END, 'HEADER');
	    next;
	}

	#Rank lines		       	      
	if ($line =~ /$RANK_START/o) {
	    $text->scan_until($RANK_END, 'RANK');
	    next;			       	      
	}				       	      
	
	#Hit lines		       	      
	if ($line =~ /$MATCH_START/o) {
	    $text->scan_until($MATCH_END, 'MATCH');
	    next;			       	      
	}

	#Trailer lines
	if ($line =~ /$TRAILER_START/o) {
	    $text->scan_until_inclusive($TRAILER_END, 'TRAILER');
	    next;			       	      
	}
	
	#end of FASTA job
	next    if $line =~ /$ENTRY_END/o;
	
	#blank line or empty record: ignore
	next    if $line =~ /$NULL/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;#->examine;
}

sub parse_frame {
    return 'f'  unless defined $_[0]; #default is forwards
    my $s = "$_[0]";
    return 'f'  if $s =~ /^\s*$/;     #default is forwards
    return 'f'  if $s eq 'f';
    return 'r'  if $s eq 'r';
    return 'r'  if $s eq 'rev-comp';
    return $s   if $s =~ /^[123]$/;   #seen in: tfasta_3.4t23.
    return $s   if $s =~ /^[456]$/;   #seen in: tfasta_3.4t23.
    return 'F'  if $s eq 'F';         #seen in: tfastx2.0u
    return 'R'  if $s eq 'R';         #seen in: tfastx2.0u
    return $s; #silently accept whatever was given
}

sub parse_orient {
    return '+'  unless defined $_[0]; #default is forwards
    my $s = "$_[0]";
    return '+'  if $s eq 'f';
    return '-'  if $s eq 'r';
    return '-'  if $s eq 'rev-comp';
    return '+'  if $s =~ /^[123]$/;   #seen in: tfasta_3.4t23.
    return '-'  if $s =~ /^[456]$/;   #seen in: tfasta_3.4t23.
    return '+'  if $s eq 'F';         #seen in: tfastx2.0u
    return '-'  if $s eq 'R';         #seen in: tfastx2.0u
    warn "WARNING: parse_orient: unrecognised value '$s'\n";
    return '?'; #what orientation?!!
}


###########################################################################
package NPB::Parse::Format::FASTA::HEADER;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    NPB::Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package NPB::Parse::Format::FASTA::RANK;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my ($hit, $field);
    NPB::Parse::Record::print $self, $indent;
    foreach $hit (@{$self->{'hit'}}) {
	foreach $field (sort keys %$hit) {
	    printf "$x%20s -> %s\n", $field, $hit->{$field};
	}
    }
}


###########################################################################
package NPB::Parse::Format::FASTA::TRAILER;

use vars qw(@ISA);

@ISA   = qw(NPB::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self, 0, undef);

    $line = $text->scan_lines(0);

    $self->{'trailer'} = $line;
    
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    NPB::Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package NPB::Parse::Format::FASTA::MATCH;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new {
    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    while (defined ($line = $text->next_line)) {

	#identifier lines
	if ($line =~ /$SUM_START/o) {
	    $text->scan_until_inclusive($SUM_END, 'SUM');
	    next;
	}

	#fragment hits: terminated by several possibilities
	if ($line =~ /$ALN_START/o) {
	    $text->scan_until($ALN_END, 'ALN');
	    next;
	}
	
	#blank line or empty record: ignore
        next    if $line =~ /$NULL/o;

	#default
	$self->warn("unknown field: $line");
    }
    $self;
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    NPB::Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package NPB::Parse::Format::FASTA::MATCH::SUM;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new { die "$_[0]::new() virtual function called\n" }

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    my $field;
    NPB::Parse::Record::print $self, $indent;
    foreach $field (sort keys %$self) {
	printf "$x%20s -> %s\n", $field,  $self->{$field};
    }
}


###########################################################################
package NPB::Parse::Format::FASTA::MATCH::ALN;

use NPB::Parse::Math;

use vars qw(@ISA);

@ISA = qw(NPB::Parse::Record);

sub new {
    my $keys_and_depth = sub {
	my ($query, $sbjct) = @_;
	#determine depth of sequence labels at left: take the
	#shorter since either sequence may begin with a gap
	$$query =~ /^(\s*\S+\s*)/o; my $x = length $1;
	$$sbjct =~ /^(\s*\S+\s*)/o; my $y = length $1;
	my $depth = min($x, $y);
	#warn "depth: $depth\n";
	#recover sequence row names
	my $qkey = substr($$query, 0, $depth);
	my $skey = substr($$sbjct, 0, $depth);
	return ($qkey, $skey, $depth);
    };

    my $append_ruler = sub {
	my ($ruler, $piece, $depth) = @_;
	if ($$ruler eq '') {
	    $$ruler .= $$piece;
	    return $$ruler;
	}
	my ($num, $junk, $rlen) = (0, $depth, length($$ruler));
	my $s = substr($$piece, 0, $depth);
	if ($s =~ /(\d+)/o) {
	    $num  = length $1;
	    $junk -= $num;
	}
	$ruler = substr($$ruler, 0, $rlen-$num) . substr($$piece, $junk);
	#warn "ruler: $num/$junk/$depth/$rlen [$ruler]\n";
	$ruler;
    };

    my $summary_info = sub {
	my ($self, $parent) = @_;
	#Look in the parent MATCH record's already parsed SUM record, which
	#contains accurate alignment ranges (but these only cover the
        #aligned regions; terminal overhanging sequences are not counted!
	my ($q1, $q2, $s1, $s2);
	my $sum = $parent->{'record_by_posn'}->[0]->[3];
	#warn "$sum->{'ranges'}\n";
	if ($sum->{'ranges'} =~ /(\d+)-(\d+):(\d+)-(\d+)/) {
	    ($q1, $q2, $s1, $s2) = ($1, $2, $3, $4);
	} else {
	    $self->die("unparsed range: '$sum->{'ranges'}'");
	}
	#The programs SSEARCH 35.04, GGSEARCH 36.3.3 had an apparent bug
        #concerning the range labelling of the reverse complement of the
        #query, with the start/stop labels inverted in the score summary and
        #wrong in some cases in the alignment rulers. Test for this:
	my $orient  = $q2 < $q1 ? '-' : '+';
	my $rev = 0;
	if ($self->query_orient_conflict($sum->{'orient'}, $orient) and
	    $q2-$q1>0) {
	    warn "WARNING: query orientation conflict for '$sum->{id}': summary says '$sum->{orient}', but range is '$q1:$q2': reversing this\n" if $DEBUG;
	    $rev = 1;
	}
	warn ">>> $sum->{'id'}\n"  if $DEBUG;
	warn "ranges: [$q1, $q2], [$s1, $s2]\n\n" if $DEBUG;
	[ [$q1, $q2, $rev], [$s1, $s2, 0] ];
    };

    my $start_info = sub {
	my ($self, $name, $ruler, $align, $depth, $rstart) = @_;
	my ($ai, $si, $ni, $num, $usedr) = (0, 0, 0, 0, 0);
	#warn "start [$$ruler]\n";
	#warn "start [$$align]\n";
	if ($$align =~ /(^[-\s]*)\S/) {
	    $si = length($1);
	} else {
	    $self->die("no sequence:", $name);
	}
	if ($$ruler =~ /^(\s*(\d+))/) {
	    ($ni, $num) = (length($1) - $depth -1, $2);
	} else {
	    ($ni, $num, $usedr) = ($si, $rstart, 1);
	}
	#count non-sequence in the fragment between seqstart and label
	my $gc = 0;
	if ($si < $ni) {  #seqstart ... label
	    my $s = substr($$align, $si, $ni-$si);
	    $s =~ tr /[a-zA-Z*]//d; #drop sequence symbols
	    $gc = length $s;  #remaining junk
	}
	warn "[$$ruler]\n[@{['.'x$depth]}$$align]\nindex: [r1: $rstart  a: $ai  b: $si  x: $ni  X: $num  gc: $gc  usedr: $usedr]\n\n" if $DEBUG;
	[$rstart, $ai, $si, $ni, $num, $gc, $usedr];
    };

    my $stop_info = sub {
	my ($self, $name, $ruler, $align, $depth, $rend) = @_;
	my ($ai, $si, $ni, $num, $usedr) = (0, 0, 0, 0, 0);
	#warn "stop  [$$ruler]\n";
	#warn "stop  [$$align]\n";
	if ($$align =~ /\S([-\s]*)$/) {
	    $ai = length($$align) -1;
	    $si = $ai - length($1);
	} else {
	    $self->die("no sequence:", $name);
	}
	if ($$ruler =~ /(\d+)(\s*)$/) {
	    $ni = length($$ruler) - length($2) - 1 - $depth;
	    $num = $1;
	} else {
	    ($ni, $num, $usedr) = ($si, $rend, 1);
	}
	#count non-sequence in the fragment between label and seqend
	my $gc = 0;
	if ($ni < $si) {  #label ... seqend
	    my $s = substr($$align, $ni, $si-$ni);
	    $s =~ tr /[a-zA-Z*]//d; #drop sequence symbols
	    $gc = length $s;  #remaining junk
	}
	warn "[$$ruler]\n[@{['.'x$depth]}$$align]\nindex: [r2: $rend  d: $ai c: $si  y: $ni  Y: $num  gc: $gc  usedr: $usedr]\n\n" if $DEBUG;
	[$rend, $ai, $si, $ni, $num, $gc, $usedr];
    };

    my $align_info = sub {
	my ($self, $sum, $name, $ruler, $align, $depth) = @_;
	my $r1  = $sum->[0];  #summary from
	my $r2  = $sum->[1];  #summary to
	my $rev = $sum->[2];  #summary to
	my $o  = $r2 < $r1 ? '-' : '+';
	my $start = &$start_info($self, $name, $ruler, $align, $depth, $r1);
	my $stop  = &$stop_info($self, $name, $ruler, $align, $depth, $r2);
	#count frameshifts lying between the extreme ruler numbers
	my ($n1, $n2) = ($start->[2], $stop->[2]);
	my $s = substr($$align, $n1, $n2-$n1+1);
	my $fs1 = $s =~ tr/[\/]//;
	my $fs2 = $s =~ tr/[\\]//;
	warn "frame: [$o, $fs1, $fs2]\n\n"  if $DEBUG;
	[ $o, $start, $stop, $fs1, $fs2, $rev ];
    };

    my $type = shift;
    if (@_ < 2) {
	#at least two args, ($offset, $bytes are optional).
	NPB::Message::die($type, "new() invalid arguments (@_)");
    }
    my ($parent, $text, $offset, $bytes) = (@_, -1, -1);
    my ($self, $line, $record);
    
    $self = new NPB::Parse::Record($type, $parent, $text, $offset, $bytes);
    $text = new NPB::Parse::Record_Stream($self);

    my ($qrule, $query, $align, $sbjct, $srule) = ('', '', '', '', '');
    my ($first_pass, $depth, $qkey, $skey) = (1, 0, '', '');

    #read records
    while (defined ($line = $text->next_line(1))) {
	my @tmp = ();

	#initial empty line before the alignment ruler
	next if $line =~ /^$/;

	#warn "$first_pass, [$line]\n";

	if ($line =~ /^\s+(?:\d+)?/) {
	    #warn "QUERY RULER\n";
	    $tmp[0] = $line;                #query ruler
	    $tmp[1] = $text->next_line(1);  #query sequence
	    $tmp[2] = $text->next_line(1);  #match pattern
	    $tmp[3] = $text->next_line(1);  #sbjct sequence
	    $tmp[4] = $text->next_line(1);  #sbjct ruler

	    if ($first_pass) {
		($qkey, $skey, $depth) = &$keys_and_depth(\$tmp[1], \$tmp[3]);
		#warn "ENTRY [$qkey], [$skey]\n";
		$first_pass = 0;
	    }

	} elsif (index($line, $qkey) == 0) {
	    #warn "QUERY (####)\n";
	    $tmp[1] = $line;                #query sequence
	    $tmp[2] = $text->next_line(1);  #match pattern
	    $tmp[3] = $text->next_line(1);  #sbjct sequence
	    $tmp[4] = $text->next_line(1);  #sbjct ruler

	} elsif (index($line, $skey) == 0) {
	    #warn "SBJCT (####)\n";
	    $tmp[3] = $line;                #sbjct sequence
	    $tmp[4] = $text->next_line(1);  #sbjct ruler

	} else {
	    $self->die("unexpected line: [$line]\n");
	}
	map { $tmp[$_] = '' unless defined $tmp[$_] } 0..@tmp-1;

	#warn "#0# [$tmp[0]]\n";
	#warn "#1# [$tmp[1]]\n";
	#warn "#2# [$tmp[2]]\n";
	#warn "#3# [$tmp[3]]\n";
	#warn "#4# [$tmp[4]]\n";

	#pad query/match/sbjct lines
	my $len = max(length($tmp[1]), length($tmp[3]));
	$tmp[0] .= ' ' x ($len-length $tmp[0]);
	$tmp[1] .= ' ' x ($len-length $tmp[1]);
	$tmp[2] .= ' ' x ($len-length $tmp[2]);
	$tmp[3] .= ' ' x ($len-length $tmp[3]);
	$tmp[4] .= ' ' x ($len-length $tmp[4]);

	#strip leading name from alignment rows
	$tmp[1] = substr($tmp[1], $depth);
	$tmp[2] = substr($tmp[2], $depth);
	$tmp[3] = substr($tmp[3], $depth);

	#grow the ruler
	$qrule = &$append_ruler(\$qrule, \$tmp[0], $depth);
	$srule = &$append_ruler(\$srule, \$tmp[4], $depth);

	#grow the alignment
	$query .= $tmp[1];
	$align .= $tmp[2];
	$sbjct .= $tmp[3];
    }

    #query/sbjct start/stop positions from parent summary
    my $sum = &$summary_info($self, $parent);

    #query/sbjct start/stop positions and numbering from ruler
    my $qinfo = &$align_info($self, $sum->[0], $qkey, \$qrule, \$query, $depth);
    my $sinfo = &$align_info($self, $sum->[1], $skey, \$srule, \$sbjct, $depth);

    my ($query_orient, $query_start, $query_stop) =
	$self->get_start_stop('qry', $qinfo, $self->query_base);

    my ($sbjct_orient, $sbjct_start, $sbjct_stop) =
	$self->get_start_stop('hit', $sinfo, $self->sbjct_base);

    my $x;
    
    #query length
    $x = $query;
    $x =~ tr/- //d;
    my $query_length = length($x);

    #sbjct length
    $x = $sbjct;
    $x =~ tr/- //d;
    my $sbjct_length = length($x);

    #query_leader
    $query =~ /^(\s*)/;
    my $query_leader = length $1;

    #query_trailer
    $query =~ /(\s*)$/;
    my $query_trailer = length $1;
    
    #sbjct_leader
    $sbjct =~ /^(\s*)/;
    my $sbjct_leader = length $1;

    #sbjct_trailer
    $sbjct =~ /(\s*)$/;
    my $sbjct_trailer = length $1;
    
    $self->{'query'} = $query;
    $self->{'align'} = $align;
    $self->{'sbjct'} = $sbjct;

    #warn "QUERY ($query_start, $query_stop, $query_length, $query_leader)\n";
    #warn "SBJCT ($sbjct_start, $sbjct_stop, $sbjct_length, $sbjct_leader)\n";
    #warn "EXIT  ($query_orient, $query_start, $query_stop) ($sbjct_orient, $sbjct_start, $sbjct_stop)\n";

    $self->{'query_orient'}  = $query_orient;
    $self->{'query_start'}   = $query_start;
    $self->{'query_stop'}    = $query_stop;
    $self->{'query_leader'}  = $query_leader;
    $self->{'query_trailer'} = $query_trailer;

    $self->{'sbjct_orient'}  = $sbjct_orient;
    $self->{'sbjct_start'}   = $sbjct_start;
    $self->{'sbjct_stop'}    = $sbjct_stop;
    $self->{'sbjct_leader'}  = $sbjct_leader;
    $self->{'sbjct_trailer'} = $sbjct_trailer;

    $self;
}

#Generic functions to fix start/stop positions suitable for any fasta member
#that uses untranslated sequences where the stated sequence ranges use the
#same numbering system as the displayed sequences. Must be overridden as
#needed:
#
# fasta       dna x dna  or  pro x pro  (ok)
# fasta[xy]   dna x pro                 (override query)
# tfast[axy]  pro x dna                 (override sbjct)

sub query_base { return 1 }
sub sbjct_base { return 1 }

#override in children: summary frame|rev-comp field refers to the query not
#the sbjct
sub query_orient_conflict {
    my ($self, $summary_orient, $orient) = @_;
    return $summary_orient ne $orient;
}
sub sbjct_orient_conflict {
    my ($self, $summary, $orient) = @_;
    return 0;
}

#subclasses override this if they need to do less work
sub get_start_stop {
    my ($self, $tgt, $info, $base) = @_;

    my ($orient, $start_info, $stop_info, $fs1, $fs2, $rev) = @$info;

    #              7            20
    #  ---------QWERTY  //  UIOPASDF----------
    #  a        b  x    //       y c         d

    # a:     alignment start: should be 0
    # b:     sequence  start: >= 0
    # c:     sequence  stop:  >= b
    # d:     alignment stop:  should be length(sequence)-1
    # x:     numbering start: >= 0  (could be < b?)
    # y:     numbering stop:  >= c
    # nx:    number start
    # ny:    number stop
    # gc1/2: count of non-sequence characters before/after the number
    # r1/2:  summary range start/stop number

    my ($r1, $a, $b, $x, $nx, $gc1, $usedr1) = @{$start_info};
    my ($r2, $d, $c, $y, $ny, $gc2, $usedr2) = @{$stop_info};

    my $delta1 = abs($x - $b) - $gc1;
    my $delta2 = abs($y - $c) - $gc2;
    my $fs = $fs1 - $fs2;  #magic: net count of frameshifts '/' versus '\'
    
    if ($x < $b) {
	$delta1 = -$delta1;
    }
    if ($y > $c) {
	$delta2 = -$delta2;
    }

    my ($start, $stop) = (0, 0);
    
    #if ($rev) {
#	$orient = $orient eq '+' ? '-' : '+';
#    }

    #extrapolate endpoints from the ruler numbers by the above deltas:
    #- scale by $base (1=protein or 3=DNA)
    #- account for the rest of the codon at the end (+/- 2) if in base 3
    #- shift according to the alignment summary range values
    #- discount frameshifts (gives agreement with the summary range)
    warn "$tgt(i): $orient,$base bc= $b,$c  xy= $x,$y  nxy= $nx,$ny  delta1/2= $delta1,$delta2  fs= $fs\n" if $DEBUG;
    if ($orient eq '+') {
     	if ($base == 1) {
     	    $start = $nx - $delta1;
	    $stop  = $ny + $delta2;
     	} else {
     	    $start = $nx - $base * $delta1;
	    $stop  = $ny + $base * $delta2 - $fs;
	    $stop += 2  unless $usedr2;
	    my $shift = $r1 - $start;
	    warn "$tgt(i): $orient,$base start/stop: $start,$stop  shift: $shift\n"  if $DEBUG;
	    $start -= $shift;
	    $stop  -= $shift;
     	}
    } else {
     	if ($base == 1) {
     	    $start = $nx + $delta1;
	    $stop  = $ny - $delta2;
     	} else {
     	    $start = $nx + $base * $delta1;
	    $stop  = $ny - $base * $delta2 + $fs;
	    $stop -= 2  unless $usedr2;
	    my $shift = $r1 - $start;  #shift
	    warn "$tgt(i): $orient,$base start/stop: $start,$stop  shift: $shift\n"  if $DEBUG;
	    $start += $shift;
	    $stop  += $shift;
     	}
    }
    warn "$tgt(o): $orient,$base start/stop: $start,$stop\n" if $DEBUG;
    if ($rev) {
	$orient = $orient eq '+' ? '-' : '+';
	my $tmp = $start; $start = $stop; $stop = $tmp;
	warn "$tgt(o): $orient,$base start/stop: $start,$stop [r]\n" if $DEBUG;
    }
    warn "\n" if $DEBUG;

    return ($orient, $start, $stop);
}

sub print {
    my ($self, $indent) = (@_, 0);
    my $x = ' ' x $indent;
    NPB::Parse::Record::print $self, $indent;
    printf "$x%20s -> '%s'\n", 'query',          $self->{'query'};
    printf "$x%20s -> '%s'\n", 'align',          $self->{'align'};
    printf "$x%20s -> '%s'\n", 'sbjct',          $self->{'sbjct'};
    printf "$x%20s -> %s\n",   'query_orient',   $self->{'query_orient'};
    printf "$x%20s -> %s\n",   'query_start',    $self->{'query_start'};
    printf "$x%20s -> %s\n",   'query_stop',     $self->{'query_stop'};
    printf "$x%20s -> %s\n",   'query_leader',   $self->{'query_leader'};
    printf "$x%20s -> %s\n",   'query_trailer',  $self->{'query_trailer'};
    printf "$x%20s -> %s\n",   'sbjct_orient',   $self->{'sbjct_orient'};
    printf "$x%20s -> %s\n",   'sbjct_start',    $self->{'sbjct_start'};
    printf "$x%20s -> %s\n",   'sbjct_stop' ,    $self->{'sbjct_stop'};
    printf "$x%20s -> %s\n",   'sbjct_leader',   $self->{'sbjct_leader'};
    printf "$x%20s -> %s\n",   'sbjct_trailer',  $self->{'sbjct_trailer'};
}


###########################################################################
1;
