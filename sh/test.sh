#!/bin/bash

API_HEIGHT2==$(\
                curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )
API_HEIGHT=${API_HEIGHT2:92:6}
echo "API_HEIGHT:$API_HEIGHT"
#${API_HEIGHT:1:1}
if [ -n "$API_HEIGHT2" ] && [ "$API_HEIGHT2" -eq "$API_HEIGHT2" ] 2>/dev/null; then
    echo "API_HEIGHT2:$API_HEIGHT2"
    
    echo "API_HEIGHT:$API_HEIGHT2"
    if [ -n "$HEADERS_HEIGHT" ] && [ "$HEADERS_HEIGHT" -eq "$HEADERS_HEIGHT" ] 2>/dev/null; then
    
        echo "header:$HEADERS_HEIGHT"
        let expr PERCENT_HEADERS=$(( ( ($API_HEIGHT - $HEADERS_HEIGHT) * 100) / $API_HEIGHT   )) 
        
    fi

    if [ -n "$HEIGHT" ] && [ "$HEIGHT" -eq "$HEIGHT" ] 2>/dev/null; then


            let expr PERCENT_BLOCKS=$(( ( ($API_HEIGHT - $HEIGHT) * 100) / $API_HEIGHT   ))
            echo "HEIGHT:$HEIGHT"

    fi

fi
