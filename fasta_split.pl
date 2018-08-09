#!/usr/bin/perl -w

use strict;
use Bio::SeqIO;

my $file = shift;
my $dir  = shift;

die "$0 seq-file [out-dir]:$!" unless(-f $file);

my $seqIO = Bio::SeqIO->new(-file => $file, -format => 'fasta');
$dir ||= "$file.dir";

mkdir($dir) or die "can not create directory $dir:$!" unless(-d $dir);

my $counter = 0;

while(my $seq = $seqIO->next_seq)
{
	++$counter;
	my $seqOut = Bio::SeqIO->new(-file => ">$dir/$counter.fsa", -format => 'fasta');
	$seqOut->write_seq($seq);
}

warn "Totally $counter sequences are written to $dir\n";

exit 0;
