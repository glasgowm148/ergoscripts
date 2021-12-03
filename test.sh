#!/bin/bash

if [ -z $JVM_HEAP_SIZE ]; then
    read -p "
    #### How many GB of memory should we give the node? ####   

    This must be less than your total RAM size. 

    Recommended: 
    - 1 for Raspberry Pi
    - 2-3 for laptops

    " JVM_HEAP
    export JVM_HEAP_SIZE="-Xmx${JVM_HEAP}g"
    echo "$JVM_HEAP_SIZE"
    echo "$JVM_HEAP_SIZE" > my.conf
    
    name=$(cat "my.conf")
    echo "name:" $name
fi 
