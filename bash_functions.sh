# this file contains common bash functions and used by sourcing in
# other bash files.

# IO

pg=`basename $0`;
program=$pg;

function msg()
{
	echo -e "[$pg] $*" >&2
}

function error()
{
	msg "[ERROR] $*"
}

function warn()
{
	msg "[WARN] $*"
}

## get the number of fields in a file
function file_nf
{
    f=$1;
    sp=${2:-"\t"}
    nf=($(less $f | gawk -v FS=$sp 'NR<100{print NF}' | uniq))
    if [[ ${#nf[@]} -gt 1 ]]; then
            echo "Inconsistent number of fields in $f"
    else
            echo $nf
    fi
}

## check whether a command is available
function check_exe
{
	if [[ $(command -v $1) ]]; then
		echo "command '$1' exist"
	else
		echo "";
	fi
}

# string functions
## split a string to separate lines
function str_split
{
	sp=$1;
	st=$2;
	# updated into a loop to change empty string to ''
	while IFS= read i
	do
		if [[ $i == "" ]]; then
			i="''";
		fi
		echo $i
	done < <(echo "$st" | sed -e "s/$sp/\n/g")
}

## case conversion
function to_upper
{
	echo "$*" | tr '[:lower:]' '[:upper:]'
}

function to_lower
{
	echo "$*" | tr '[:upper:]' '[:lower:]'
}

## generate random alphabet string
function rand_str
{
	len=${1:-8}; # string length
	echo $(head -10 /dev/urandom | tr -dc '0-9a-zA-Z' | fold -w $len | head -1)
}

## test whether a string is number
function is_num
{
	if [[ "$1" =~ ^-?[0-9.]+$ ]]; then
		echo "ok"
	else
		echo ""
	fi
}

function is_int
{
	if [[ "$1" =~ ^-?[0-9]+$ ]]; then
		echo "ok"
	else
		echo "";
	fi
}


# computing
## use bc to compare/compute numbers
function pass_bc
{
	echo -e "$*" | bc -l
}

