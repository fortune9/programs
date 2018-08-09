#!/bin/env python

import sys;

def suffix_array(s):
	""" Given a string, returning a suffix array
	"""
	satups = sorted([(s[i:], i) for i in xrange(0, len(s) + 1)]);
	return map(lambda x: x[1], satups); # get only offsets

def bwt(T):
	""" Given a string T, returning BWT(T), i.e. the last column of
	sorted rotation matrix
	"""
	bw = [];
	for si in suffix_array(T):
		if si == 0:
			#bw.append('$');
			bw.append('\0');
		else:
			bw.append(T[si-1])
	return ''.join(bw);

def bwm(T):
	""" Given a string, get the Burrows-Wheeler Matrix.
	"""
	bwm = [];
	t = T + '\0';
	tLen = len(t);
	lasti = tLen - 1;
	lastRow = t;
	for i in xrange(tLen):
		row = lastRow[lasti:] + lastRow[:lasti];
		bwm.append(row);
		lastRow=row;
	return(sorted(bwm));


try:
	input=sys.argv[1];
except:
	print "Usage: %s <string>" % sys.argv[0];
	sys.exit(1);

#sa = suffix_array(input);
bwtL = bwt(input);
bwMat = bwm(input);
print("The Burrows-Wheeler Matrix:")
print("\n".join(bwMat));
print("The Burrows-Wheeler Transformation:")
print("\n".join(bwtL));

sys.exit(0);

