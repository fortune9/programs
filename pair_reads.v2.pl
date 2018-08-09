#!/usr/bin/env perl
use strict;
use BerkeleyDB;
use Getopt::Long;

$SIG{INT} = \&clean_tmp;
$SIG{TERM} = \&clean_tmp;

my $addSuf;

GetOptions(
	'suffix!'	=> \$addSuf
);

$addSuf = 1 unless(defined $addSuf);

my ($fq1,$fq2,$out) = @ARGV;

&usage() unless($out);

my $fh1 = _open_file($fq1);
my $fh2 = _open_file($fq2);
my $outFh1 = _open_file("${out}_1.fastq.gz", ">");
my $outFh2 = _open_file("${out}_2.fastq.gz", '>');
my $outFhUp = _open_file("${out}_up.fastq.gz", '>');

warn "# Indexing $fq2 first\n";

my %reads2;
my $tmpFile = $ENV{'TEMPDIR'}."/$fq2.$$.tmp"; # fq2 itself may contain
# folder, so it is safer to add suffix only
my $tmpFh;
open($tmpFh,"+> $tmpFile") or die "Can not open $tmpFile:$!";

my $counter = 0;
my $currPos;
my $prevPos = 0;
while(my ($read2Ref, $name) = _get_read($fh2, '2'))
{
	print $tmpFh $$read2Ref;
	$currPos = tell($tmpFh);
	$reads2{$name} = [$prevPos, $currPos-$prevPos];
	$prevPos = $currPos;
	warn sprintf("# %10d reads have been indexed at %s\n", $counter,
		scalar(localtime))
	if(++$counter % 1e6 == 0);
}

warn "# Reading $fq1 and compare to $fq2 at ".scalar(localtime)."\n";

my $upCnt1 = 0;
my $pairCnt = 0;
my $read1;
my $read2Ref;
while(my ($read1Ref, $name) = _get_read($fh1, '1'))
{
	$read1 = $$read1Ref;
	if(exists $reads2{$name}) # exists in both file
	{
		$read2Ref = _seek_read($tmpFh, $reads2{$name});
		print $outFh1 $read1;
		print $outFh2 $$read2Ref;
		delete $reads2{$name};
		$pairCnt++;
	}else # only in file 1
	{
		print $outFhUp $read1;
		$upCnt1++;
	}
}

# do not forget output the remaining reads in file 2
my $upCnt2 = 0;
while(my ($name, $pos) = each %reads2)
{
	$read2Ref = _seek_read($tmpFh,$pos);
	print $outFhUp $$read2Ref;
	$upCnt2++;
}

close $tmpFh;
&clean_tmp();

warn "# The whole work is done\n";
warn sprintf("#Paired: %10d\n#Unpaired[1]: %6d\n#Unpaired[2]: %6d\n",
	$pairCnt, $upCnt1, $upCnt2);

exit 0;

sub _seek_read
{
	my ($fh,$pos) = @_;

	my $read;
	seek($fh,$pos->[0],0); # set new start location
	read($fh,$read,$pos->[1]); # read the content
	return \$read;
}

sub _get_read
{
	my $fh = shift;
	my $suffix = shift;

	return () if eof $fh;
	$suffix = 0 unless($addSuf); # suppress suffix if necessary

	my $cnt = 0;
	my $read = '';
	my $name;
	my $hasSuffix; # indicate whether the sequence name already
	# contains suffix, if so, the original suffix would be kept and
	# will not add new one
	while($cnt++ < 4)
	{
		my $line = <$fh>;
		if($cnt == 1) # read name line
		{
			$hasSuffix = 1 if($line =~ /^\@\S+[\-\/]\d+\s/);
			($name) = $line =~ /^(\@\S+)/;
			if($suffix)
			{
				$line =~ s/^(\@\S+)/$1\/$suffix/ unless($hasSuffix); #
				# do not add suffix if already exists
			}

		}elsif($cnt == 3)
		{
			if($suffix)
			{
				$line =~ s/^(\+\S+)/$1\/$suffix/ unless($hasSuffix);
			}
		}

		$read .= $line;
	}

	$name =~ s/[\-\/]\d+$// # remove the suffix from the name
	if($hasSuffix);
	return (\$read, $name);
}

sub _open_file
{
	my $file = shift;
	my $type = shift;
	my $fh;

	if($file =~ /\.gz$/i)
	{
		if($type eq '>') # for output
		{
			open($fh, " | gzip >$file") or die "Can not open $file:$!";
		}else
		{
#			open($fh, "zcat $file |") or die "Can not open $file:$!";
			open($fh, "gzip -dc $file |") or die "Can not open $file:$!";
		}
	}else
	{
		open($fh, "$type $file") or die "Can not open $file:$!";
	}

	return $fh;
}

sub clean_tmp
{
	unlink "$tmpFile" if(-e "$tmpFile");
}

sub usage
{
	print <<USAGE;
Usage: $0 <fastq1> <fastq2> <out>

This program is to pair the sequence reads from the two input files,
and output three files: <out>_1.fastq.gz <out>_2.fastq.gz
<out>_up.fastq.gz

Options:

--suffix: a switch option, if provided, suffix /1 and /2 will be added to
read names. Default is True, so suffixes are added.

Updates:

Mon Mar  6 14:09:18 EST 2017
1. add \$SIG{INT} and \$SIG{TERM} handlers to clean temporary files
before abnormal exit.

Thu Apr 14 13:49:41 EDT 2016
1. use '/' to separate suffixes for read names.
2. add one option --suffix to choose adding suffix /1 and /2 at
the end of squence read names or not.

USAGE

	exit 1;

}

