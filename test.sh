#!/bin/bash
read -p "- How many GB of ram should we set the JVM heap size to? (Recommended: 1 for Pi, 2-3 for laptops): " JVM_HEAP


export JVM_HEAP_SIZE="-Xmx${JVM_HEAP}G"
echo $JVM_HEAP_SIZE