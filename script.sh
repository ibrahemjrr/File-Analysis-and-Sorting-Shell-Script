#!/bin/bash

displayHelp() {
  echo ""
  echo "Usage: script.sh [extension1 extension2 ... ] [directory]"
  echo ""
  echo "This script searches for files with the specified extensions (e.g., .txt) in the given directory and its subdirectories."
  echo "then it generates a report with file details grouped by owner and sorted (ascending) by total size."
  echo ""
  echo "Usage with file filters: script.sh [options] [extension1 extension2 ... ] [directory]"
  echo ""
  echo "  Options:"
  echo "    -h: Display this help section"
  echo "    -s <size>: Filter files by size (in bytes)"
  echo "    -p <permissions>: Filter files by permissions (in octal format)"
  echo "    -t <timestamp>: Filter files by last modified timestamp after the specified date in (YYYY-MM-DD) format"
  echo "    -r: Generate a summary report in a seperate file"
}

addFilters() {
  local filters=()

	if [ -n "$sizeFilter" ]; then
	  filters+=("-size $sizeFilter")
	fi

	if [ -n "$permissionsFilter" ]; then
    	  filters+=("-perm $permissionsFilter")
  	fi

  	if [ -n "$timestampFilter" ]; then
    	  filters+=("-newermt $timestampFilter")
  	fi

  echo "${filters[*]}"
}

while getopts ":s:p:t:hr" opt; do
  case $opt in
	s ) sizeFilter=$OPTARG ;;
	p ) permissionsFilter=$OPTARG ;;
	t ) timestampFilter=$OPTARG ;;
	r ) summaryReport=true ;;
	h ) displayHelp
	  exit 0 ;;
	: ) echo "Option requires an argument." 
	  displayHelp
	  exit 1 ;;
	* ) echo "Invalid option"
          displayHelp
	  exit 1 ;;
  esac
done

shift $((OPTIND-1))

if [ "$#" -lt 2 ]; then
  echo "Error: Invalid number of arguments."
  displayHelp
  exit 1
fi

extensions=("${@:1:$#-1}")
directory="${@:$#}"

if [ ! -d "$directory" ]; then
	echo "Error: make sure to enter a valid directory."
	displayHelp
	exit 1
fi

reportFile="file_analysis.txt"
rm -f "$reportFile"

filters=$(addFilters)

echo "Searching for files with extensions '${extensions[*]}' in '$directory'..."

for extension in "${extensions[@]}"; do
	find "$directory" -type f -name "*.$extension" $filters -exec stat -c "%s %U %a %y %n" {} + >> "$reportFile"
done

sort -k2,2 -k1,1n  -o "$reportFile" "$reportFile"

echo "The report has been saved to: $reportFile"

if [ "$summaryReport" = true ]; then
	summaryReportFile="summary_report.txt"
  	rm -f "$summaryReportFile"
  	totalFiles=$(wc -l < "$reportFile")
  	totalSize=$(awk '{sum+=$1} END {print sum}' "$reportFile")
  	averageSize=$(awk '{sum+=$1} END {print sum/NR}' "$reportFile")
  	largestFile=$(awk '{if ($1 > max) max=$1} END {print max}' "$reportFile")
  	smallestFile=$(awk 'NR==1 { min = $1 } $1 < min { min = $1 } END { print min }' "$reportFile")
  	mostRecentEditedFile=$(awk '{print $4, $5}' "$reportFile" | sort -r | head -n 1)
  	userFileSize=$(awk '{sum[$2]+=$1} END {for (i in sum) print i, sum[i]}' "$reportFile")

  	echo "" >> "$reportFile"
  	echo "Total number of files: $totalFiles" >> "$summaryReportFile"
  	echo "Total file size: $totalSize bytes" >> "$summaryReportFile"
  	echo "Average file size: $averageSize bytes" >> "$summaryReportFile"
  	echo "Largest file size: $largestFile bytes" >> "$summaryReportFile"
  	echo "Smallest file size: $smallestFile bytes" >> "$summaryReportFile"
  	echo "Most recent edit on file: $mostRecentEditedFile" >> "$summaryReportFile"
  	echo "users has files of total size: "  >> "$summaryReportFile"
  	echo "$userFileSize" >> "$summaryReportFile"
	echo "summary_report has been saved to: $summaryReportFile"
fi



