#!/bin/env perl

use strict;
use Getopt::Long;

my $W = '[WARN]';

my $paired;
my $correctAll;

GetOptions(
	"pair!"  => \$paired,
	"correct-all!"  => \$correctAll
);

my $contFile = shift;
my $lineFile = shift or &usage();
my $rev = shift;

#rather than storing all the line numbers in a hash, we will read it
#line by line, which should have been sorted
my %lines;
my $expected = 0;
my $currNum = -1;
open(L,"< $lineFile") or die "can't open $lineFile:$!";

# now extract lines
open(C, "< $contFile") or die "can't open $contFile:$!";
my $counter = 0; # line number in contFile
my $extracted = 0;
$currNum=next_num(); # first number
my @lastRecord; # a read pair or a read
my @record;
my $storedLine; # for storing a line to pair with next

while(@record = _read_record())
{
	unless(defined $currNum) # No more numbers in $lineFile
	{
		#warn "No more numbers in $lineFile\n";
		if($rev) # output the remaining of contFile
		{
			_output_record(); $extracted++; $counter++;
			# the remaining record are not corrected
			while(@record = _read_record()) 
			{$extracted++; $counter++; print @record;}
		}
		last;
	}
	$counter++;
	die "Record number [$counter] is greater than requested number [$currNum]:$!"
	if($counter > $currNum);

	if($rev) # reverse mode
	{
		if($counter==$currNum)
		{
			$currNum=next_num(); # pose next challenge
			next;
		}
		# otherwise output the record

	}else # normal mode
	{
		next if($counter != $currNum);
		$currNum=next_num(); # update and output the record
	}
	
	_output_record();
	if(++$extracted % 1e6 == 0)
	{
		warn "$extracted records have been extracted\n";
	}
}
close C;
close L;

$expected = $counter - $expected if($rev);
warn "Work done! Extracted: $extracted; Expected: $expected\n";

exit 0;

sub _output_record
{
	if($paired)
	{
		_correct_lines(\@record) unless($correctAll);
		print @record;
	}else
	{
		print @record;
	}
	return 1;
}

sub _read_record
{
	@lastRecord = @record;
	my @lines;
	return @lines if(eof(C));

	if($paired)
	{
		push @lines, $storedLine || _read_line(), _read_line(); # two lines
		$storedLine=undef; # undefine it after using it
		_correct_lines(\@lines) if($correctAll);
	}else
	{
		push @lines, _read_line();
	}

	return @lines;
}

sub _read_line
{
	my $line = <C>;
	return $line;
}

sub _correct_lines
{
	my $linesRef = shift;
	my ($line1, $line2) = @$linesRef;
	my ($name1, undef) = split "\t", $line1;
	my ($name2, undef) = split "\t", $line2;
	if($name1 eq $name2) # great pair
	{
		return 0;
	}
	# otherwise check the previous line in last record
	unless(@lastRecord) # current record is the first
	{
		warn "$W Single read '$name1' found\n";
		@$linesRef = ($line1); # modify the record in place
		$storedLine = $line2; # leave this line for next pair
		return 1;
	}
	my (undef, $preLine) = @lastRecord;
	my ($name, undef) = split "\t", $preLine;
	if($name1 eq $name)
	{
		@$linesRef = ($preLine,$line1);
		$storedLine = $line2; # leave this line for next pair
		return 2;
	}else # a single read
	{
		warn "$W Single read '$name1' found\n";
		@$linesRef = ($line1); 
		$storedLine = $line2; # leave this line for next pair
		return 1;
	}
}

sub next_num
{
	while(<L>)
	{
		next if /^\s*$/ or /^#/;
		s/^\s+//;
		s/\s+$//;
		next unless /^[0-9]+$/o;
		die $! if $_ < $currNum;
		$currNum = $_;
		$expected++;
		return $_;
	}
	return undef;
}

sub usage
{
	print <<USAGE;
	$0 [--pair] <content-file> <line-num-file> [<reverse>]

	Options:
	--pair: 
		if given, extracting is done in paired-read mode. 
		The default is single-end mode
	--correct-all: 
		if given, all the read pairs are checked. 
		The default is to only check the pair to extract.

USAGE

	exit 1;
}
