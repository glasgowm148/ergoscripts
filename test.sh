#!/bin/bash

while sleep 1
    do
    LINE=$(tail -n 1 height.log)
    LINE1=${LINE:30:6}
    echo "LINE1:" $LINE1

    LINE_2=$(tail -n 1 height.log)
    LINE2=${LINE2:30:6}
    echo "LINE2:" $LINE2

    if [ $LINE -ne $LINE2 ]; then
        echo true
        else
        false
    fi
done