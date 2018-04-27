# Copyright (C) 2015-2018 Nigel P. Brown

use strict;

###########################################################################
package Bio::MView::Build::RowInfoMixin;

use Bio::MView::Option::Parameters;  #for $PAR

my $DIS_SCHEMA = [
    # unf ukey       label
    [ 1,  'num',     '',       ],
    [ 2,  'cid',     '',       ],
    [ 3,  'text',    '',       ], #use truncated text
    [ 4,  '_data_',  '',       ],
    [ 5,  'covr',    'cov',    ],
    [ 6,  'pcid',    'pid',    ],
    [ 7,  'posn1',   'query',  ],
    [ 8,  'posn2',   'sbjct',  ],
    [ 0,  'seq',     '',       ], #don't fetch sequence
    ];

my $UNF_SCHEMA = [
    # unf ukey       label
    [ 1,  'num',     'row',    ],
    [ 2,  'cid',     'id',     ],
    [ 3,  'desc',    'desc',   ],
    [ 4,  '_data_',  '',       ],
    [ 5,  'covr',    'cov',    ],
    [ 6,  'pcid',    'pid',    ],
    [ 7,  'posn1',   'query',  ],
    [ 8,  'posn2',   'sbjct',  ],
    [ 9,  'seq',     '',       ],
    ];

my $FMT_SCHEMA = [
    # fmt fkey       label      format
    [ 1,  'num',     '',        '4N'   ],
    [ 2,  'cid',     '',        '30S'  ],
    [ 3,  'text',    '',        '50S'  ], #use truncated text
    [ 4,  '_data_',  '',        ''     ],
    [ 5,  'covr',    'cov',     '6N'   ],
    [ 6,  'pcid',    'pid',     '6N'   ],
    [ 7,  'posn1',   'query',   '15S'  ],
    [ 8,  'posn2',   'sbjct',   '15S'  ],
    [ 9,  'seq',     '',        '500S' ],
    ];

my $RDB_SCHEMA = [
    # rdb  rkey       label      format
    [ 1,   'num0',    'row',     '4N'   ], #don't convert zero to ''
    [ 2,   'cid',     'id',      '30S'  ],
    [ 3,   'desc',    'desc',    '500S' ],
    [ 4,   '_data_',  '',        ''     ],
    [ 5,   'covr',    'cov',     '6N'   ],
    [ 6,   'pcid',    'pid',     '6N'   ],
    [ 7,   'posn1',   'query',   '15S'  ],
    [ 8,   'posn2',   'sbjct',   '15S'  ],
    [ 9,   'seq',     'seq',     '500S' ],
    ];

#ignore these keys if sequence output is off
my $IGNORE_SEQUENCE_KEYS = [ 'covr', 'pcid', 'seq' ];

######################################################################
# public methods
######################################################################
#save row information according to schema
sub save_info {
    my $self = shift;
    #warn "save_info: [@{[join(',',@_)]}]\n";

    my $schema = $self->schema;
    return $self  unless @$schema;

    for (my $i=0; $i<@$schema; $i++) {
        my ($n1, $n2, $name, $label, $format, $default) = @{$schema->[$i]};
        #warn "save: $name\n";
        $self->{'info'}->{$name} = defined $_[$i] ? $_[$i] : $default;
    }
}

#test if item has attribute
sub has {
    my ($self, $key) = @_;
    #warn "has: [$key]\n";

    my $schema = $self->schema;

    return exists $self->{'info'}->{$key}  unless @$schema;

    foreach my $row (@$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;
        return 1  if $key eq $name;
        return 1  if $key eq $label;
    }
    return 0; #no key
}

#set a row information attribute if in the schema
sub set_val {
    my ($self, $key, $val) = @_;
    #warn "set_val: [$key => $val]\n";

    my $schema = $self->schema;
    return  unless @$schema;

    foreach my $row (@$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;
        $self->{'info'}->{$name} = $val, return  if $key eq $name;
        $self->{'info'}->{$name} = $val, return  if $key eq $label;
    }
    warn "@{[ref $self]}::set_val: unknown attribute '$key'\n";
}

#get a row information attribute if in the schema
sub get_val {
    my ($self, $key) = @_;
    #warn "get_val: [$key]\n";

    my $schema = $self->schema;

    if (@$schema < 1) {
        return $self->{$key}  if exists $self->{$key};
        return '';
    }

    foreach my $row (@$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;
        return $self->{'info'}->{$name}  if $key eq $name;
        return $self->{'info'}->{$name}  if $key eq $label;
    }
    warn "@{[ref $self]}::get_val: unknown attribute '$key'\n";
    return '';
}

