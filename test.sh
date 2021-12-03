#!/bin/bash


API_HEIGHT2==$(\
        curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json" )

#API_HEIGHT=${API_HEIGHT2:92:6}
echo ${API_HEIGHT2}[2]

#for i in * ; do mv -- "$i" "${i:0:5}" ; done
