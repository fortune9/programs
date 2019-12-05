#!/usr/bin/env perl

use strict;
use Getopt::Long;

my $sep = "\t"; # field separator
my $idCol;
my $fieldCols;
my $types;
my $outFile;
my $noTies;

GetOptions(
	"id=i"	=> \$idCol,
	"fields=s" => \$fieldCols,
	"types=s"  => \$types,
	"no-ties!" => \$noTies,
	"outfile:s" => \$outFile,
	"sep:s"	=> \$sep
);

my $inFile = shift or usage();

my @types = split /,/, $types;
my @cmpCols = split /,/, $fieldCols;
if($#types != $#cmpCols)
{
	die "The numbers of provided fields and types differ; check the options:$!";
}

@cmpCols=map { $_-1 } @cmpCols; # convert to array index
$idCol--;

my $fh = _open_file($inFile);
my $o = _open_file($outFile,">");
$o = $o->{_handle};

# process the records for one id by one
my $i = 0;
while(my $record = _next_record($fh))
{
	my $bestHit=_best_hit($record);
	_output_hit($bestHit);
	warn "$i records have been processed\n"
	if(++$i % 10000 == 0);
}

close $fh->{_handle};
close $o if $outFile;

warn "Job is done at ", scalar(localtime), "\n";

exit 0;

sub _best_hit
{
	my $record = shift;
	if($#$record < 1) # only one item for this id
	{
		return $record;
	}
	my @bestIndice = (0);
	my $best = $record->[0]; # the first one
	for(my $j = 1; $j <= $#$record; $j++)
	{
		my $res = _cmp_hits($best, $record->[$j]);
		if($res == 0) # equal
		{
			push @bestIndice, $j; # add this hit
		}elsif($res < 0) # new one is better
		{
			@bestIndice = ($j);
			$best = $record->[$j];
		} # otherwise old one is better, and do nothing
	}
	# if no ties, choose the first best one
	if($noTies) { @bestIndice = ($bestIndice[0]); }
	return [@{$record}[@bestIndice]];
}

sub _cmp_hits
{
	my ($a, $b)=@_;
	my $res;
	for(my $k=0; $k <= $#types; $k++)
	{
		my $v1=$a->[$cmpCols[$k]];
		my $v2=$b->[$cmpCols[$k]];
		my $t = $types[$k];
		$res = _value_cmp($t, $v1, $v2);
		next unless($res); # no difference
		return $res; # difference found
	}
	return 0; # no difference in all fields
}

sub _value_cmp
{
	my ($t, $v1, $v2) = @_;
	my $r;
	if($t eq "s")
	{
		$r=$v1 cmp $v2;
	}elsif($t eq "n")
	{
		$r=$v1 <=> $v2;
	}elsif($t eq "-s")
	{
		$r=$v2 cmp $v1;
	}elsif($t eq "-n")
	{
		$r=$v2 <=> $v1;
	}else
	{
		die "Unknown cmp type '$t':$!";
	}
	return $r;
}

sub _output_hit
{
	my $hits = shift;
	foreach (@$hits)
	{
		print $o join($sep, @$_), "\n";
	}
}

sub _next_line
{
	my $fh = shift;
	my $line = shift @{$fh->{_stack}};
	return $line if defined($line);
	# otherwise read a new line
	my $handle = $fh->{_handle};
	if(eof($handle)) { return; }
	while($line=<$handle>)
	{
		next if $line =~ /^\s*$/; # skip empty lines
		chomp $line;
		return $line;
	}
	return;
}

sub _stack_line
{
	my ($fh, $line) = @_;
	push @{$fh->{_stack}}, $line;
	return 1;
}

sub _next_record
{
	my $fh = shift;
	my @record;
	my $id;
	while(my $line = _next_line($fh))
	{
		my @tmp = split /$sep/, $line;
		if(defined($id))
		{
			if($tmp[$idCol] eq $id)
			{
				push @record, \@tmp;
			}else # a new line
			{
				_stack_line($fh, $line);
				last;
			}
		}else # first record
		{
			push @record, \@tmp;
			$id=$tmp[$idCol];
		}
	}
	return unless(@record); # empty records
	return \@record;
}

sub _open_file
{
	my ($f, $mode) = @_;
	$mode="<" unless $mode; # default mode
	$f ||= '-'; # default input/output
	my $fh;
	if($f =~ /\.gz$/) # compressed
	{
		if($mode eq "<") # reading
		{
			open($fh, "zcat $f |") or die "can't open $f:$!";
		}else
		{
			open($fh, "| gzip -c >$f") or die "can't open $f for writing:$!";
		}
	}else
	{
		open($fh, "$mode $f") or die "can't open $f:$!";
	}
	return { _handle => $fh, _stack => [] };
}


sub usage
{
	print <<EOF;
Usage: $0 [options] <infile>

This program compares specified fields and chooses one line with 
the 'biggest' values for each id. The values compared field by field
until a difference found, so the order of specified fields matters.
Also if one wants to choose the smaller value for a field, use the
format like -s or -n for the option --types (see below).

To read from standard input, give '-' as <infile>.

Options (default values are in []):

--sep: <char> the field separator for both input and output files.
[tab]

--id: <int> the field containing the id, lines with the same id
are compared at the specified fields (see option --fields).

--fields: <int1,int2,...> a number of integers giving the fields
which are compared.

--types: <str1,str2,...> the types of the comparisons for the above
specified fields. The values can be 's' for string comparison and 'n'
for numerical comparison. If only one value is provided, then it is
used for all compared fields. [s]

--no-ties: if provided, only one line for each id is output, even if
ties exist for the compared fields.

--outfile: <path> the outfile to store result. If the file has a '.gz'
extension, it will be output as gzipped format. [stdout]

Example uses:

# choose the biggest based on the fields 2 and 3
$0 --id 1 --fields 2,3 --types n,n test.tsv

# same as above but choose the smallest for field 2
$0 --id 1 --fields 2,3 --types '-n,n' test.tsv

# exclude ties by selecting the first biggest line
$0 --id 1 --fields 2,3 --types n,n --no-ties test.tsv

EOF

	exit 1;
}
