#!/bin/env python

import sys;
import random as rd;

try:
	maxInt=int(sys.argv[1]);
	size=int(sys.argv[2]);
except:
	print """
	Usage: {0} <max-int> <size> [<min-int>]

	This program generates <size> random numbers between <min-int>
	(default 1) and <max-int>""".format(sys.argv[0]);
	sys.exit(1);

if len(sys.argv) > 3:
	minInt=int(sys.argv[3]);
else:
	minInt=1


# now generate the random numbers
# if the sample size is too large, say large than 1M, then we had
# better sample them chunk by chunk to lower memory usage
chunkSize=int(1e6); # the largest size to get from each call of 'rd.sample'
numChunks=int((size+chunkSize-1)/chunkSize);
spaceSize=round((maxInt - minInt + 1)/(size*1.0/chunkSize));
spaceSize=int(spaceSize);

for i in xrange(numChunks):
	# determine the sub-space
	start=i*spaceSize + 1;
	end  =start + spaceSize -1;
	# determine the local sample size
	localSize=chunkSize;
	# the situtation for last chunk
	if end > maxInt:
		end = maxInt;
		if size % chunkSize:
			localSize = size % chunkSize;
	
	#frac=localSize*1.0/(end-start+1);
	#print >> sys.stderr, "# {0}: {1}".format(i, frac);
	#print >> sys.stderr, "#>> {0}, {1}, {2}".format(start, end, localSize);
	rdNums=rd.sample(xrange(start, end), localSize);
	for num in rdNums:
		print num

sys.exit(0);

