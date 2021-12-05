#!/bin/bash

ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
echo $ver
echo ${ver:0:1}
