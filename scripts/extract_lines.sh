#!/bin/bash

if [[ $# -lt 2 ]]; then
	echo "
	Usage: $0 <input-content-file> <line-num-file> [<reverse-if-provided>]

	This program reads the specified lines (given by the line numbers
	contained in <line-num-file>) from <input-content-file>.

	If a file is read from standard input (i.e., a terminal), please
	specify it as '-'.
	
	Note: the line numbers in <line-num-file> should be one number per
	line
	
	If the last (3rd) argument is provided, then the lines not
	specified in <line-num-file> are output instead.
	"

	exit 1;
fi

contFile=$1;
lineFile=$2;
rev=$3

if [[ -n "$rev" ]]; then
	echo "# Reverse mode" >&2
fi

# step 1: store the line numbers into an array
declare -A lineNums

maxLine=-1
expected=0
while read i
do
	lineNums[$i]=1; let 'expected = expected + 1'
	if [[ $i -gt $maxLine ]]; then
		maxLine=$i
	fi
done < <(cat -- "$lineFile")


# extract corresponding lines now
# define a global line counter
counter=0
extracted=0; # record the number extracted lines
while read line
do
	let "counter = counter + 1"
	if [[ $counter -gt $maxLine ]]; then
		break
	fi

	if [[ -z "$rev" && -n "${lineNums[$counter]+1}" ]]; then
		#echo $line # this may expand some special letters
		printf "%s\n" "$line"; let "extracted = extracted + 1";
		continue
	fi

	if [[ -n "$rev" && -z "${lineNums[$counter]+1}" ]]; then
		printf "%s\n" "$line"; let "extracted = extracted + 1";
		continue
	fi

done < <(cat -- "$contFile")

echo "# $extracted lines are extracted [$expected expected]" >&2

exit 0;

