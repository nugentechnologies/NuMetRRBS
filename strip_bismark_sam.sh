#!/bin/bash

usage(){
    echo >&2 ""
    echo >&2 "USAGE: $0 SAM_FILE"
    echo >&2 " --SAM_FILE required, output will go to [SAM_FILE]_stripped.sam"
    echo >&2 ""
}

# Run as paired end
if [ $# -eq 1 ]
        then
        FILE=$1
       
# Missing parameters
else
        echo >&2 ""
        echo >&2 "ERROR: 1 input SAM file required, see usage below."
        usage
        exit 1
fi

# Check input parameters
if [ ! -e "$FILE" ]
        then
        echo >&2 ""
        echo >&2 "ERROR: SAM file '$FILE' does not exist."
        exit 1
fi

cat <(grep -P '^@' $FILE)  <(paste <(grep -v -P '^@' $FILE | cut -f 1 | cut -f 1 -d '_') <(grep -v -P '^@' $FILE | cut -f 1 --complement)) > $FILE\_stripped.sam
