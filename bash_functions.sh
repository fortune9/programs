# this file contains common bash functions and used by sourcing in
# other bash files.

# IO
function msg()
{
	echo -e "$*" >&2
}


# testing
## check whether a command is available
function check_exe
{
	if [[ $(command -v $1) ]]; then
		echo "command '$1' exist"
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

