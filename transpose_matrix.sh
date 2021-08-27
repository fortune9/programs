#!/bin/bash

function transpose_row {
    tr "$sep" "\n"
}

function is_gzipped {
    if [[ "$1" =~ \.gz$ ]]; then
        echo "Y"
    else
        echo ""
    fi
}

if [[ $# -lt 2 ]]; then
    cat <<EOF
Usage: $0 [options] <input-file> <out-file>

This program transposes a matrix-like file,
so that the rows become columns and columns
become rows.

<input-file> and <out-file> are filenames
for input and output files.

Options (default values in []):

--sep <character> the field separator for both
    input and output files [,].

--skip-lines <int> the number of lines to skip
    from input file [0].

EOF

    exit 1
fi

sep=,
skip=0
posArgs=()

while [[ $# -gt 0 ]]
do
    k="$1";shift;
    case $k in
        --sep)
            sep=$1;
            shift;
            ;;
        --skip-lines)
            skip=$1;
            shift;
            ;;
        *)
            posArgs+=("$k")
            ;;
    esac
done

inFile=${posArgs[0]}
outFile=${posArgs[1]}

if [[ $( is_gzipped "$inFile") ]]; then
    myCat=zcat
else
    myCat=cat
fi

# get the first two lines to check whether they have
# the same number of fields
fieldCounts=($( $myCat $inFile | \
    gawk -v FS="$sep" -v s=$skip 'NR>s&&NR<s+3{print NF}'))

first=${fieldCounts[0]}
second=${fieldCounts[1]}
dif=$(( first - second ))
firstLine=$( $myCat $inFile | gawk -v s=$skip 'NR>s' | head -1)

if [[ $dif -eq 0 ]]; then
    # the field counts are the same
    numField=$first
    tped=$(echo "$firstLine" | transpose_row)
elif [[ $dif -eq -1 ]]; then
    # first row has 1 fewer field, so will treat as header
    numField=$second
    # prepend an empty field
    tped=$(echo "$sep$firstLine" | transpose_row)
else
    echo "Unknown format for the input data"
    exit 2;
fi

tmpOut=tmp.tp.$$.out
echo "$tped" >$tmpOut

counter=0

# start from 2nd row
$myCat $inFile | gawk -v s=$skip 'NR>s+1' | while read line
do
    paste -d "$sep" $tmpOut \
        <(echo "$line" | transpose_row ) \
        >tmp.$$
    mv tmp.$$ $tmpOut
    counter=$(( counter + 1 ))
    if [[ $(( counter % 1000 )) -eq 0 ]]; then
        echo "## $counter lines have been processed."
    fi
done

if [[ $(is_gzipped "$outFile") ]]; then
    cat $tmpOut | gzip -c >"$outFile" && \
        rm $tmpOut
else
    mv $tmpOut "$outFile"
fi

echo "Job done [$outFile]"

exit 0

