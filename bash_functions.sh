# this file contains common bash functions and used by sourcing in
# other bash files.

# check whether a command is available
function check_exe
{
	if [[ $(command -v $1) ]]; then
		echo "command '$1' exist"
	else
		echo "";
	fi
}

