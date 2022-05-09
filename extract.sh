#!/bin/bash

while getopts ":i:t:o:v:" opt
do
  case $opt in
    i)
	inputFiles=($OPTARG)
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    t)
	tFile="$OPTARG"
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    o)
  	oFile="$OPTARG"
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    v)
  	vFile="$OPTARG"
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    \? ) 
	  echo "Unknown option: -$OPTARG" >&2
	  exit 1
	    ;;
    :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [[ ${#inputFiles[@]} == 0 ]]
then
      echo "No input file is specified!" >&2
      exit 1
fi

for file in ${inputFiles[@]}
do
  if [[ ! -f "$file" ]]
  then
  	echo "Input file $file does not exist!" >&2
  	exit 1;
  fi
done

if [[ "$tFile" == "" ]]
then
  touch "e.csv" #default tFile
  tFile="e.csv"
else
  touch "$tFile"
fi

if [[ "$oFile" == "" ]]
then
  touch "d.csv" #default oFile
  oFile="d.csv"
else
  touch "$oFile"
fi

if [[ "$vFile" == "" ]]
then
  touch "f.csv" #default vFile
  vFile="f.csv"
else
  touch "$vFile"
fi

: > "$tFile"
: > "$oFile"
: > "$vFile"

Authors=()
for file in ${inputFiles[@]}
do
  { read
    while read -r line
    do
    if [ ! -z "$line" ]
    then
      lineArr=()
      while read -r sliceLine; do
        sliceLine=${sliceLine##+([[:space:]])}
        sliceLine=${sliceLine%%+([[:space:]])}
        lineArr+=( "$sliceLine" )
      done < <( echo $line | sed ':a;s/^\(\("[^"]*"\|[^",]*\)*\),/\1\n/;ta' )

      while read -r sliceLine; do
        Authors+=( "$sliceLine" )
      done < <( echo ${lineArr[1]} | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1\n/;ta' | tr -d '"' | sed 's/^[ \t]*//;s/[ \t]*$//' )

    fi
    done
  } < "$file"
done

authorArr=()
while read -r -d '' eachAuthor
do
    authorArr+=("$eachAuthor")
done < <(printf "%s\0" "${Authors[@]}" | sort -uz)

((j=0))
declare -A authorCode
for i in "${authorArr[@]}"
do
((j++))
authorCode["$i"]=$j
echo "\"$i\",$j" >> "$tFile"
done

declare -A authorCount
declare -A matrix
((k=0))

for file in ${inputFiles[@]}
do
  
  { read
    while read -r line
    do
    if [ ! -z "$line" ]
    then
      lineArr=()
      while read -r sliceLine; do
        sliceLine=${sliceLine##+([[:space:]])}
        sliceLine=${sliceLine%%+([[:space:]])}
        lineArr+=( "$sliceLine" )
      done < <( echo $line | sed ':a;s/^\(\("[^"]*"\|[^",]*\)*\),/\1\n/;ta' )

      Authors=()
      while read -r sliceLine; do
        Authors+=( "$sliceLine" )
      done < <( echo ${lineArr[1]} | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1\n/;ta' | tr -d '"' | sed 's/^[ \t]*//;s/[ \t]*$//' )
      
      authorNums=""
      readarray -t sortedAuths < <(for a in "${Authors[@]}"; do echo "$a"; done | sort)
      for i in "${sortedAuths[@]}"
      do
        authorNums+="${authorCode["$i"]},"
        ((authorCount[${authorCode["$i"]}]+=1))
        for ((j = 1 ; j < ${#sortedAuths[@]} ; j++))
        do
          ((matrix[${authorCode["$i"]},${authorCode["${sortedAuths[$j]}"]}]+=1))
        done
      done

      echo ${lineArr[2]},$authorNums | sed 's/,*$//g' >> "$oFile"

      ((k=k+1))
    fi
    done
  } < "$file"
done

for i in "${authorArr[@]}"
do
  matrix[${authorCode["$i"]},${authorCode["$i"]}]=${authorCount[${authorCode["$i"]}]}
done

for ((j = 1 ; j <= $k ; j++))
do 
  for ((m = 1 ; m <= $k ; m++))
  do

    matrix[$m,$j]=${matrix[$j,$m]}

  done
done

echo -n " ," >> "$vFile"
for ((j = 1 ; j <= $k ; j++))
do
if [[ $j -ne 6 ]]
then
  echo -n "$j," >> "$vFile"
else
  echo -n "$j" >> "$vFile"
fi

done
echo "" >> "$vFile"

for ((j = 1 ; j <= $k ; j++))
do

  for ((m = 1 ; m <= $k ; m++))
  do
  if [[ $m -ne 6 ]]
  then
    if [[ $m -eq 1 ]]
    then
      if [[ ${matrix[$j,$m]} == "" ]]
      then
        echo -n "$j,0," >> "$vFile"
      else
        echo -n "$j,${matrix[$j,$m]}," >> "$vFile"
      fi
    else
      if [[ ${matrix[$j,$m]} == "" ]]
      then
        echo -n "0," >> "$vFile"
      else
        echo -n "${matrix[$j,$m]}," >> "$vFile"
      fi
    fi
  else
    if [[ ${matrix[$j,$m]} == "" ]]
    then
      echo -n "0" >> "$vFile"
    else
      echo -n "${matrix[$j,$m]}" >> "$vFile"
    fi
  fi

  done
  echo "" >> "$vFile"
done
