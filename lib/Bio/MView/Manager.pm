# Copyright (C) 1997-2018 Nigel P. Brown

######################################################################
package Bio::MView::Manager;

use Bio::MView::Option::Parameters;  #for $PAR
use Bio::MView::Option::Arguments;
use Bio::MView::Build;
use Bio::MView::Convert;
use Bio::MView::Display;
use Bio::MView::SRS qw(srsLink);

use strict;

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->{'acount'}  = 0;
    $self->{'display'} = [];
    $self->{'file'}    = undef;
    $self->{'format'}  = undef;
    $self->{'stream'}  = undef;
    $self->{'filter'}  = undef;
    $self->{'class'}   = undef;
    $self->{'quiet'}   = undef;
    $self->{'noparse'} = undef;

    $self;
}

sub alignment_count { $_[0]->{'acount'} }

#Called with the desired format to be parsed: either a string 'X' naming a
#Parse::Format::X or a hint which will be recognised by that class.
sub parse {
    my ($self, $file, $format) = (shift, shift, shift);
    my ($library, $tmp, $bld, $aln, $dis, $header1, $header2, $header3, $loop);

    #load a parser for the desired format
    $tmp = "Bio::MView::Build::Format::$format";
    ($library = $tmp) =~ s/::/\//g;
    require "$library.pm";

    return  if $self->{'noparse'};    #load the parser, but do nothing

    $self->{'file'}   = $file;
    $self->{'format'} = lc $format;
    $self->{'class'}  = $tmp;

    #warn $self->{'format'}, "\n";

    no strict 'refs';
    $tmp = &{"${tmp}::parser"}();
    use strict 'refs';

    $self->{'stream'} = new NPB::Parse::Stream($file, $tmp);

    return undef  unless defined $self->{'stream'};

    ($loop, $header1, $header2, $header3) = (0, '', '', '');

    #$header1 = $self->header($self->{'quiet'});

    while (defined ($bld = $self->next)) {

        $bld->reset;  #NIGE renamed

        while (defined ($aln = $bld->next)) {

	    if ($aln < 1) {  #null alignment
                #warn $PAR->get('prog') . ": empty alignment\n";
		next;
	    }

	    $self->{'acount'}++;

            if ($PAR->get('mode') ne 'new') {
                my $conv = new Bio::MView::Convert($bld, $aln,
                                                   $PAR->get('moltype'));
                my $s;

                $s = $conv->plain    if $PAR->get('mode') eq 'plain';
                $s = $conv->pearson  if $PAR->get('mode') eq 'pearson';
                $s = $conv->pir      if $PAR->get('mode') eq 'pir';
                $s = $conv->clustal  if $PAR->get('mode') eq 'clustal';
                $s = $conv->msf      if $PAR->get('mode') eq 'msf';
                $s = $conv->rdb      if $PAR->get('mode') eq 'rdb';

                print $$s  if defined $s;
                next;
            }

            $dis = $self->add_display($bld, $aln);

	    if ($loop++ < 1) {
		$header2 = $bld->header($self->{'quiet'}) . $aln->header($self->{'quiet'});
	    }
	    $header3 = $bld->subheader($self->{'quiet'});

	    #add to display list
	    push @{$self->{'display'}}, [ $dis, $header1, $header2, $header3 ];

	    #display item now?
	    unless ($PAR->get('register')) {
		$self->print;
		@{$self->{'display'}} = ();  #garbage collect
		#Universal::vmstat("print done (Manager)");
	    }

	    $header1 = $header2 = $header3 = '';

	    #drop old Align and Display objects: GC *before* next iteration!
	    $aln = $dis = undef;
        }

	#drop old Build object: GC *before* next iteration!
	$bld = undef;
    }
    $self;
}

