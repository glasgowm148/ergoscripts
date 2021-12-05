#!/bin/bash

# Shell script for installing Ergo Node on any platform.
# markglasgow@gmail.com - 29 November
# -------------------------------------------------------------------------
# Run this with
# bash -c "$(curl -s https://node.phenotype.dev)"


set_env(){
# Variables
# CALLEDBY: main
#
    # Initial variables
    export API_KEY="dummy"
    WHAT_AM_I=$(uname -m)
    
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    i=0
    let PERCENT_BLOCKS=100
    let PERCENT_HEADERS=100

    # Check for python
    if ! hash python; then
        echo "python is not installed"
        exit 1
    fi
    #pyv="$(python -V 2>&1)"
    #echo "$pyv"
    ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
    #echo "$ver"
    #if [ "$ver" -gt "27" ]; then
    #    echo ver:$ver
        #echo "This script requires python 2.7 or lesser"
        #exit 1
    # fi

    # Set memory
    case "$(uname -s)" in

        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            echo 'MS Windows'
            #WIN_MEM=$(systeminfo)
            WIN_MEM=$(wmic OS get FreePhysicalMemory)
            kb_to_mb=$((memory * 1024))
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
            export blocksToKeep="#blocksToKeep = 1440 # Set this to 1440-2880 for Pi"
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
            sleep 5
            echo "Raspberry Pi detected, running node in light-mode and only keeping last 1440 blocks"
            export blocksToKeep="blocksToKeep = 1440 # 1440 = ~2days"
            ;;
    esac
    
}

set_conf (){
# Write the config file with the generated hash
# CALLEDBY: check_run
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
        #skipV1TransactionsValidation = true
        
        # Number of last blocks to keep with transactions and ADproofs, for all other blocks only header will be stored.
        # Keep all blocks from genesis if negative
        # download and keep only ~4 days of full-blocks
        $blocksToKeep

        # State type.  Possible options are:
        # "utxo" - keep full utxo set, that allows to validate arbitrary block and generate ADProofs
        # "digest" - keep state root hash only and validate transactions via ADProofs
        stateType = "digest"

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
        apiKeyHash = "$API_KEY"
    }
    network {
            
            # Misbehaving peer penalty score will not be increased withing this time interval,
            # unless permanent penalty is applied
            penaltySafeInterval = 1m
            
            # Max penalty score peer can accumulate before being banned
            penaltyScoreThreshold = 100

            # Max number of delivery checks. Stop expecting modifier (and penalize peer) if it was not delivered after that
            # number of delivery attempts
            maxDeliveryChecks = 2
        }
}
    " > ergo.conf

}


start_node(){
# Starting the node      
#
    #-Djava.util.logging.config.file=logging.properties
    java -jar $JVM_HEAP_SIZE ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 
    echo "JVM Heap is set to:" $JVM_HEAP_SIZE
    echo "#### Waiting for a response from the server. ####"
    while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n '.'; tail -n 1 server.log;  done;  # wait for node be ready with progress bar
    error_log
}


check_run() {
# Check for .log files to see if this is the first run
# If(.log) -> extract env -> start_node
# else set_conf() -> get_hash() -> set_conf()
    count=`ls -1 *.log 2>/dev/null | wc -l`
    if [ $count != 0 ]; then 
        rm ergo.log
        rm server.log # remove the log file on each run so it doesn't become useless.
        #JVM_HEAP_SIZE=$(cat "jvm.conf")
        #echo "jvm.conf: JVM Heap size is set to: $JVM_HEAP_SIZE"

        API_KEY=$(cat "api.conf")
        echo "api.conf: API Key is set to: $API_KEY"
        
        start_node
    else # If no .log file - we assume first run
        if [ -n `which java` ]; 
            then
                echo 
            else
                echo "No Java version found"
                echo "Please run"
                echo "curl -s "https://beta.sdkman.io" | bash"
        fi
        
        # ()
        #set_heap 
        
        read -p "
            #### Please create a password. #### 

            This will be used to unlock your API. Generally using the same API key through the entire sync process can prevent 'Bad API Key' errors.

            " input

        export API_KEY=$input
        echo "$API_KEY" > api.conf
        ###########################################################################           
        ### Download the latest .jar file                                                                    
        ###########################################################################
        if [ -e *.jar ]; 
        then 
            echo
            #echo "- Node .jar is already downloaded"
        else
            echo "- Retrieving latest node release.."
            LATEST_ERGO_RELEASE=$(curl -s "https://api.github.com/repos/ergoplatform/ergo/releases/latest" | awk -F '"' '/tag_name/{print $4}')
            LATEST_ERGO_RELEASE_NUMBERS=$(echo ${LATEST_ERGO_RELEASE} | cut -c 2-)
            ERGO_DOWNLOAD_URL=https://github.com/ergoplatform/ergo/releases/download/${LATEST_ERGO_RELEASE}/ergo-${LATEST_ERGO_RELEASE_NUMBERS}.jar
            echo "- Downloading Latest known Ergo release: ${LATEST_ERGO_RELEASE}."
            curl --silent -L ${ERGO_DOWNLOAD_URL} --output ergo.jar
        fi 


        ###########################################################################           
        ### Prompt the user for a password and hash it using Blake2b                                                                    
        ###########################################################################

        # Write basic conf
        set_conf

        # Set the API key
        get_hash

        # Write basic conf
        set_conf


    fi 

}

