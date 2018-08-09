#!/bin/env perl

use strict;

my $contFile = shift;
my $lineFile = shift or &usage();
my $rev = shift;

# store all the line numbers in a hash
my %lines;
my $expected = 0;
open(L,"< $lineFile") or die "can't open $lineFile:$!";
while(<L>)
{
	chomp;
	$lines{$_}++;
	$expected++;
}
close L;

# now extract lines
open(C, "< $contFile") or die "can't open $contFile:$!";
my $counter = 0;
my $extracted = 0;
while(<C>)
{
	$counter++;
	next if($rev and $lines{$counter});
	next if(!$rev and !$lines{$counter});
	print;
	if(++$extracted % 1e6 == 0)
	{
		warn "$extracted lines have been extracted\n";
	}
}
close C;

warn "Work done! Extracted: $extracted; Expected: $expected\n";

exit 0;

sub usage
{
	print <<USAGE;
	$0 <content-file> <line-num-file> [<reverse>]

USAGE

	exit 1;
}
