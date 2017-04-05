#!/usr/bin/env bash

minX=0
minY=0
maxX=200
maxY=300
nbPoints=8

echo "["

for (( i=1; i<=$nbPoints; i++ ))
do
    x=$[($RANDOM % ($[$maxX - $minX] + 1)) + $minX]
    y=$[($RANDOM % ($[$maxY - $minY] + 1)) + $minY]
    echo "[$x, $y]"

    if [ "$i" -lt "$nbPoints" ]
    then
        echo ","
    fi
done

echo "]"
