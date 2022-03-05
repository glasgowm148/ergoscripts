#!/bin/bash


export API_KEY="dummy"
export BLAKE_HASH="unset"

#OS=$(uname -m)

## Create directory
[ -d ergo ] || mkdir ergo && cd ergo

## Initial Minimal Config
echo "
    ergo {
        node {
            mining = false
        }

    }" > ergo.conf
        

## Download .jar
echo "- Retrieving latest node release.."
LATEST_ERGO_RELEASE=$(curl -s "https://api.github.com/repos/ergoplatform/ergo/releases/latest" | awk -F '"' '/tag_name/{print $4}')
LATEST_ERGO_RELEASE_NUMBERS=$(echo ${LATEST_ERGO_RELEASE} | cut -c 2-)
ERGO_DOWNLOAD_URL=https://github.com/ergoplatform/ergo/releases/download/${LATEST_ERGO_RELEASE}/ergo-${LATEST_ERGO_RELEASE_NUMBERS}.jar
echo "- Downloading Latest known Ergo release: ${LATEST_ERGO_RELEASE}."
curl --silent -L ${ERGO_DOWNLOAD_URL} --output ergo.jar

## Start the node.
java -jar -Xmx3G ergo.jar --mainnet -c ergo.conf > server.log 2>&1 &
echo "#### Waiting for a response from the server. ####"
while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n '.';  done;  # wait for node be ready with progress bar

## Set API key
read -p "
#### Please create a password. #### 

This will be used to unlock your API. 

Generally using the same API key through the entire sync process can prevent 'Bad API Key' errors:

" input


## Start node and get Blake2b hash of the API
java -jar -Xmx3G ergo.jar --mainnet -c ergo.conf > server.log 2>&1 &
export BLAKE_HASH=$(curl --silent -X POST "http://localhost:9053/utils/hash/blake2b" -H "accept: application/json" -H "Content-Type: application/json" -d "\"$input\"")


## Kill
#curl -X POST --max-time 10 "http://127.0.0.1:9053/node/shutdown" -H "api_key: $API_KEY"
kill -9 $(lsof -t -i:9053) 2>/dev/null
kill -9 $(lsof -t -i:9030) 2>/dev/null
killall -9 java 2>/dev/null


echo "
    ergo {
        node {
            mining = false
        }

    }
        
    scorex {
        restApi {
            apiKeyHash = "$BLAKE_HASH"
            
        }
    }" > ergo.conf


echo "API key set to" $input "and the node is now syncing"
echo "Starting the node..."
echo "Monitor the .log files for any errors"
echo "Please visit https://127.0.0.0.9053/info to track the status." 

## Start node
java -jar -Xmx4G -Dlogback.stdout.level=WARN -Dlogback.file.level=ERR ergo.jar --mainnet -c ergo.conf > output.log

