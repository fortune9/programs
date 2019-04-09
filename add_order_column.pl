#!/bin/env perl

use strict;
use Getopt::Long;

sub usage
{
	print STDERR "
	Usage: $0 <in-file> <column-file>

	This program adds one more column to <in-file>, and 
	the added column is simply the numbers determined by
	order of the values in the <column-file> by matching
	the key column (see the option --key-col). This added
	column can be used to sort the file and thus in effect
	have the <in-file> sorted according to the order specified
	in the <column-file>. The <column-file> should contain
	one value per line.

	For the values present in the key column but absent from
	<column-file>, they will be assigned an order number
	greater than any in <column-file>, increasingly with each
	new value observed.

	Options:

	-k/--key-col: <INT>. The column given by the column number
	in <in-file> to match the values in <column-file>. Default
	is 1, i.e., the 1st column.

	-s/--skip: <INT>. The number of lines to skip at the beginning
	of <in-file>. Default is 0.

	--fill: <STR>. The string used to fill the new column for
	skipped lines (see --skip). Default is '0'.

	-b/--before: If provided, the added column will be output as
	1st column.

";

	exit 1;
}

if($#ARGV < 0) { usage(); }

my $keyCol;
my $skip;
my $fill;
my $before;

GetOptions(
	'k|key-col:i'  => \$keyCol,
	's|skip:i'     => \$skip,
	'fill:s'       => \$fill,
	'b|before!'    => \$before
);

$keyCol ||= 1; $keyCol--;
$skip ||= 0;
$fill = '0' unless(defined $fill);

my $inFile = shift;
my $keyFile = shift or &usage();

my $outSep="\t";
my %keys;
my $order=0;
open(K, "< $keyFile") or die "cannot open $keyFile:$!";
while(<K>)
{
	next if /^\s*$/; # empty lines
	chomp;
	my $k = (split /\s/)[0]; # first non-blank value
	$keys{$k} = ++$order;
}

close K;

warn "[INFO] Start adding columns\n";

open(I, "< $inFile") or die "cannot open $inFile:$!";
while(<I>)
{
	chomp;
	if($skip > 0)
	{
		output_line($_, $fill);
		$skip--;
		next;
	}

	my $k = (split "\t")[$keyCol];
	unless(exists $keys{$k})
	{
		$keys{$k} = ++$order;
		warn "[WARN] Found unobserved key '$k', order=$order\n";
	}
	output_line($_, $keys{$k})
}

close I;

warn "[INFO] Job is done\n";

exit 0;

sub output_line
{
	my ($line, $col) = @_;
	if($before)
	{
		print $col, $outSep, $line, "\n";
	}else
	{
		print $line, $outSep, $col, "\n";
	}
}

