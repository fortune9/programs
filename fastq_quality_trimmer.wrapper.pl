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

&usage() and 
die "Input or output files are missing for fastq_quality_trimmer:$!"
unless($fastqFile);

#give a unique id for each run of the program
my $ID = $$; # get PID
my $cat = $fastqFile =~ /\.gz$/i? 'zcat' : 'cat';

print "====== Trim reads by quality [$ID] ======\n";
print ">>>$ID: ", scalar(localtime), "\n";
my $lineNum=`$cat $fastqFile | wc -l | cut -f 1 -d " "`;
print "$ID [$fastqFile]: Reads count[before trim]: ",$lineNum/4, "\n";
my $fmt = '%C\nElapsed:%e\tUser:%U\tSys:%S';
my $cmd = "/usr/bin/time -f '$fmt' $cat $fastqFile | fastq_quality_trimmer @ARGV";
$cmd .= " -o $outFile" if($outFile);
#print "CMD>>\n$cmd\n"; exit 1;
system("$cmd") and die "Quality trimming on $fastqFile failed:$!";

if($outFile)
{
$lineNum= ($outFile =~ /\.gz$/i)? 
`zcat $outFile | wc -l | cut -f 1 -d " "` :
`cat $outFile | wc -l | cut -f 1 -d " "`;
print "$ID [$outFile]: Reads count[after trim]: ", $lineNum/4, "\n";
}
print "<<<$ID: ", scalar(localtime), "\n";

exit 0;

sub usage
{
	print <<USAGE;
$0 [options]

The purpose of this wrapper is to provide statistic summary for the
trimming process such as how many sequences are discarded.

The options are exactly the same as those for the original
'fastq_quality_trimmer' tool, so run 'fastq_quality_trimmer' for
options' help.

Created:
Wed Jun 18 13:55:30 EDT 2014

USAGE

	exit 1;
}
