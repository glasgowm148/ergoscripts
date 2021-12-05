#!/bin/bash

memory=15
echo "memory !!-- " $memory
half_mem=$((memory / 2))
echo "half_mem !!-- " $half_mem
JVM_HEAP_SIZE="-Xmx${half_mem}g"
echo "JVM_HEAP_SIZE !!-- " $JVM_HEAP_SIZE