case_kill(){
# Kill process across platform
# TODO: safe kill # curl -X POST "http://127.0.0.1:9053/node/shutdown" -H "api_key: hellomyd"
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
#
    ERROR=$(tail -n 5 server.log | grep 'ERROR\|WARN') 
    t_NONE=$(tail -n 5 server.log | grep 'Got GetReaders request in state (None,None,None,None)\|port')

    if [ -z ${ERROR+x} ]; then
        echo "INFO:" $ERROR
    else
        echo "WARN/ERROR:" $ERROR
        echo "$ERROR" >> error.log
    fi

    ## Count the occurance of t_NONE and kill/restart if > 10
    if [ ! -z "$t_NONE" ]; then
        echo i: $i
        ((i=i+1)) 
    else
        echo #i: $i
    fi

    if [ $i -gt 10 ]; then
        i=0
        echo i: $i
        case_kill
        start_node
        
    fi

}

get_hash(){
# Get & Set API key
#
    start_node

    if [ -z ${API_KEY+x} ]; then 
        #echo "API_KEY is unset";
        export API_KEY=$(curl --silent -X POST "http://localhost:9053/utils/hash/blake2b" -H "accept: application/json" -H "Content-Type: application/json" -d "\"$input\"")
    fi

    case_kill
    
    set_conf

    start_node

}

get_heights(){
# This method pulls the latest height and header height from /info
#
    
    # run with python2 if python3 is default
    if [[ "$ver" -gt "27" ]]; then

            API_HEIGHT2==$(\
                curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )

            HEADERS_HEIGHT=$(\
                curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
                | python2 -c "import sys, json; print json.load(sys.stdin)['headersHeight'];"\
            )

            HEIGHT=$(\
            curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
            | python2 -c "import sys, json; print json.load(sys.stdin)['parameters']['height'];"\
            )
            
            FULL_HEIGHT=$(\
            curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
            | python2 -c "import sys, json; print json.load(sys.stdin)['fullHeight'];"\
            )
            
        else

            API_HEIGHT2==$(\
                curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )
            
            HEADERS_HEIGHT=$(\
                curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
                | python -c "import sys, json; print json.load(sys.stdin)['headersHeight'];"\
            )

            HEIGHT=$(\
            curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
            | python -c "import sys, json; print json.load(sys.stdin)['parameters']['height'];"\
            )
            
            FULL_HEIGHT=$(\
            curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
            | python -c "import sys, json; print json.load(sys.stdin)['fullHeight'];"\
            )

    fi
    
    # Calculate %
    if [ ! -z ${API_HEIGHT2+x} ]; then
        API_HEIGHT=${API_HEIGHT2:92:6}

        if [ ! -z ${HEADERS_HEIGHT+x} ]; then # TODO: Triggers an error when 0??

            if [ $HEADERS_HEIGHT -ne 0 ]; then
                    let expr PERCENT_HEADERS=$(( ( ($API_HEIGHT - $HEADERS_HEIGHT) * 100) / $API_HEIGHT   )) 
            fi

        fi

        if [ ! -z ${HEIGHT+x} ]; then

            if [ $HEIGHT -ne 0 ]; then
                    let expr PERCENT_BLOCKS=$(( ( ($API_HEIGHT - $HEIGHT) * 100) / $API_HEIGHT   ))
            fi

        fi
    
    fi
    
} 
    

launch_panel() {
# Open browser to panel page
#
    if [ "$ver" -gt "27" ]; 
        then
            python2 -mwebbrowser http://127.0.0.1:9053/panel 
        else
            python -mwebbrowser http://127.0.0.1:9053/panel 
    fi
}


print_con() {
#TODO: Exit when height is met? 
#TODO: Setup System services?
    while sleep 1
        do
        clear
        printf "%s    \n\n" \
        "To use the API, enter your password ('$API_KEY') on 127.0.0.1:9053/panel under 'Set API key'."\
        "Please follow the next steps on docs.ergoplatform.org to initialise your wallet."  \
        "For best results please disable any sleep mode while syncing"  \
        "Sync Progress;"\
        "### Headers: ~$(( 100 - $PERCENT_HEADERS ))% Complete ($HEADERS_HEIGHT/$API_HEIGHT) ### "\
        "### Blocks:  ~$(( 100 - $PERCENT_BLOCKS ))% Complete ($HEIGHT/$API_HEIGHT) ### "
        
        echo ""
        echo "The most recent lines from server.log will be shown here:"
        error_log
        
        dt=$(date '+%d/%m/%Y %H:%M:%S');
        echo "$dt: HEADERS: $HEADERS_HEIGHT, HEIGHT:$HEIGHT" >> height.log

        get_heights  

    done
}


######################
# main()
######################
set_env     # 1. Set some environment variables

case_kill   # 2. Cross-platform port killer

check_run   # 3. Check if first run

set_conf    # 4. Set the configuration file

print_con   # 5. Print to console