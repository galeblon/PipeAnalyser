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
#-c;			shows step at wchich nothing is outputted
#-h NUMBER; shows NUMBER of lines of output at each step
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

FLAG_TIME=0
FLAG_ALL=0
FLAG_CONTINUITY=0
STR_TO_PARSE=""
HOW_MUCH_TO_SHOW=5

printOutput(){
	if [[ "$FLAG_CONTINUITY" == 1 ]]; then
		return
	fi
	if [[ "$FLAG_ALL" == 1 ]]; then
		cat $TEMP_OUTPUT | more
	else
		cat $TEMP_OUTPUT | head -n $HOW_MUCH_TO_SHOW
	fi
	NUM_OF_LINES=$(wc -l < $TEMP_OUTPUT)
	echo -e "\n"Outputted ${NUM_OF_LINES} lines of data
}

printFirstHeader(){
	if [[ "$FLAG_CONTINUITY" == 1 ]]; then
		return
	fi
	clear
	echo -e "$(tput bold)$1.)$(tput sgr0) TO EXECUTE: $(tput smul)${LIST_OF_STEPS[$1]} $(tput rmul)"
}

printHeader(){
	if [[ "$FLAG_CONTINUITY" == 1 ]]; then
		return
	fi
	clear
	echo -e "$(tput bold)$1.)$(tput sgr0) TO EXECUTE: $(tput smul)${LIST_OF_STEPS[$1]} ${LIST_OF_STEPS[($1+1)]} $(tput rmul)"
	echo -e "$(tput bold && tput setaf 1)BEFORE EXECUTION OF: ${LIST_OF_STEPS[$1]} ${LIST_OF_STEPS[($1+1)]}$(tput sgr0)"
}

printPostHeader(){
	if [[ "$FLAG_CONTINUITY" == 1 ]]; then
		return
	fi
	if (( $1 == 0 )); then
		echo -e "$(tput bold && tput setaf 2)AFTER EXECUTION OF: ${LIST_OF_STEPS[$1]}$(tput sgr0)"
	else
		echo -e "$(tput bold && tput setaf 2)AFTER EXECUTION OF: ${LIST_OF_STEPS[$1]} ${LIST_OF_STEPS[($1+1)]}$(tput sgr0)"
	fi
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

#echo  STATEMENT TO TEST: "${STR_TO_PARSE[@]}"

if [[ $FLAG_CONTINUITY == 0 ]]; then
	echo "Press any key to continue."
	read -n 1
fi

LIST_OF_STEPS=()
INDEX=0

#Building commands from single words.
for part in "${STR_TO_PARSE[@]}"; do
	case $part in
	"|")
	((INDEX++))
	LIST_OF_STEPS[$INDEX]=$part
	((INDEX++))
	;;
	*)
	LIST_OF_STEPS[$INDEX]+=" "$part
	;;
	esac
done


#${LIST_OF_STEPS[0]} > $TEMP_OUTPUT || exit 1
INDEX=0

#Sample command for testing
#tree /home | grep -o '[a-z,A-Z].*\..*' | sort | uniq -c | sort -nr

PREV_LINES=0
PREV_CHARACTERS=0
CURR_LINES=0
CURR_CHARACTERS=0

while [ $INDEX -lt ${#LIST_OF_STEPS[@]} ]; do
	if [[ $INDEX != 0 ]]; then
		printHeader $INDEX
		if [[ "$FLAG_ALL" == 1 && "$FLAG_CONTINUITY" == 0 ]]; then
			echo Press any key to continue...
			read -n 1
		fi
		printOutput
		NEXT_STEP="cat $TEMP_OUTPUT ${LIST_OF_STEPS[$INDEX]} ${LIST_OF_STEPS[($INDEX+1)]}"
	else
		printFirstHeader $INDEX
		NEXT_STEP="${LIST_OF_STEPS[$INDEX]}"
	fi

	#Command is processed here.
	TIME_ELAPSED="$(date +%s%N)"
	RES=$(eval $NEXT_STEP || exit 1)
	TIME_ELAPSED="$(($(date +%s%N)-TIME_ELAPSED))"

	#Result of evaluation is stored in temporary file.
	echo -e "$RES" > $TEMP_OUTPUT
	if [[ -z "$RES"  && "$FLAG_CONTINUITY" == 1 ]]; then
		echo -e "Output was null after step: $(tput bold)${LIST_OF_STEPS[$INDEX+1]}$(tput sgr0)"
		rm  $TEMP_OUTPUT
		exit
	fi

	CURR_LINES=$(wc -l < $TEMP_OUTPUT)
	CURR_CHARACTERS=$(wc -c < $TEMP_OUTPUT)
	DELTA_LINES=$((CURR_LINES-PREV_LINES))
	DELTA_CHARACTERS=$((CURR_CHARACTERS-PREV_CHARACTERS))
	if [[ $PREV_LINES != 0 && "$FLAG_CONTINUITY" == 0 ]]; then
		echo -ne "\nDelta lines: "
		if [[ "$DELTA_LINES" -gt 0 ]]; then
			echo -ne "$(tput bold && tput setaf 2)+"
			echo $DELTA_LINES
		elif [[ "$DELTA_LINES" -lt 0 ]]; then
			echo -ne "$(tput bold && tput setaf 1)"
		fi
		echo -ne "$(($DELTA_LINES*100/$PREV_LINES))$(tput sgr0)%\t\t"
		echo -n "Delta characters: "
		if [[ "$DELTA_CHARACTERS" -gt 0 ]]; then
			echo -ne "$(tput bold && tput setaf 2)+"
			echo $DELTA_CHARACTERS
		elif [[ "$DELTA_CHARACTERS" -lt 0 ]]; then
			echo -ne "$(tput bold && tput setaf 1)"
		fi
		echo -ne "$(($DELTA_CHARACTERS*100/$PREV_CHARACTERS))$(tput sgr0)%\n\n"
	fi
	PREV_LINES=$CURR_LINES
	PREV_CHARACTERS=$CURR_CHARACTERS

	printPostHeader $INDEX

	#echo Linie: $PREV_LINES
	#echo Znaki: $PREV_CHARACTERS

	if [[ "$FLAG_ALL" == 1 && "$FLAG_CONTINUITY" == 0 ]]; then
		echo Press any key to continue...
		read -n 1
	fi
	printOutput

	if [[ "$FLAG_TIME" = 1 && "$FLAG_CONTINUITY" == 0 ]]; then
		echo -e "\nTime of execution: $((TIME_ELAPSED/1000000)) miliseconds"
	fi

	if [[ $FLAG_CONTINUITY == 0 ]]; then
		echo -e "\nPress any key to go the next step."
		read -n 1
	fi

	if [[ $INDEX != 0 ]]; then
		INDEX=$((INDEX+2))
	else
		INDEX=$((INDEX+1))
	fi
done

if [[ $FLAG_CONTINUITY == 1 ]]; then
	echo -e "Output is never empty."
fi

rm  $TEMP_OUTPUT
