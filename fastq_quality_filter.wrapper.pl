#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw(:config pass_through);

my @args = @ARGV;

# get the input file name
my $fastqFile;
my $outFile;
GetOptions(
	"i=s"	=> \$fastqFile,
	"o=s"	=> \$outFile
);

die "Input or output files are missing for fastq_quality_filter:$!"
unless($fastqFile);

#die "$0 can not process gzipped input file:$!"
#if($fastqFile =~/\.gz$/i);

# get step id in a project
my $ID = $$; # PID

print "====== Filter reads by quality [$ID] ======\n";
print ">>>$ID: ", scalar(localtime), "\n";
my $cat = $fastqFile =~ /\.gz$/i? 'zcat' : 'cat';
my $lineNum=`$cat $fastqFile | wc -l | cut -f 1 -d " "` 
	or die "Can not count lines in $fastqFile:$!";
print "$ID [$fastqFile]: Reads count[before filter]: ",$lineNum/4, "\n";
my $fmt = '%C\nElapsed:%e\tUser:%U\tSys:%S';
my $cmd = "/usr/bin/time -f '$fmt' $cat $fastqFile | fastq_quality_filter @ARGV";
$cmd .= " -o $outFile" if($outFile);
#print "CMD>>\n$cmd\n"; exit 1;
system("$cmd") and die "Quality filter on $fastqFile failed:$!";

if($outFile)
{
$lineNum= ($outFile =~ /\.gz$/i)? 
`zcat $outFile | wc -l | cut -f 1 -d " "` :
`cat $outFile | wc -l | cut -f 1 -d " "`;
print "$ID [$outFile]: Reads count[after filter]: ", $lineNum/4, "\n";
}else
{
	warn "# Statistics can not be estimated for output of $fastqFile because the output went to standard output\n";
}
print "<<<$ID: ", scalar(localtime), "\n";

exit 0;

sub usage
{
	print <<USAGE;
$0 [options]

The purpose of this wrapper is to provide statistic summary for the
filtering process such as how many sequences are discarded.

The options are exactly the same as those for the original
'fastq_quality_filter' tool, so run 'fastq_quality_filter' for
options' help.

Created:
Wed Jun 18 13:55:30 EDT 2014

USAGE

	exit 1;
}