#string of row items, unformatted, tab-separated for rdb
sub row_as_rdb_string {
    my ($self, $mode) = @_;
    my @cols = ();
    my $ignore = $self->ignore_child_columns;
    #warn "ignore: @$ignore\n";
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$RDB_SCHEMA) {
        my ($n, $key, $label, $format) = @$row;
        next  unless $n;                       #ignore row
        next if grep { $key eq $_ } @$ignore;  #ignore row
        push @cols, $self->schema_item_as_rdb_list($mode, $row);
    }
    #warn "row_as_rdb_string: [@cols]\n";
    return join("\t", @cols);
}

#string of row items, unformatted, with supplied delim and ignore list
sub row_as_string {
    my ($self, $delim, $ignore) = @_;
    $ignore = []  unless defined $ignore;
    push @$ignore, @{$self->ignore_child_columns};
    #warn "ignore: @$ignore\n";
    my @cols = ();
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$UNF_SCHEMA) {
        my ($n, $key, $label, $format) = @$row;
        next  unless $n;                       #ignore row
        next if grep { $key eq $_ } @$ignore;  #ignore row
        my @tmp = $self->schema_item_as_rdb_list('data', $row);
        push @cols, grep { defined and $_ ne '' } @tmp;  #strip empties
    }
    #warn "row_as_string: [@cols]\n\n";
    return join($delim, @cols);
}

#list of column widths for formatted columns
sub display_column_widths {
    my $self = shift;
    my @cols = ();
    my $ignore = $self->ignore_child_columns;
    #warn @$ignore;
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$DIS_SCHEMA) {
        my ($n, $key, $label) = @$row;
        next  unless $n;                        #ignore row

        if (grep { $key eq $_ } @$ignore) {     #zero width
            #warn "$key / ignore\n";
            push @cols, 0;
            next;
        }

        my @item = ();
        push @item, $self->schema_item_unformatted('attr', $row);
        if (@item) {
            #warn "$key = $item[0]\n" if @item; #non-zero width
            push @cols, length($item[0]);
        } else {
            push @cols, 0;                      #zero-width _data_
        }
    }
    #warn "display_column_widths: [@cols]\n";
    return @cols;
}

#list of column labels for formatted columns
sub display_column_labels {
    my $self = shift;
    my @cols = ();
    my $ignore = $self->ignore_child_columns;
    #warn @$ignore;
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$DIS_SCHEMA) {
        my ($n, $key, $label) = @$row;
        next  unless $n;                        #ignore row

        if (grep { $key eq $_ } @$ignore) {     #zero width
            #warn "$key / ignore\n";
            push @cols, '';
            next;
        }

        my @item = ();
        push @item, $self->schema_item_formatted('attr', $row);
        if (@item) {
            #warn "$key = $item[0]\n" if @item; #non-zero width
            push @cols, $item[0];
        } else {
            push @cols, '';                     #zero-width _data_
        }
    }
    #warn "display_column_labels: [@cols]\n";
    return @cols;
}

#list of column values for formatted columns
sub display_column_values {
    my $self = shift;
    my @cols = ();
    my $ignore = $self->ignore_child_columns;
    #warn @$ignore;
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$DIS_SCHEMA) {
        my ($n, $key, $label) = @$row;
        next  unless $n;                        #ignore row

        if (grep { $key eq $_ } @$ignore) {     #zero width
            #warn "$key / ignore\n";
            push @cols, '';
            next;
        }

        my @item = ();
        push @item, $self->schema_item_formatted('data', $row);
        if (@item) {
            #warn "$key = $item[0]\n" if @item; #non-zero width
            push @cols, $item[0];
        } else {
            push @cols, '';                     #zero-width _data_
        }
    }
    #warn "display_column_values: [@cols]\n";
    return @cols;
}

######################################################################
# protected methods
######################################################################
sub schema { [] }          #subclass overrides: default is empty
sub ignore_columns { [] }  #subclass overrides: default is empty

######################################################################
# private methods
######################################################################
sub ignore_child_columns {
    my $self = shift;
    my $ignore = $self->ignore_columns;  #from subclass
    push @$ignore, @$IGNORE_SEQUENCE_KEYS  unless $PAR->get('sequences');
    return $ignore;
}

#return a concatenated string of formatted schema data suitable for
#screen display
sub schema_data_as_formatted_string {
    my ($self, $mode, $delim) = (@_, ' ');

    my $fmtstr = sub {
        my $fmt = shift;
        return "%s"  unless $fmt;
        $fmt =~ /(\d+)(\S)/o;
        return "%-$1s"  if $2 eq 'S';
        return "%$1s";
    };

    my $schema = $self->schema;

    my @tmp = ();
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;

        next  unless $n1;  #ignore row

        my $fmt = &$fmtstr($format);

        if ($mode eq 'data') {
            my $data = $self->{'info'}->{$name};
            #warn "schema_data_as_formatted_string: $name => [$data]\n";
            push(@tmp, sprintf($fmt, $data));
            next;
        }
        push(@tmp, sprintf($fmt, $label)),  next  if $mode eq 'attr';
        push(@tmp, $format),                next  if $mode eq 'form';
    }
    return join($delim, @tmp);
}

