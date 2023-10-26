#!/bin/bash

#if [ "x$1" = "x" ] then; maxbreite=11; else maxbreite=$1; fi
len=$(cat statistic.log | jq '.request' | wc -l) 
lines=`tput lines`
cols=`tput cols`
pages=`expr $len / $cols`

#if [ "x$1" = "x" ]; then b=100; else b=$1; fi
#if [ "$b" -lt "$cols" ]; then b=$cols; fi
#b=$(cat statistic.log | tr -d ' \n' | sed -e 's/}{/}\n{/g' | wc -l)
#[ "$a" != "" ] b=$a
echo -n "Page [1-$pages]:"
read a
b=$(expr $a \* $cols)
#echo "a: $a # len : $len # b :$b"
#exit
# Initialisierung
#breite=1; offset=`expr $maxbreite / 2 + 1`; maxoffset=$offset

# breiter werdender Baum, funktioniert nur fuer ungerade Maximalbreiten,
# sonst Maximalbreite falsch

#while [ $breite -le $maxbreite ] do
#  printf "%${offset}s" " "; echo '\t' | expand -t $breite | sed 's/ /*/g'
#  breite=`expr $breite + 2`; offset=`expr $offset - 1`
#done

# Stamm
#printf "%${maxoffset}s*\n" " "; printf "%${maxoffset}s*\n" " "

read max min <<< $(cat statistic.log | jq '.requests' | head -n $b | tail -n `expr $cols - 10`  | awk -v ma=0 -v mi=1000000  'ma<$1 {ma=$1} mi>$1 {mi=$1} END {print ma,mi}')
s=$(cat statistic.log | jq '(.requests | tostring) + "," + (.timestamp | split("T")[1] )' | head -n $b | tail -n `expr $cols - 10` | tr -d '"' | tr '\n' ' ')

step=$(expr $max - $min)
step=$(expr $step / $lines + 1)
col=10
clear
#echo $min $max $lines $step
for p in $s
do
  i=$(echo $p | cut -d, -f1)
  t=$(echo $p | cut -d, -f2)
  row=$(expr $i - $min)
  row=`expr $row / $step`
  row=`expr $lines - $row`
  tput cup $row 0
  echo -n $i
  tput cup $row $col
  echo -n "*"
  tput cup `expr $lines - 2` $col
  echo -n "+"
  if [ `expr $col % 15` -eq 0 ]
  then
    tput cup $lines $col
    echo -n "|$t"
  fi

  #tput cup $lines  $col
  #echo -n "+"
  #echo "$col, $row :($i) =>  $lines - ($i - $min) / $step"
  col=`expr $col + 1`
done
read -n 1 -s a
echo


