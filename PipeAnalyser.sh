#!/bin/bash
# Author           : Adrian Misiak (s171600@student.pg.edu.pl)
# Created On       : 29.04.2018
# Last Modified By : Adrian Misiak
# Last Modified On : data
# Version          : 1.0.1
#
# Description      :
# Simple testing and statistic gathering script for piped commands;
#-t; 				shows time statistic
#-a;				shows all output
#-c;	<--TODO			shows step at wchich nothing is outputted
#-h NUMBER; shows NUMBER of lines of output
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

FLAG_TIME=0
FLAG_ALL=0
FLAG_CONTINUITY=0
STR_TO_PARSE=""
HOW_MUCH_TO_SHOW=5

printOutput(){
	if (( $FLAG_ALL == 1 )); then
		cat $TEMP_OUTPUT | more
	else
		cat $TEMP_OUTPUT | head -n $HOW_MUCH_TO_SHOW
	fi
	NUM_OF_LINES=$(wc -l < $TEMP_OUTPUT)
	echo Outputted ${NUM_OF_LINES} lines of data
}


while getopts tach: OPT; do
	case $OPT in
		t) FLAG_TIME=1;;
		a) FLAG_ALL=1;;
		c) FLAG_CONTINUITY=1;;
		h) HOW_MUCH_TO_SHOW=$OPTARG
	esac
done


echo Type the statement to test:
read STR_TO_PARSE
TEMP_OUTPUT=$(mktemp)

#Transforms the string intro array.
IFS=' ' read -r -a STR_TO_PARSE <<< "$STR_TO_PARSE"

echo  STATEMENT TO TEST: "${STR_TO_PARSE[@]}"
echo "Press any key to continue."
read -n 1
clear
ARRAY=()
INDEX=0

#Building commands from single words.
for part in "${STR_TO_PARSE[@]}"; do
	case $part in
	"|")
	((INDEX++))
	ARRAY[$INDEX]=$part
	((INDEX++))
	;;
	*)
	ARRAY[$INDEX]+=" "$part
	;;
	esac
done


${ARRAY[0]} > $TEMP_OUTPUT || exit 1
INDEX=1

#Sample command for testing
#tree /home | grep -o '[a-z,A-Z].*\..*' | sort | uniq -c | sort -nr

while [ $INDEX -lt ${#ARRAY[@]} ]; do
	echo -e "$(tput bold)$INDEX.)$(tput sgr0) TO EXECUTE: $(tput smul)${ARRAY[$INDEX]} ${ARRAY[($INDEX+1)]} $(tput rmul)"
	echo -e "$(tput bold && tput setaf 1)BEFORE EXECUTION OF: ${ARRAY[$INDEX]} ${ARRAY[($INDEX+1)]}$(tput sgr0)"
	if [[ $FLAG_ALL == 1 ]]; then
		echo Press any key to continue...
		read -n 1
	fi

	printOutput

	NEXT_STEP="cat $TEMP_OUTPUT ${ARRAY[$INDEX]} ${ARRAY[($INDEX+1)]}"

	#Command is processed here
	TIME_ELAPSED="$(date +%s%N)"
	RES=$(eval $NEXT_STEP || exit 1)
	TIME_ELAPSED="$(($(date +%s%N)-TIME_ELAPSED))"

	#Result of evaluation is stored in temporary file.
	echo -e "$RES" > $TEMP_OUTPUT
	echo -e '\n'

	echo -e "$(tput bold && tput setaf 2)AFTER EXECUTION OF: ${ARRAY[$INDEX]} ${ARRAY[($INDEX+1)]}$(tput sgr0)"
	if [[ $FLAG_ALL == 1 ]]; then
		echo Press any key to continue...
		read -n 1
	fi

	printOutput

	if (( FLAG_TIME == 1 )); then
		echo -e "\nTime of execution: $((TIME_ELAPSED/1000000)) miliseconds"
	fi

	echo -e "\nPress any key to go the next step."
	read -n 1
	INDEX=$((INDEX+2))
	clear
done

rm  $TEMP_OUTPUT
