# Copyright (C) 2018 Nigel P. Brown

######################################################################
package Bio::MView::Option::Arguments;

use Exporter;
use Bio::MView::Colormap;
use Bio::MView::Groupmap;
use Bio::MView::Align::Consensus;

@ISA = qw(Exporter);

push @EXPORT, qw(list_informats   check_informat);
push @EXPORT, qw(list_outformats  check_outformat);

push @EXPORT, qw(list_html_modes  check_html_mode);
push @EXPORT, qw(list_css_modes   check_css_mode);

push @EXPORT, qw(list_identity_modes  check_identity_mode);

push @EXPORT, qw(list_molecule_types  check_molecule_type);

push @EXPORT, qw(list_colormap_names  check_colormap);
push @EXPORT, qw(list_groupmap_names  check_groupmap);
push @EXPORT, qw(list_ignore_classes  check_ignore_class);

push @EXPORT, qw(list_alignment_color_schemes  check_alignment_color_scheme);
push @EXPORT, qw(list_consensus_color_schemes  check_consensus_color_scheme);

push @EXPORT, qw(list_hsp_tiling    check_hsp_tiling);
push @EXPORT, qw(list_strand_types  check_strand_type);
push @EXPORT, qw(list_cycle_types   check_cycle_type);
push @EXPORT, qw(list_block_values  check_block_value);
push @EXPORT, qw(list_chain_values  check_chain_value);

use strict;
use vars qw($Types);

############################################################################
my @Known_Informats = (
    #search formats
    'blast',
    'uvfasta',

    #flatfile formats
    'clustal',
    'fasta',
    'pir',
    'msf',
    'plain',
    'hssp',
    'maf',
    'multas',
    'mips',
    'jnetz',
);

sub list_informats { return join(",", @Known_Informats) }

sub test_file_contains_pearson_or_fasta {
    my ($file, $mode) = @_;
    my $guess = 'Pearson';
    return $guess  unless $mode eq 'file';
    local ($_, *TMP);
    open(TMP, "< $file");  #assume file access already checked
    while (<TMP>) {
        next  if /^\s*$/;
        $guess = 'FASTA'  unless /^\s*>/;
        last;
    }
    close TMP;
    return $guess;
}

sub check_informat_extension {
    my ($file, $ext, $mode) = @_;
    local $_;
    foreach ($ext) {  #switch
	return 'CLUSTAL'  if $_ =~ /^aln/i;
	return 'CLUSTAL'  if $_ =~ /^clu/i;
	return 'HSSP'     if $_ =~ /^hss/i;
	return 'JNETZ'    if $_ =~ /^jnt/i;
	return 'JNETZ'    if $_ =~ /^jne/i;
	return 'MAF'      if $_ =~ /^maf/i;
	return 'MIPS'     if $_ =~ /^mip/i;
	return 'MSF'      if $_ =~ /^msf/i;
	return 'MULTAS'   if $_ =~ /^mul/i;
	return 'PIR'      if $_ =~ /^pir/i;
	return 'Plain'    if $_ =~ /^txt/i;
	return 'Plain'    if $_ =~ /^pla/i;
	return 'Plain'    if $_ =~ /^pln/i;
	return 'BLAST'    if $_ =~ /^bla/i;
	return 'BLAST'    if $_ =~ /^tbl/i;
	return 'BLAST'    if $_ =~ /^phi/i;
	return 'BLAST'    if $_ =~ /^psi/i;
	return 'FASTA'    if $_ =~ /^tfa/i;
	return 'FASTA'    if $_ =~ /^ggs/i;
	return 'FASTA'    if $_ =~ /^gls/i;
	return 'FASTA'    if $_ =~ /^ss/i;
    }
    if ($ext =~ /^fa/i) {
        return test_file_contains_pearson_or_fasta($file, $mode);
    }
    return undef;
}

