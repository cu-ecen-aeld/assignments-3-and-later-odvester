#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
	echo "Error: Two arguments are required."
	echo "Usage: ./writer.sh [filepath] [write_string]"
	exit 1
fi

# Assignments to variables for easier reference
writefile=$1
writestr=$2

# Extract the directory name from the full file path
dir=$(dirname "$writefile")

# Check if the directory exists, if not create it
if [ ! -d "$dir" ]; then
	mkdir -p "$dir"
	if [ $? -ne 0 ]; then
		echo "Error: Directory '$dir' could not be created."
		exit 1
	fi
fi

# Try to write to the file
echo "$writestr" > "$writefile"

# Check if the write was successful
if [ $? -ne 0 ]; then
	echo "Error: file '$writefile' could not be created."
	exit 1
fi

echo "File '$writefile' created successfully."
