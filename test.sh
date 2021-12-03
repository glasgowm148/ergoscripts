#!/bin/bash

API_HEIGHT==$(\
        curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" \
        | python -c "import sys, json; print json.load(sys.stdin)['height']"\
    )

API_HEIGHT2==$(\
        curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )

#API_HEIGHT2=${API_HEIGHT2#?}

#echo $API_HEIGHT2
echo ""
echo ${API_HEIGHT2:10}

#for i in * ; do mv -- "$i" "${i:0:5}" ; done