sub check_informat_basename {
    my ($file, $base, $mode) = @_;
    local $_;
    foreach ($base) {  #switch
        return 'CLUSTAL'  if $_ =~ /aln/i;
        return 'CLUSTAL'  if $_ =~ /clu/i;
        return 'HSSP'     if $_ =~ /hssp/i;
        return 'JNETZ'    if $_ =~ /jnet/i;
        return 'MAF'      if $_ =~ /maf/i;
        return 'MIPS'     if $_ =~ /mips/i;
        return 'MSF'      if $_ =~ /msf/i;
        return 'MULTAS'   if $_ =~ /multal/i;
        return 'MULTAS'   if $_ =~ /multas/i;
        return 'PIR'      if $_ =~ /pir/i;
        return 'Plain'    if $_ =~ /plain/i;
        return 'BLAST'    if $_ =~ /blast/i;
        return 'BLAST'    if $_ =~ /tblast/i;
        return 'BLAST'    if $_ =~ /phi.*blast/i;
        return 'BLAST'    if $_ =~ /psi.*blast/i;
        return 'FASTA'    if $_ =~ /ggsearch/i;
        return 'FASTA'    if $_ =~ /glsearch/i;
        return 'FASTA'    if $_ =~ /ssearch/i;
        return 'FASTA'    if $_ =~ /uvf/i;
        return 'FASTA'    if $_ =~ /tfast/i;
        return 'FASTA'    if $_ =~ /fast[fmsxy]/i;
        return 'Pearson'  if $_ =~ /pearson/i;
    }
    if ($base =~ /^fa/i) {
        return test_file_contains_pearson_or_fasta($file, $mode);
    }
    return undef;
}

sub check_informat {
    my ($file, $mode) = (@_, 'option');
    return ''  if $file eq '';
    my ($base, $ext, $guess) = ($file, '');
    ($base, $ext) = Universal::fileparts($file)  if $mode eq 'file';
    #warn "(file=$file, mode=$mode, base=$base, ext=$ext)";
    $guess = check_informat_extension($file, $ext, $mode);
    $guess = check_informat_basename($file, $base, $mode)
        unless defined $guess;
    return $guess;
}

############################################################################
my @Known_Outformats = (
    #dumps, possibly unaligned
    'pearson',
    'fasta',
    'pir',

    #multiple alignments
    'plain',
    'clustal',
    'msf',
    'new',

    #tabular
    'rdb',
);

sub list_outformats { return join(",", @Known_Outformats) }

sub check_outformat {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'new'      if $_ =~ /^ne/i;
        return 'plain'    if $_ =~ /^pl/i;
        return 'pearson'  if $_ =~ /^fa/i;
        return 'pearson'  if $_ =~ /^pe/i;
        return 'pir'      if $_ =~ /^pi/i;
        return 'msf'      if $_ =~ /^ms/i;
        return 'clustal'  if $_ =~ /^cl/i;
        return 'clustal'  if $_ =~ /^al/i;
        return 'rdb'      if $_ =~ /^rd/i;
    }
    return undef;
}

############################################################################
my @Known_HTML_Modes = (
    'head',
    'body',
    'data',
    'full',
    'off',
);

sub list_html_modes { return join(",", @Known_HTML_Modes) }

sub check_html_mode {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 16|8|4|2|1  if $_ =~ /^full/i;
        return 8|4|2|1     if $_ =~ /^head/i;
        return 4|2|1       if $_ =~ /^body/i;
        return 1           if $_ =~ /^data/i;
        return 0           if $_ =~ /^off/i;
    }
    return undef;
}

############################################################################
my @Known_CSS_Modes = (
    'off',
    'on',
    'file:',
    'http:',
);

sub list_css_modes { return join(",", @Known_CSS_Modes) }

sub check_css_mode {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 0     if $_ eq 'off' or $_ eq '0';
        return 1     if $_ eq 'on'  or $_ eq '1';
        return $val  if $_ =~ /^file:/i;
        return $val  if $_ =~ /^http:/i;
    }
    return undef;
}

###########################################################################
my @Known_Identity_Modes = (
    'aligned',
    'reference',
    'hit',
);

sub list_identity_modes { return join(",", @Known_Identity_Modes) }

sub check_identity_mode {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'reference' if $_ =~ /^r/;
        return 'aligned'   if $_ =~ /^a/;
        return 'hit'       if $_ =~ /^h/;
    }
    return undef;
}

###########################################################################
my @Known_Molecule_Types = (
    'aa',
    'na',
    'dna',
    'rna',
);

sub list_molecule_types { return join(",", @Known_Molecule_Types) }

sub check_molecule_type {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'aa'   if $_ =~ /^aa/i;
        return 'na'   if $_ =~ /^na/i;
        return 'dna'  if $_ =~ /^dna/i;
        return 'rna'  if $_ =~ /^rna/i ;
    }
    return undef;
}

###########################################################################
sub list_colormap_names { Bio::MView::Colormap::list_colormap_names }
sub check_colormap      { Bio::MView::Colormap::check_colormap(@_) }

###########################################################################
sub list_groupmap_names { Bio::MView::Groupmap::list_groupmap_names }
sub check_groupmap      { Bio::MView::Groupmap::check_groupmap(@_) }

