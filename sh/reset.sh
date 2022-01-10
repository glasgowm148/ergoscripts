#!/bin/bash


echo "shutdown"
curl -X POST "http://127.0.0.1:9053/node/shutdown" -H "api_key: hello"

cd ergo_node

echo "Booting..."

sleep 120
#pkill -9 java
#killall -9 java
#kill -9 $(lsof -t -i:9053)
#kill -9 $(lsof -t -i:9030)

java -jar  ergo.jar --mainnet -c ergo.conf > reset.log 2>&1 & 