#return next entry worth of parse data as in a Bio::MView::Build object
#ready for parsing, or undef if no more data.
sub next {
    my $self = shift;
    my ($entry, $tmp);

    #free the last entry and garbage its Bio::MView::Build
    if (defined $self->{'filter'}) {
        $self->{'filter'}->get_entry->free;
        $self->{'filter'} = undef;
    }

    #read the next chunk of data
    $entry = $self->{'stream'}->get_entry;
    if (! defined $entry) {
        $self->{'stream'}->close;
        return undef;
    }

    #construct a new Bio::MView::Build
    return $self->{'filter'} = $self->{'class'}->new($entry);
}


#construct a header string describing this alignment
sub header {
    my ($self, $quiet) = (@_, 0);
    return ''  if $quiet;
    my $s = "File: $self->{'file'}  Format: $self->{'format'}\n";
    Bio::MView::Display::displaytext($s);
}

sub gc_flag {
    return 0  if $PAR->get('consensus');
    return 0  if $PAR->get('conservation');
    1;
}

sub add_display {
    my ($self, $bld, $aln) = @_;

    my $ref    = $bld->get_row_id($PAR->get('ref_id'));
    my $refobj = $bld->get_row($PAR->get('ref_id'));

    #collect all the column labels
    $self->{'labelwidths'} = [ $refobj->display_column_widths ];

    #allow the Build instance to override the normal parameter
    #settings and to substitute specialised handlers for
    #'peculiar' alignments, eg., sequence versus secondary structure.
    $bld->change_alignment_settings($aln);

    #Universal::vmstat("display constructor");
    my $dis = new Bio::MView::Display($aln->init_display);
    #Universal::vmstat("display constructor DONE");

    #attach a ruler? (may include header text)
    if ($PAR->get('ruler')) {
        my $tmp = $aln->build_ruler($refobj);
	$tmp->append_display($dis);
        #Universal::vmstat("ruler added");
    }

    #attach the alignment
    if ($PAR->get('alignment')) {
        if ($PAR->get('html')) {
            $aln->set_color_scheme
                (
                 'ref_id'      => $ref,
                 'coloring'    => $PAR->get('aln_coloring'),
                 'colormap'    => $PAR->get('aln_colormap'),
                 'colormapf'   => $PAR->get('fnd_colormap'),
                 'group'       => $PAR->get('aln_groupmap'),
                 'threshold'   => $PAR->get('aln_threshold'),
                 'ignore'      => $PAR->get('aln_ignore'),
                 'con_gaps'    => $PAR->get('con_gaps'),
                 'css1'        => $PAR->get('css1'),
                 'alncolor'    => $PAR->get('alncolor'),
                 'labcolor'    => $PAR->get('labcolor'),
                 'symcolor'    => $PAR->get('symcolor'),
                 'gapcolor'    => $PAR->get('gapcolor'),
                 'find'        => $PAR->get('find'),
                );
        }
        #Universal::vmstat("set_color_scheme done");
	$aln->append_display($dis, $self->gc_flag);
        #Universal::vmstat("alignment added");
    }

    #attach conservation line?
    if ($PAR->get('conservation')) {
	my $tmp = $aln->build_conservation_row($PAR->get('moltype'));
	$tmp->append_display($dis);
        #Universal::vmstat("conservation added");
    }

    #attach consensus alignments?
    if ($PAR->get('consensus')) {
	my $tmp = $aln->build_consensus_rows(
                                          $PAR->get('con_groupmap'),
                                          $PAR->get('con_threshold'),
                                          $PAR->get('con_ignore'),
                                          $PAR->get('con_gaps'),
                                         );

        $tmp->set_consensus_color_scheme(
                               $aln, $ref,
			       'coloringc' => $PAR->get('con_coloring'),
                               'colormap'  => $PAR->get('aln_colormap'),
                               'colormapc' => $PAR->get('con_colormap'),
                               'group'     => $PAR->get('con_groupmap'),
                               'threshold' => $PAR->get('con_threshold'),
                               'ignore'    => $PAR->get('con_ignore'),
			       'css1'      => $PAR->get('css1'),
                              );
	$tmp->append_display($dis);
        #Universal::vmstat("consensi added");
    }

    #garbage collect if not already done piecemeal
    if (!$self->gc_flag) {
	$aln->do_gc;
	#Universal::vmstat("final garbage collect");
    }
    $dis;
}

