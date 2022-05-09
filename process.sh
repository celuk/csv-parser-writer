#!/bin/bash

while getopts ":s:i:o:" opt
do
  case $opt in
    s)
  	sortArgs=($OPTARG)
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    i)
	  inputFiles=($OPTARG)
    if [[ ${OPTARG:0:1} == '-' ]]; then
      echo "Invalid value $OPTARG given to -$opt!" >&2
      exit 1
    fi
      ;;
    o)
	  outputFile="$OPTARG"
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

if [[ "$outputFile" == "" ]]
then
  touch "out.csv" #default output file
  outputFile="out.csv"
else
  touch "$outputFile"
fi

: > "$outputFile" #clear once then append

echo "Cites,Authors,Title,Year,Source,Publisher,ArticleURL,CitesURL,GSRank,QueryDate,Type,DOI,ISSN,CitationURL,Volume,Issue,StartPage,EndPage,ECC,CitesPerYear,CitesPerAuthor,AuthorCount,Age,Abstract,FullTextURL,RelatedURL,TotalPages" >> "$outputFile"

if [[ ${#sortArgs[@]} == 0 ]] #if user not sorting
then

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

        Cites=${lineArr[0]}

        Year=${lineArr[3]}
        QueryDate="$(echo ${lineArr[9]} | sed 's/ .*//' | tr -d '"-')"
        Age=$((($(date +%s -d $QueryDate)-$(date +%s -d ${Year}0101))/86400))
        
        AuthorCount="$(echo ${lineArr[1]} | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1\n/;ta' | tr -d '"' | sed 's/^[ \t]*//;s/[ \t]*$//' | wc -l)"

        line="${lineArr[0]},${lineArr[1]},${lineArr[2]},${lineArr[3]},${lineArr[4]},${lineArr[5]},${lineArr[6]},${lineArr[7]},${lineArr[8]},${lineArr[9]}\
              ,${lineArr[10]},${lineArr[11]},${lineArr[12]},${lineArr[13]},${lineArr[14]},${lineArr[15]},${lineArr[16]},${lineArr[17]}\
              ,$Cites,$(($Cites*365/$Age)),$(($Cites/$AuthorCount)),$AuthorCount,$Age\
              ,${lineArr[23]},${lineArr[24]},${lineArr[25]}"
        line+=","
        if [[ ! -z "${lineArr[16]// }" && ! -z "${lineArr[17]// }" ]]
        then
          line+="$((${lineArr[17]// } - ${lineArr[16]// } + 1))"
        fi
        echo $line | sed ':a;s/^\(\("[^"]*"\|[^"[[:space:]]]*\)*\)[[:space:]]/\1/;ta' | sed ':a;s/^\(\("[^"]*"\|[^",]*\)*\),/\1|/;ta' >> "$outputFile"
      fi
      done
    } < "$file"
  done

  echo "$(head -n1 "$outputFile" && tail -n+2 "$outputFile" | sed ':a;s/^\(\("[^"]*"\|[^"|]*\)*\)|/\1,/;ta')" > "$outputFile"

else

  sortCmd="sort -t '|' -s "
  for sortArg in ${sortArgs[@]}
  do

    if [[ "$sortArg" != "Cites" 
       && "$sortArg" != "Authors" && "$sortArg" != "Title" && "$sortArg" != "Year" 
       && "$sortArg" != "Source" && "$sortArg" != "Publisher" && "$sortArg" != "ArticleURL" 
       && "$sortArg" != "CitesURL" && "$sortArg" != "GSRank" && "$sortArg" != "QueryDate" 
       && "$sortArg" != "Type" && "$sortArg" != "DOI" && "$sortArg" != "ISSN" 
       && "$sortArg" != "CitationURL" && "$sortArg" != "Volume" && "$sortArg" != "Issue" 
       && "$sortArg" != "StartPage" && "$sortArg" != "EndPage" && "$sortArg" != "Abstract" 
       && "$sortArg" != "FullTextURL" && "$sortArg" != "RelatedURL" && "$sortArg" != "TotalPages" ]]
    then
      echo "$sortArg is not a valid sort field!" >&2
      exit 1
    fi

    if [[ $sortArg == "Cites" ]]
    then
    sortCmd+="-k1,1n "
    fi
    if [[ $sortArg == "Authors" ]]
    then
    sortCmd+="-k2,2 "
    fi
    if [[ $sortArg == "Title" ]]
    then
      sortCmd+="-k3,3 "
    fi
    if [[ $sortArg == "Year" ]]
    then
      sortCmd+="-k4,4n "
    fi
    if [[ $sortArg == "Source" ]]
    then
      sortCmd+="-k5,5 "
    fi
    if [[ $sortArg == "Publisher" ]]
    then
      sortCmd+="-k6,6 "
    fi
    if [[ $sortArg == "ArticleURL" ]]
    then
      sortCmd+="-k7,7 "
    fi
    if [[ $sortArg == "CitesURL" ]]
    then
      sortCmd+="-k8,8 "
    fi
    if [[ $sortArg == "GSRank" ]]
    then
      sortCmd+="-k9,9n "
    fi
    if [[ $sortArg == "QueryDate" ]]
    then
      sortCmd+="-k10,10 "
    fi
    if [[ $sortArg == "Type" ]]
    then
      sortCmd+="-k11,11 "
    fi
    if [[ $sortArg == "DOI" ]]
    then
      sortCmd+="-k12,12 "
    fi
    if [[ $sortArg == "ISSN" ]]
    then
      sortCmd+="-k13,13 "
    fi
    if [[ $sortArg == "CitationURL" ]]
    then
      sortCmd+="-k14,14 "
    fi
    if [[ $sortArg == "Volume" ]]
    then
      sortCmd+="-k15,15n "
    fi
    if [[ $sortArg == "Issue" ]]
    then
      sortCmd+="-k16,16n "
    fi
    if [[ $sortArg == "StartPage" ]]
    then
      sortCmd+="-k17,17n "
    fi
    if [[ $sortArg == "EndPage" ]]
    then
      sortCmd+="-k18,18n "
    fi
    if [[ $sortArg == "Abstract" ]]
    then
      sortCmd+="-k24,24 "
    fi
    if [[ $sortArg == "FullTextURL" ]]
    then
      sortCmd+="-k25,25 "
    fi
    if [[ $sortArg == "RelatedURL" ]]
    then
      sortCmd+="-k26,26 "
    fi
    if [[ $sortArg == "TotalPages" ]]
    then
      sortCmd+="-k27,27n "
    fi

  done

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

        Cites=${lineArr[0]}

        Year=${lineArr[3]}
        QueryDate="$(echo ${lineArr[9]} | sed 's/ .*//' | tr -d '"-')"
        Age=$((($(date +%s -d $QueryDate)-$(date +%s -d ${Year}0101))/86400))
        
        AuthorCount="$(echo ${lineArr[1]} | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1\n/;ta' | tr -d '"' | sed 's/^[ \t]*//;s/[ \t]*$//' | wc -l)"

        line="${lineArr[0]},${lineArr[1]},${lineArr[2]},${lineArr[3]},${lineArr[4]},${lineArr[5]},${lineArr[6]},${lineArr[7]},${lineArr[8]},${lineArr[9]}\
              ,${lineArr[10]},${lineArr[11]},${lineArr[12]},${lineArr[13]},${lineArr[14]},${lineArr[15]},${lineArr[16]},${lineArr[17]}\
              ,$Cites,$(($Cites*365/$Age)),$(($Cites/$AuthorCount)),$AuthorCount,$Age\
              ,${lineArr[23]},${lineArr[24]},${lineArr[25]}"
        line+=","
        if [[ ! -z "${lineArr[16]// }" && ! -z "${lineArr[17]// }" ]]
        then
          line+="$((${lineArr[17]// } - ${lineArr[16]// } + 1))"
        fi
        echo $line | sed ':a;s/^\(\("[^"]*"\|[^"[[:space:]]]*\)*\)[[:space:]]/\1/;ta' | sed ':a;s/^\(\("[^"]*"\|[^",]*\)*\),/\1|/;ta' >> "$outputFile"
      fi
      done
    } < "$file"
  done

  echo "$(head -n1 "$outputFile" && tail -n+2 "$outputFile" | eval "$sortCmd" | sed ':a;s/^\(\("[^"]*"\|[^"|]*\)*\)|/\1,/;ta')" > "$outputFile"
fi
