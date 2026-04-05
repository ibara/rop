#!/bin/sh

rm -f out.txt

total=$1

if [ -z $total ] ; then
  total=100
fi

i=0

while [ $i -lt $total ] ; do
  (/usr/bin/time -p ./opt sqlite3.s > /dev/null) 2>> out.txt
  i=$((i+1))
done

./timing out.txt $total | tee stats

rm -f timing out.txt