#wrapper functions
sub check_input_file {
    my $file = shift;
    return Bio::MView::Option::Arguments::check_informat($file, 'file');
}

sub load_colormaps { Bio::MView::Colormap::load_colormaps(@_) }
sub dump_colormaps { Bio::MView::Colormap::dump_colormaps(@_) }
sub dump_css       { Bio::MView::Colormap::dump_css1_colormaps(@_) }

sub load_groupmaps { Bio::MView::Groupmap::load_groupmaps(@_) }
sub dump_groupmaps { Bio::MView::Groupmap::dump_groupmaps(@_) }

#sub get_default_find_colormap { Bio::MView::Align::get_default_find_colormap(@_) }

sub print {
    my ($self, $stm) = (@_, \*STDOUT);

    $self->{'posnwidth'} = 0;

    # warn join(',', @{$self->{'labelwidths'}}), "\n";

    #minimum column widths
    $self->{'labwidth0'} = $self->{'labelwidths'}[0];
    $self->{'labwidth1'} = $self->{'labelwidths'}[1];
    $self->{'labwidth2'} = $self->{'labelwidths'}[2];
    $self->{'labwidth3'} = $self->{'labelwidths'}[3];
    $self->{'labwidth4'} = $self->{'labelwidths'}[4];
    $self->{'labwidth5'} = $self->{'labelwidths'}[5];
    $self->{'labwidth6'} = $self->{'labelwidths'}[6];
    $self->{'labwidth7'} = $self->{'labelwidths'}[7];

    # warn
    #     "PW ", $self->{'posnwidth'},
    #     "  L0 ", $self->{'labwidth0'},
    #     "  L1 ", $self->{'labwidth1'},
    #     "  L2 ", $self->{'labwidth2'},
    #     "  L3 ", $self->{'labwidth3'},
    #     "  L4 ", $self->{'labwidth4'},
    #     "  L5 ", $self->{'labwidth5'},
    #     "  L6 ", $self->{'labwidth6'},
    #     "  L7 ", $self->{'labwidth7'},
    #     "\n"   ;

    #consolidate field widths
    foreach (@{$self->{'display'}}) {
        $self->{'posnwidth'} = $_->[0]->{'posnwidth'}
            if $_->[0]->{'posnwidth'} > $self->{'posnwidth'};
        $self->{'labwidth0'} = $_->[0]->{'labwidth0'}
            if $_->[0]->{'labwidth0'} > $self->{'labwidth0'};
        $self->{'labwidth1'} = $_->[0]->{'labwidth1'}
            if $_->[0]->{'labwidth1'} > $self->{'labwidth1'};
        $self->{'labwidth2'} = $_->[0]->{'labwidth2'}
            if $_->[0]->{'labwidth2'} > $self->{'labwidth2'};
        $self->{'labwidth3'} = $_->[0]->{'labwidth3'}
            if $_->[0]->{'labwidth3'} > $self->{'labwidth3'};
        $self->{'labwidth4'} = $_->[0]->{'labwidth4'}
            if $_->[0]->{'labwidth4'} > $self->{'labwidth4'};
        $self->{'labwidth5'} = $_->[0]->{'labwidth5'}
            if $_->[0]->{'labwidth5'} > $self->{'labwidth5'};
        $self->{'labwidth6'} = $_->[0]->{'labwidth6'}
            if $_->[0]->{'labwidth6'} > $self->{'labwidth6'};
        $self->{'labwidth7'} = $_->[0]->{'labwidth7'}
            if $_->[0]->{'labwidth7'} > $self->{'labwidth7'};
    }

    # warn
    #     "PW ", $self->{'posnwidth'},
    #     "  L0 ", $self->{'labwidth0'},
    #     "  L1 ", $self->{'labwidth1'},
    #     "  L2 ", $self->{'labwidth2'},
    #     "  L3 ", $self->{'labwidth3'},
    #     "  L4 ", $self->{'labwidth4'},
    #     "  L5 ", $self->{'labwidth5'},
    #     "  L6 ", $self->{'labwidth6'},
    #     "  L7 ", $self->{'labwidth7'},
    #     "\n"   ;

    my $first = 1;
    #output
    while ($_ = shift @{$self->{'display'}}) {
	#Universal::vmstat("display");
	if ($PAR->get('html')) {
            my $s = "style=\"border:0px;";
	    #body tag
	    if (! $PAR->get('css1')) {
                #supported in HTML 4.01:
		$s .= " background-color:" . $PAR->get('alncolor') . ";"
		    if defined $PAR->get('alncolor');
		$s .= " color:"            . $PAR->get('labcolor') . ";"
		    if defined $PAR->get('labcolor');
		$s .= " a:link:"           . $PAR->get('linkcolor')  . ";"
		    if defined $PAR->get('linkcolor');
		$s .= " a:active:"         . $PAR->get('alinkcolor') . ";"
		    if defined $PAR->get('alinkcolor');
		$s .= " a:visited:"        . $PAR->get('vlinkcolor') . ";"
		    if defined $PAR->get('vlinkcolor');
            }
            $s .= "\"";
	    print $stm "<P>\n"  unless $first;
	    print $stm "<TABLE $s>\n";
	    #header
	    print $stm "<TR><TD><PRE>\n";
	    print $stm ($_->[1] ? $_->[1] : '');
	    print $stm ($_->[2] ? $_->[2] : '');
	    print $stm "</PRE></TD></TR>\n";
	    #subheader
	    if ($_->[3]) {
		print $stm "<TR><TD><PRE>\n";
		print $stm $_->[3];
		print $stm "</PRE></TD></TR>\n";
	    }
	    #alignment start
	    print $stm "<TR><TD>\n";
	} else {
	    #header
	    print $stm "\n"           if $_->[1] or $_->[2];
	    print $stm $_->[1],       if $_->[1];
	    print $stm $_->[2]        if $_->[2];
	    print "\n";
	    print $stm $_->[3], "\n"  if $_->[3];
	}
	#alignment
	$_->[0]->display(
			 'stream'    => $stm,
			 'html'      => $PAR->get('html'),
			 'bold'      => $PAR->get('bold'),
			 'col'       => $PAR->get('width'),
			 'label0'    => $PAR->get('label0'),
			 'label1'    => $PAR->get('label1'),
			 'label2'    => $PAR->get('label2'),
			 'label3'    => $PAR->get('label3'),
			 'label4'    => $PAR->get('label4'),
			 'label5'    => $PAR->get('label5'),
			 'label6'    => $PAR->get('label6'),
			 'label7'    => $PAR->get('label7'),
			 'posnwidth' => $self->{'posnwidth'},
			 'labwidth0' => $self->{'labwidth0'},
			 'labwidth1' => $self->{'labwidth1'},
			 'labwidth2' => $self->{'labwidth2'},
			 'labwidth3' => $self->{'labwidth3'},
			 'labwidth4' => $self->{'labwidth4'},
			 'labwidth5' => $self->{'labwidth5'},
			 'labwidth6' => $self->{'labwidth6'},
			 'labwidth7' => $self->{'labwidth7'},
			);
	if ($PAR->get('html')) {
	    #alignment end
	    print $stm "</TD></TR>\n";
	    print $stm "</TABLE>\n";
	    print $stm "</P>\n"  unless $first;
	}
	#Universal::vmstat("display done");
	$_->[0]->free;
	#Universal::vmstat("display free done");

	$first = 0;
    }
    $self;
}


###########################################################################
1;