###########################################################################
sub list_ignore_classes { Bio::MView::Align::Consensus::list_ignore_classes }
sub check_ignore_class  { Bio::MView::Align::Consensus::check_ignore_class(@_) }

###########################################################################
my @Known_Alignment_Color_Schemes = (
    'none',
    'any',
    'identity',
    'mismatch',
    'consensus',
    'group',
);

sub list_alignment_color_schemes {
    return join(",", @Known_Alignment_Color_Schemes)
}

sub check_alignment_color_scheme {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'none'       if $_ =~ /^n/i;
        return 'any'        if $_ =~ /^a/i;
        return 'identity'   if $_ =~ /^i/i;
        return 'mismatch'   if $_ =~ /^m/i;
        return 'consensus'  if $_ =~ /^c/i;
        return 'group'      if $_ =~ /^g/i;
    }
    return undef;
}

###########################################################################
my @Known_Consensus_Color_Schemes = (
    'none',
    'any',
    'identity',
);

sub list_consensus_color_schemes {
    return join(",", @Known_Consensus_Color_Schemes)
}

sub check_consensus_color_scheme {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'none'       if $_ =~ /^n/i;
        return 'any'        if $_ =~ /^a/i;
        return 'identity'   if $_ =~ /^i/i;
    }
    return undef;
}

###########################################################################
my @Known_HSP_Tiling = (
     'ranked',
     'discrete',
     'all',
);

sub list_hsp_tiling { return join(",", @Known_HSP_Tiling) }

sub check_hsp_tiling {
    my $val = shift;
    local $_;
    foreach ($val) {  #switch
        return 'all'       if $_ =~ /^a/i;
        return 'ranked'    if $_ =~ /^r/i;
        return 'discrete'  if $_ =~ /^d/i;
    }
    return undef;
}

###########################################################################
my @Known_Strand_Types = (
    'p',
    'm',
    'both',
    '*',
);

sub list_strand_types { return join(",", @Known_Strand_Types) }

sub check_strand_type {
    my $val = shift;
    my @tmp = ();
    local $_;
    foreach (split /[,\s]+/, $val) {
        if    (lc $_ eq 'p')    { push @tmp, '+' }
        elsif (lc $_ eq 'm')    { push @tmp, '-' }
        elsif (lc $_ eq 'both') { @tmp = () }
        elsif ($_ eq '*')       { @tmp = () }
        else {
            return undef;    #unrecognised
        }
    }
    @tmp = ()  if @tmp > 1;  #want both strands
    return [ @tmp ];
}

###########################################################################
sub list_cycle_types { return join(",", qw(1..N first last all *)) }

sub check_cycle_type {
    my $val = shift;
    my @tmp=();
    local $_;
    foreach (split /[,\s]+/, $val) {
        if    ($_ eq 'first') { push @tmp, 1 }
        elsif ($_ eq 'last')  { push @tmp, 0 }
        elsif ($_ eq 'all')   { @tmp = (); last }
        elsif ($_ eq '*')     { @tmp = (); last }
        elsif (/^\d+$/)       { push @tmp, $_   }
        else {
            return undef;    #unrecognised
        }
    }
    return [ @tmp ];
}

###########################################################################
sub list_block_values { return join(",", qw(1..N first last all *)) }

sub check_block_value {
    my $val = shift;
    my @tmp=();
    local $_;
    foreach (split /[,\s]+/, $val) {
        if    ($_ eq 'first') { push @tmp, 1 }
        elsif ($_ eq 'last')  { push @tmp, 0 }
        elsif ($_ eq 'all')   { @tmp = (); last }
        elsif ($_ eq '*')     { @tmp = (); last }
        elsif (/^\d+$/)       { push @tmp, $_ }
        else {
            return undef;    #unrecognised
        }
    }
    return [ @tmp ];
}

###########################################################################
sub list_chain_values { return join(",", qw(A..B 1..N first last all *)) }

sub check_chain_value {
    my $val = shift;
    my @tmp=();
    local $_;
    foreach (split /[,\s]+/, $val) {
        if    ($_ eq 'first') { push @tmp, 1 }
        elsif ($_ eq 'last')  { push @tmp, 0 }
        elsif ($_ eq 'all')   { @tmp = (); last }
        elsif ($_ eq '*')     { @tmp = (); last }
        else                  { push @tmp, $_ }
    }
    return [ @tmp ];
}

###########################################################################
1;
