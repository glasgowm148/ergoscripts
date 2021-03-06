#!/bin/bash

# Shell script for installing Ergo Node on any platform.
# markglasgow@gmail.com - 29 November
# -------------------------------------------------------------------------
# Run this with
# bash -c "$(curl -s https://node.phenotype.dev)"


set_env(){
# Set some variables and check for python/java
# TODO: Win support for java/python
    # Initial variables
    export API_KEY="dummy"
    export BLAKE_HASH="unset"

    #OS=$(uname -m)
    #cd ../ergo_node
    [ -d ergo_node ] || mkdir ergo_node && cd ergo_node
    
    
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    i=0
    let PERCENT_BLOCKS=100
    let PERCENT_HEADERS=100

    # Check for python
    if ! hash python; then
        echo "python is not installed"
        #curl https://pyenv.run | bash
        #echo "Python installed, please re-run"
        #https://github.com/pyenv-win/pyenv-win
        exit 1
    fi
    #pyv="$(python -V 2>&1)"
    #echo "$pyv"
    ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
    #echo $ver
    #echo `java -version 2>&1 | grep 'version' 2>&1 | awk -F\" '{ split($2,a,"."); print a[1]"."a[2]}'`
    jver=`java -version 2>&1 | grep 'version' 2>&1 | awk -F\" '{ split($2,a,"."); print a[1]"."a[2]}'`

    if [[ $jver == "1.8" ]]; then                
        echo $jver is less than java 8
        echo "Please update to the latest version"
        echo "curl -s "https://beta.sdkman.io" | bash"
    else
        echo $jver is java 17
    fi
   
  
    # Set memory
    case "$(uname -s)" in

        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            echo 'MS Windows'
            #WIN_MEM=$(systeminfo)
            WIN_MEM=$(wmic OS get FreePhysicalMemory)
            kb_to_mb=$((memory*1024))
            echo "WIN memory !!-- " $kb_to_mb
            JVM_HEAP_SIZE="-Xmx${kb_to_mb}m"
            ;;

        Linux)
            memory=`awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo` 
            half_mem=$((${memory%.*} / 2))
            JVM_HEAP_SIZE="-Xmx${half_mem}m"
            ;;

        Darwin) #Other
            memory=$(top -l1 | awk '/PhysMem/ {print $2}')
            half_mem=$((${memory%?} / 2))
            JVM_HEAP_SIZE="-Xmx${half_mem}g"            
            ;;

        Other*)
            JVM_HEAP_SIZE="-Xmx2g"
            ;;
    esac

    case "$(uname -m)" in
        armv7l|aarch64)
            memory=`awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo` 
            half_mem=$((${memory%.*} / 3))
            JVM_HEAP_SIZE="-Xmx${half_mem}m"
            echo "JVM_HEAP_SIZE Set to:" $JVM_HEAP_SIZE
            
            echo "Raspberry Pi detected, running node in light-mode" 
            echo "blocksToKeep = 1440 # keep ~2 days of blocks"
            echo "stateType = digest # Note: You cannot validate arbitrary block and generate ADProofs due to this"
            echo "To be able to do this on a Pi please "
            sleep 10
            export blocksToKeep="#blocksToKeep = 1440 # 1440 = ~2days"
            export stateType = "stateType = digest"
            ;;
    esac
    
}

set_conf (){
# Write the config file with the generated hash
# CALLEDBY: first_run
# TODO: Add custom Pi conf ('blockToKeep' / )
echo "
    ergo {
        node {
            # Full options available at 
            # https://github.com/ergoplatform/ergo/blob/master/src/main/resources/application.conf
            
            mining = false
            
            ### there's light regime where the node is not storing UTXO set, and can validate only limited in length suffix of full blocks . Such nodes are running on Raspberry Pi with 0.5 GB given even.
            # Skip validation of transactions in the mainnet before block 417,792 (in v1 blocks).
            # Block 417,792 is checkpointed by the protocol (so its UTXO set as well).
            # The node still applying transactions to UTXO set and so checks UTXO set digests for each block.
            skipV1TransactionsValidation = true
            
            # Number of last blocks to keep with transactions and ADproofs, for all other blocks only header will be stored.
            # Keep all blocks from genesis if negative
            # download and keep only ~4 days of full-blocks
            $blocksToKeep
            
            # A node is considering that the chain is synced if sees a block header with timestamp no more
            # than headerChainDiff blocks on average from future
            # testnet value is 800 blocks ~= 1600 minutes (~1.1 days)
            #headerChainDiff = 800

            # State type.  Possible options are:
            # "utxo" - keep full utxo set, that allows to validate arbitrary block and generate ADProofs
            # "digest" - keep state root hash only and validate transactions via ADProofs
            $stateType
            # Download block transactions and verify them (requires BlocksToKeep == 0 if disabled)
            #verifyTransactions = false

            # Download PoPoW proof on node bootstrap
            #PoPoWBootstrap = true

        }

    }      
            
    scorex {
        restApi {
            # Hex-encoded Blake2b256 hash of an API key. 
            # Should be 64-chars long Base16 string.
            # below is the hash of the string 'hello'
            # replace with your actual hash 
            apiKeyHash = "$BLAKE_HASH"
        }
        network {
                
                # Misbehaving peer penalty score will not be increased withing this time interval,
                # unless permanent penalty is applied
                #penaltySafeInterval = 1m
                
                # Max penalty score peer can accumulate before being banned
                #penaltyScoreThreshold = 100

                # Max number of delivery checks. Stop expecting modifier (and penalize peer) if it was not delivered after that
                # number of delivery attempts
                #maxDeliveryChecks = 2
            }
    }
        " > ergo.conf

}


