#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
	echo "Error: Two arguments are required."
	echo "Usage: ./finder.sh [directory] [search_string]"
	exit 1
fi

# Assign arguments to variables for easier reference
filesdir=$1
searchstr=$2

# Check if filesdir exists and is a directory
if [ ! -d "$filesdir" ]; then
	echo "Error: Given path '$filesdir' is not a directory."
	exit 1
fi

# Use find to get count of all files in the directory and subdirectories
filecount=$(find "$filesdir" -type f | wc -l)

# Use grep to find the count of all lines in all files that match the searchstr
matchcount=$(grep -r "$searchstr" "$filesdir" | wc -l)

# Print the output
echo "The number of files are $filecount and the number of matching lines are $matchcount"