#return a concatenated string of unformatted schema data suitable for
#simple output formats
sub schema_data_as_unformatted_string {
    my ($self, $mode, $delim) = (@_, ' ');

    my $schema = $self->schema;

    my @tmp = ();
    foreach my $row (sort { $a->[0] <=> $b->[0] } @$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;

        next  unless $n1;  #ignore row

        if ($mode eq 'data') {
            my $data = $self->{'info'}->{$name};
            #warn "schema_data_as_unformatted_string: $name => [$data]\n";
            push @tmp, $data;
            next;
        }
        push(@tmp, $label),  next  if $mode eq 'attr';
        push(@tmp, $format), next  if $mode eq 'form';
    }
    return join($delim, @tmp);
}

#return a list of unformatted schema data for rdb tab-separated columns
sub schema_data_as_rdb_list {
    my ($self, $mode) = (@_);

    my $schema = $self->schema;

    my @tmp = ();
    foreach my $row (sort { $a->[1] <=> $b->[1] } @$schema) {
        my ($n1, $n2, $name, $label, $format, $default) = @$row;

        next  unless $n2;  #ignore row

        if ($mode eq 'data') {
            my $data = $self->{'info'}->{$name};
            #warn "schema_data_as_rdb_list: $name => $data\n";
            push(@tmp, $data);
            next;
        }
        push(@tmp, $label),  next  if $mode eq 'attr';
        push(@tmp, $format), next  if $mode eq 'form';
    }
    return @tmp;
}

#one single column item, unformatted
sub schema_item_unformatted {
    my ($self, $mode, $row) = @_;
    my ($n, $key, $label) = @$row;
    my $data;
    if ($mode eq 'data') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_unformatted_string($mode) ];
            #warn "schema_item_unformatted($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $self->$key;
            #warn "schema_item_unformatted($mode): $key => [$data]\n";
            return $data;
        }
    }
    elsif ($mode eq 'attr') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_unformatted_string($mode) ];
            #warn "schema_item_unformatted($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $label;
            #warn "schema_item_unformatted($mode): $key => [$data]\n";
            return $data;
        }
    }
    return ();
}

#one single column item, formatted
sub schema_item_formatted {
    my ($self, $mode, $row) = @_;
    my ($n, $key, $label, $format) = @$row;

    my $fmtstr = sub {
        my $fmt = shift;
        return "%s"  unless $fmt;
        $fmt =~ /(\d+)(\S)/o;
        return "%-$1s"  if $2 eq 'S';
        return "%$1s";
    };

    my $fmt = &$fmtstr($format);
    my $data;

    if ($mode eq 'data') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_formatted_string($mode) ];
            #warn "schema_item_formatted($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = sprintf($fmt, $self->$key);
            #warn "schema_item_formatted($mode): $key => [$data]\n";
            return $data;
        }
    }
    elsif ($mode eq 'attr') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_formatted_string($mode) ];
            #warn "schema_item_formatted($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = sprintf($fmt, $label);
            #warn "schema_item_formatted($mode): $key => [$data]\n";
            return $data;
        }
    }
    elsif ($mode eq 'form') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_formatted_string($mode) ];
            #warn "schema_item_formatted($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $format;
            #warn "schema_item_formatted($mode): $key => [$data]\n";
            return $data;
        }
    }
    return ();
}

#one single column item, unformatted for rdb
sub schema_item_as_rdb_list {
    my ($self, $mode, $row) = @_;
    my ($n, $key, $label, $format) = @$row;
    my $data;
    if ($mode eq 'data') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_rdb_list($mode) ];
            #warn "schema_item_as_rdb_list($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $self->$key;
            #warn "schema_item_as_rdb_list($mode): $key => [$data]\n";
            return $data;
        }
    }
    elsif ($mode eq 'attr') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_rdb_list($mode) ];
            #warn "schema_item_as_rdb_list($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $label;
            #warn "schema_item_as_rdb_list($mode): $key => [$data]\n";
            return $data;
        }
    }
    elsif ($mode eq 'form') {
        if ($key eq '_data_') {
            $data = [ $self->schema_data_as_rdb_list($mode) ];
            #warn "schema_item_as_rdb_list($mode): $key => [@$data]\n";
            return @$data;
        } else {
            $data = $format;
            #warn "schema_item_as_rdb_list($mode): $key => [$data]\n";
            return $data;
        }
    }
    return ();
}

###########################################################################
1;
