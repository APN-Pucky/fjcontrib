#!/bin/bash
#
# usage:
#   ./check.sh <program> <datafile>
#
# this script checks if "<program>" exists, runs it using <datafile>
# as an input, and compares the output with "<program>.ref" (it fails if
# "<program>.ref" does not exist),
#
# Note that <program> is actually run using "./<program> < <datafile>"

GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

function print_status_and_exit {
if [ $2 == "Success" ]; then
   col=$GREEN
else
   col=$RED
fi      
    printf "  %-20s %-25s %s\n" `pwd | sed 's/.*\///g'` "$1" "${col}$2${NORMAL}" >> ../test_summary.tmp
    #-----------------------------------------------------------------
    # NOTE:
    #   This will cause the check test to exit with no error. 
    #   Comment this line out if you want errors to cause Make to stop
    exit
}

echo
echo -n "In directory" `pwd | sed 's/.*\///'`
echo "/ checking the output of '$1' using the input file"
echo "$2 and reference file $1.ref"

# check that all the necessary files are in place
#
# Note that, for the executable, the Makefile should in principle
# rebuild the program if it is absent or not executable
test -e ./$1 || { echo "ERROR: the executable $1 cannot be found."; print_status_and_exit "$1" "Failed (executable not found)"; exit 1;}
test -x ./$1 || { echo "ERROR: $1 is not executable."; print_status_and_exit "$1" "Failed (program not executable)"; exit 1;}
test -e ./$1.ref || { echo "ERROR: the expected output $1.ref cannot be found."; print_status_and_exit "$1" "Failed (reference output not found)"; exit 1;}
test -e ./$2 || { echo "ERROR: the datafile $2 cannot be found."; print_status_and_exit "$1" "Failed (datafile not found)"; exit 1;}

# make sure that the reference output file is not empty (after removal of
# comments and empty lines)
[ -z "$(cat ./$1.ref | grep -v '^#' | grep -v '^$')" ] && {
    echo "ERROR: the reference output, $1.ref"
    echo "should contain more than comments and empty lines"
    echo
    print_status_and_exit "$1" "Failed (no valid reference)"
    exit 1
}

# run the example
./$1 < $2 2>/dev/null | grep -v "^#" > $1.tmp_ref

DIFF=`cat $1.ref | grep -v "^#" | diff $1.tmp_ref -`
if [[ -n $DIFF ]]; then 
    cat $1.ref | grep -v "^#" | diff $1.tmp_ref - > $1.diff
    echo "ERROR: Outputs differ (diff available in $1.diff)"
    echo
    rm $1.tmp_ref
    print_status_and_exit "$1" "Failed (see difference file)"
    exit 1
fi

rm $1.tmp_ref

print_status_and_exit "$1" "Success"
