#!/bin/bash

# Shell script for installing Ergo Node under Unix.
# markglasgow@gmail.com - 29 November
# -------------------------------------------------------------------------
# Run this with
# bash -c "$(curl -s https://node.phenotype.dev)"


kill -9 $(lsof -t -i:9053)
#rm -rf .ergo/wallet
#rm -rf .ergo/state
# knownPeers: https://github.com/ergoplatform/ergo/blob/246ac2918028462a07dff19ea1ca35e4e15bb5e0/src/main/resources/mainnet.conf#L43

###########################################################################           
### Download the latest .jar file                                                                    
###########################################################################
if [ -e *.jar ]; then 
    echo "- Node .jar is already downloaded"
else
    echo "- Retrieving latest node release.."
    LATEST_ERGO_RELEASE=$(curl -s "https://api.github.com/repos/ergoplatform/ergo/releases/latest" | awk -F '"' '/tag_name/{print $4}')
    LATEST_ERGO_RELEASE_NUMBERS=$(echo ${LATEST_ERGO_RELEASE} | cut -c 2-)
    ERGO_DOWNLOAD_URL=https://github.com/ergoplatform/ergo/releases/download/${LATEST_ERGO_RELEASE}/ergo-${LATEST_ERGO_RELEASE_NUMBERS}.jar
    echo "- Downloading Latest known Ergo release: ${LATEST_ERGO_RELEASE}."
    curl --silent -L ${ERGO_DOWNLOAD_URL} --output ergo.jar
fi 
kill $pid > /dev/null 2>&1


###########################################################################           
### Prompt the user for a password and hash it using Blake2b                                                                    
###########################################################################
read -p "- Please create a password. This will be used to unlock your API: " input
export RAND=$(curl -s --location -g --request GET 'api.hashify.net/hash/BLAKE2B-256/hex?value='$input)
export blake_hash=${RAND[@]:10:66}       
if [ -z ${blake_hash+x} ]; then echo "blake_hash is unset"; fi
read -p "- How many GB of ram should we set the JVM heap size to? (Recommended: 1 for Pi, 2-3 for laptops): " JVM_HEAP

###########################################################################           
### Write the config file with the generated hash                                                                    
###########################################################################
echo "
ergo {
        node {
            # Full options available at 
            # https://github.com/ergoplatform/ergo/blob/master/src/main/resources/application.conf
            
            mining = false
            
            skipV1TransactionsValidation = true
            
            blocksToKeep = 0

            }
        network {

            penaltySafeInterval = 1m
            penaltyScoreThreshold = 10
            maxDeliveryChecks = 4
        }
    }
scorex {
    restApi {
        # Hex-encoded Blake2b256 hash of an API key. 
        # Should be 64-chars long Base16 string.
        # below is the hash of the string 'hello'
        # replace with your actual hash 
        apiKeyHash = "$blake_hash"
    }
}" > ergo.conf


###########################################################################           
### Run the server, the -Xmx3G flag specifies the JVM Heap size
### Change this depending on system specs.                                                        
###########################################################################

export JVM_HEAP_SIZE="-Xmx${JVM_HEAP}g"
#-Djava.util.logging.config.file=logging.properties
java -jar   $JVM_HEAP_SIZE ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 

echo "- Waiting for a response from the server - If this is taking too long check server.log"
while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n '.'; done;  # wait for node be ready with progress bar


###########################################################################           
### This should open the browser (providing python is installed)
### At this stage you can check if your API key works as prompted.                                                        
###########################################################################
python -mwebbrowser http://127.0.0.1:9053/panel 


###########################################################################           
### This method pulls the latest height and header height from /info
###########################################################################
get_heights(){
    
    API_HEIGHT==$(\
        curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" \
        | python -c "import sys, json; print json.load(sys.stdin)['height']"\
    )
    let API_HEIGHT=${API_HEIGHT#?}
    
    #echo "Target height retrieved from API: $API_HEIGHT"

    HEADERS_HEIGHT=$(\
        curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
        | python -c "import sys, json; print json.load(sys.stdin)['headersHeight']"\
    )
    #echo "Current header height: $HEADERS_HEIGHT"

    HEIGHT=$(\
    curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
    | python -c "import sys, json; print json.load(sys.stdin)['parameters']['height']"\
    
    )
    
    FULL_HEIGHT=$(\
    curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
    | python -c "import sys, json; print json.load(sys.stdin)['fullHeight']"\
    
    )

    # Set the percentages
    if [ -n $HEADERS_HEIGHT ]; then
       # echo "api: $API_HEIGHT, hh:$HEADERS_HEIGHT"
        let expr PERCENT_HEADERS=$(( ( ($API_HEIGHT - $HEADERS_HEIGHT) * 100) / $API_HEIGHT   ))      
    fi

    if [ $HEIGHT -ne 0 ]; then
        let expr PERCENT_BLOCKS=$(( ( ($API_HEIGHT - $HEIGHT) * 100) / $API_HEIGHT   ))
    fi

    # Compare against the 'fullHeight' JSON component
    if [ -z $FULL_HEIGHT ]; then
        echo "Full height is $FULL_HEIGHT"
        if [$FULL_HEIGHT -ne $API_HEIGHT ]; then
            echo "WARN - Full height and API height do not match!"
            echo "FULL_HEIGHT is $FULL_HEIGHT"
            echo "API_HEIGHT is $API_HEIGHT"
            
        else
            echo "Successfully sync'd!"
        fi
    fi
    
}

###########################################################################           
### Display progress to user
###########################################################################

# Dummy values to start
let PERCENT_BLOCKS=100
let PERCENT_HEADERS=100


while sleep 2
do
    clear
    
    
    printf "%s    \n\n" \
      "Sync Progress;"\
      "- Headers: ~$(( 100 - $PERCENT_HEADERS ))% Complete ($HEADERS_HEIGHT/$API_HEIGHT)"\
      "- Blocks:  ~$(( 100 - $PERCENT_BLOCKS ))% Complete ($HEIGHT/$API_HEIGHT)"\
      "To use the API, enter your password ('$input') on 127.0.0.1:9053/panel under 'Set API key'."\
      "Please follow the next steps on docs.ergoplatform.org to initialise your wallet."  
    echo ""
    echo "server.log tail"
    tail -n 10 server.log 

    get_heights
    
done

