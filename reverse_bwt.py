#!/bin/env python

import sys;

null = '\0';

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
			bw.append(null);
		else:
			bw.append(T[si-1])
	return ''.join(bw);

def bwm(T):
	""" Given a string, get the Burrows-Wheeler Matrix.
	"""
	bwm = [];
	t = T + null;
	tLen = len(t);
	lasti = tLen - 1;
	lastRow = t;
	for i in xrange(tLen):
		row = lastRow[lasti:] + lastRow[:lasti];
		bwm.append(row);
		lastRow=row;
	return(sorted(bwm));

def rank_bwt(bw):
	""" Give a BWT string, return a B-rank and tots -- a mapping from
	characters to the number of times the character appeared in BWT
	"""
	tots = dict();
	ranks = [];
	for c in bw:
		if c not in tots:
			tots[c] = 0;
		ranks.append(tots[c]);
		tots[c] += 1;
	return ranks, tots;	

def firstCol(tots):
	""" Get the range for each character in the first column of BWM
	matrix
	"""
	first = {};
	totc = 0;
	for c, count in sorted(tots.iteritems()):
		first[c] = (totc, totc + count);
		totc += count;
	return first;

def rev_bwt(bw):
	""" Recover T from BWT
	"""
	ranks, tots = rank_bwt(bw);
	first = firstCol(tots);
	rowi = 0;
	t = null;
	while bw[rowi] != null:
		c = bw[rowi];
		t = c + t; # prepend the character
		# first[c][0] is the first row where the character 'c' occurs
		# in the first column, ranks[rowi] is the B-rank of 'c', which
		# is the same as the rank in the first column for 'c', so the
		# sum of these two gives the right row number for 'c' in first
		# column.
		rowi = first[c][0] + ranks[rowi];
	return t.rstrip(null);
try:
	input=sys.argv[1];
except:
	print "Usage: %s <bwt-string>" % sys.argv[0];
	sys.exit(1);

#sa = suffix_array(input);
bwmL = bwt(input);
orig = rev_bwt(bwmL);
print("The Burrows Wheeler Transform is: '%s'\n" % bwmL);
print("The recovered string is: '%s'\n" % orig);

sys.exit(0);

