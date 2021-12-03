#!/bin/bash

count=`ls -1 *.pog 2>/dev/null | wc -l`
if [ $count != 0 ]; then 
echo true
fi 