start_node(){
# Starting the node      
#
    #-Djava.util.logging.config.file=logging.properties
    #java -jar -Xmx14G ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 
    java -jar $JVM_HEAP_SIZE ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 
    echo "JVM Heap is set to:" $JVM_HEAP_SIZE
    echo "#### Waiting for a response from the server. ####"
    while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n '.';  done;  # wait for node be ready with progress bar
    #error_log
}
     > server.log 2>&1 & 


first_run() {
# Check for .log files to see if this is the first run
# If(.log) -> extract env -> start_node
# Set basic config for boot, boot & get the hash and then re-set config              
         
    ### Download the latest .jar file                                                                    
    if [ ! -e *.jar ]; then 
        echo "- Retrieving latest node release.."
        LATEST_ERGO_RELEASE=$(curl -s "https://api.github.com/repos/ergoplatform/ergo/releases/latest" | awk -F '"' '/tag_name/{print $4}')
        LATEST_ERGO_RELEASE_NUMBERS=$(echo ${LATEST_ERGO_RELEASE} | cut -c 2-)
        ERGO_DOWNLOAD_URL=https://github.com/ergoplatform/ergo/releases/download/${LATEST_ERGO_RELEASE}/ergo-${LATEST_ERGO_RELEASE_NUMBERS}.jar
        echo "- Downloading Latest known Ergo release: ${LATEST_ERGO_RELEASE}."
        curl --silent -L ${ERGO_DOWNLOAD_URL} --output ergo.jar
    fi 

   
    
    # API 
    read -p "
#### Please create a password. #### 

This will be used to unlock your API. 

Generally using the same API key through the entire sync process can prevent 'Bad API Key' errors:

" input

    export API_KEY=$input
    echo "$API_KEY" > api.conf
    
    # Write basic conf
    set_conf
    
    start_node
    
    export BLAKE_HASH=$(curl --silent -X POST "http://localhost:9053/utils/hash/blake2b" -H "accept: application/json" -H "Content-Type: application/json" -d "\"$input\"")
    echo "$BLAKE_HASH" > blake.conf
    #echo "BLAKE_HASH:$BLAKE_HASH"
    
    case_kill

    # Add blake hash
    set_conf
    
    start_node
    


}

case_kill(){
# Kill process across platform
# TODO: safe kill # curl -X POST "http://127.0.0.1:9053/node/shutdown" -H "api_key: Dj821642148!"
    case "$(uname -s)" in

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo 'MS Windows'
        netstat -ano | findstr :9053
        taskkill /PID 9053 /F
        ;;

    armv7l*|aarch64)
        echo "on Pi!"
        kill -9 $(lsof -t -i:9053)
        ;;
    *) #Other
        kill -9 $(lsof -t -i:9053)
        ;;
    esac

}

error_log(){
# Export ERROR/WARN only to error.log  
# TODO: ValueError: No JSON object could be decoded -> start_node
    ERROR=$(tail -n 5 server.log | grep 'ERROR\|WARN') 
    t_NONE=$(tail -n 5 server.log | grep 'Got GetReaders request in state (None,None,None,None)\|port')
    if [ -z "$ERROR" ]; then
        echo "INFO:" $ERROR
    else
        echo "WARN/ERROR:" $ERROR
        echo "$ERROR" >> error.log
    fi


    ## Count the occurance of t_NONE and kill/restart if > 10
    if [ -n "$t_NONE" ]; then
        echo "Readers not ready. If this keeps happening we'll attempt to restart: $i"
        ((i=i+1)) 
    else
        echo #i: $i
    fi

    if [ $i -gt 10 ]; then
        i=0
        echo i: $i
        #case_kill
        curl -X POST "http://127.0.0.1:9053/node/shutdown" -H "api_key: $API_KEY"
        start_node
        
    fi

}


    

    




######################
# main()
######################

# Set some environment variables
set_env     
set_conf

# Cross-platform port killer
case_kill   

count=`ls -1 *.log 2>/dev/null | wc -l`
if [ $count != 0 ]; then 
    #rm ergo.log
    #rm server.log # remove the log file on each run so it doesn't become useless.
    
    API_KEY=$(cat "api.conf")
    echo "api.conf: API Key is set to: $API_KEY"
    BLAKE_HASH=$(cat "blake.conf")
    echo "blake.conf: Blake hash is: $BLAKE_HASH"
    start_node
else 
    # If no .log file - we assume first run
    first_run 
fi

# Set the configuration file
set_conf   

case_kill

echo "done"
echo "This script sets your hash and then exits. Please run with.."
exit 1

# Launch in browser
#python${ver:0:1} -mwebbrowser http://127.0.0.1:9053/panel 

