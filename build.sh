#!/bin/bash

files=( \
  lib/jquery.ba-throttle-debounce.min.js \
  src/coffee/yam.js \
)

baseDir=`dirname $0`

counter=0
while [ $counter -lt ${#files[@]} ]; do
  files[$counter]="$baseDir/${files[$counter]}"
  let counter=counter+1
done

combined=build/yam.js
minified=build/yam.min.js

if [ -a $minified ]
  then
    rm $minified
fi

cat ${files[*]} >> $combined
uglifyjs $combined >> $minified