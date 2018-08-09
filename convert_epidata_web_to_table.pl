#!/bin/env perl

use strict;
use File::Basename;

my $sep = "\t";
my $exeDir = dirname($0);

my $inFile = shift or &usage();
my $outFile = shift || '-';

open(IN, "< $inFile") or die "cannot open $inFile:$!";
open(OUT, "> $outFile") or die "cannot open $outFile:$!";
my @row;
my $percentCnt = 0;
my $header = 1;
while(<IN>)
{
	if(/^(in471_\d+)\s*$/)
	{
		&output() if @row;
		$percentCnt = 0;
		@row = ($1); # initialize with new sample
		next;
	}
	if(/^(in471_\d+)\s*(\S+)/)
	{
		$row[11] = $1;
		$row[12] = $2;
		@row[1..3] = ('NA','NA','NA');
		next;
	}
	if(/(\d+)\s+weeks?\s+(\w+)\s+(\d+)/i)
	{
		@row[1..3] = ($1, $2, $3); # age, sex, number
		next;
	}
	if(/^(mini|midi|RNA)\s*(PE|SE)?/i)
	{
		@row[4..5] = ($1, $2 || 'NA'); # type and mode
		next;
	}
	if(/^([0-9,]+)\s+read/i)
	{
		$row[6] = $1; # number of reads
		next;
	}
	if(/^(\d+)\%/)
	{
		$row[7 + $percentCnt++] = $1; #mapping efficiency and conversion rate
		next;
	}
	if(/^([0-9,]+)\s*$/)
	{
		$row[9] = $1; # unique CpG sites
		next;
	}
	if(/^(\d+)X/)
	{
		$row[10] = $1; # coverage
		next;
	}
}
# don't forget the last piece
&output() if @row;
close IN;
close OUT;

exit 0;

sub output
{
	foreach (8,9,10,11,12)
	{
		$row[$_] = 'NA' unless(defined $row[$_]);
	}
	print OUT join($sep, qw/sample_id age sex replicate seq_type mode num_reads map_efficiency bis_conv_rate num_uniq_cpg coverage orig_sample treatment/), "\n" if($header);
	print OUT join($sep, @row), "\n";
	$header = 0;
}

sub usage
{
	print <<USAGE;
Usage: $0 <web-text-file> [<out-file>]

This program converts the sample information copied from http://epidata.zymoresearch.com to a table, delimited by tab.

Unless <out-file> is specified, the output goes to standard output.

Example input and output can be found at $exeDir/convert_epidata_web_to_table.in.txt and  $exeDir/convert_epidata_web_to_table.out.tsv 

Author: Zhenguo Zhang
Created: Mon May  8 12:54:35 EDT 2017

USAGE

	exit 1;
}

