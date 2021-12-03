#!/bin/bash

# Shell script for installing Ergo Node under Unix.
# markglasgow@gmail.com - 29 November
# -------------------------------------------------------------------------
# Run this with
# bash -c "$(curl -s https://node.phenotype.dev)"
# Dummy string to populate the .conf file before true API key generated. 
export BLAKE_HASH="dummy"
WHAT_AM_I=$(uname -m)
echo "$WHAT_AM_I"
pyv="$(python -V 2>&1)"
echo "$pyv"

if ! hash python; then
    echo "python is not installed"
    #exit 1
fi

ver=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
echo "$ver"
if [ "$ver" -gt "27" ]; then
    echo ver:$ver
    #echo "This script requires python 2.7 or lesser"
    #exit 1
fi

dt=$(date '+%d/%m/%Y %H:%M:%S');
i=0


# Clean up error files if exist

###########################################################################           
### Run the server, the -Xmx3G flag specifies the JVM Heap size
###########################################################################
INPUT_heap_size() {
    if [ -z $JVM_HEAP_SIZE ]; then
        read -p "
        #### How many GB of memory should we give the node? ####   

        This must be less than your total RAM size. 

        Recommended: 
        - 1 for Raspberry Pi
        - 2-3 for laptops

        " JVM_HEAP
        export JVM_HEAP_SIZE="-Xmx${JVM_HEAP}g"
        echo "$JVM_HEAP_SIZE" > jvm.conf
    fi 
}

###########################################################################           
### Write the config file with the generated hash                                                                    
###########################################################################
write_conf (){
    echo "
    ergo {
            node {
                # Full options available at 
                # https://github.com/ergoplatform/ergo/blob/master/src/main/resources/application.conf
                
                mining = false
                
                # Skip validation of transactions in the mainnet before block 417,792 (in v1 blocks).
                # Block 417,792 is checkpointed by the protocol (so its UTXO set as well).
                # The node still applying transactions to UTXO set and so checks UTXO set digests for each block.
                #skipV1TransactionsValidation = true
                
                # Number of last blocks to keep with transactions and ADproofs, for all other blocks only header will be stored.
                # Keep all blocks from genesis if negative
                # download and keep only ~4 days of full-blocks
                # blocksToKeep = 2880

                # State type.  Possible options are:
                # "utxo" - keep full utxo set, that allows to validate arbitrary block and generate ADProofs
                # "digest" - keep state root hash only and validate transactions via ADProofs
                stateType = "digest"

                # Download block transactions and verify them (requires BlocksToKeep == 0 if disabled)
                #verifyTransactions = false

                # Download PoPoW proof on node bootstrap
                #PoPoWBootstrap = true

                }
            network {
                
                #bindAddress = '0.0.0.0:9053'

                # Misbehaving peer penalty score will not be increased withing this time interval,
                # unless permanent penalty is applied
                penaltySafeInterval = 1m
                
                # Max penalty score peer can accumulate before being banned
                penaltyScoreThreshold = 100

                # Max number of delivery checks. Stop expecting modifier (and penalize peer) if it was not delivered after that
                # number of delivery attempts
                maxDeliveryChecks = 2
            }
        
    scorex {
        restApi {
            # Hex-encoded Blake2b256 hash of an API key. 
            # Should be 64-chars long Base16 string.
            # below is the hash of the string 'hello'
            # replace with your actual hash 
            apiKeyHash = "$BLAKE_HASH"
        }
    }
    }" > ergo.conf

}

###########################################################################           
### Starting the node                                                                  
###########################################################################
start_node(){

    #-Djava.util.logging.config.file=logging.properties
    java -jar $JVM_HEAP_SIZE ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 
    
    echo "#### Waiting for a response from the server. ####"
    while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n '.'; tail -n 1 server.log;  done;  # wait for node be ready with progress bar
    error_log
}

###########################################################################           
### Check for .log files to see if this is the first run
###########################################################################
first_run() {
    count=`ls -1 *.log 2>/dev/null | wc -l`
    if [ $count != 0 ]; then 
        #echo true
        #mv error.log error_backup.log
        #rm error.log
        rm ergo.log
        rm server.log # remove the log file on each run so it doesn't become useless.
        JVM_HEAP_SIZE=$(cat "jvm.conf")
        echo $JVM_HEAP_SIZE

        API_KEY=$(cat "api.conf")
        echo $API_KEY
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

        INPUT_heap_size 

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
        write_conf

        # Set the API key
        start_and_hash

    fi 

}


###########################################################################           
### Write the config file with the generated hash                                                                    
###########################################################################
serial_killer(){
    case "$(uname -s)" in

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo 'MS Windows'
        netstat -ano | findstr :9053
        taskkill /PID 9053 /F
        ;;

    ARMV*|aarch64)
      echo 'Pi' > pi.log
      ;;
    # Add here more strings to compare
    # See correspondence table at the bottom of this answer

    *)
        #echo 'Other OS' 
        kill -9 $(lsof -t -i:9053)
        ;;
    esac

}









###########################################################################           
### Export ERROR/WARN only to error.log                                                                 
###########################################################################
error_log(){
    
    ERROR=$(tail -n 5 server.log | grep 'ERROR\|WARN') 
    t_NONE=$(tail -n 5 server.log | grep 'Got GetReaders request in state (None,None,None,None)\|port')
    if [ -z "$ERROR" ]; then
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
        serial_killer
        start_node
        
    fi

}


###########################################################################           
### Get & Set API key                                                                
###########################################################################
start_and_hash(){
    start_node

    if [ -z ${BLAKE_HASH+x} ]; then 
        #echo "blake_hash is unset";
        export BLAKE_HASH=$(curl --silent -X POST "http://localhost:9053/utils/hash/blake2b" -H "accept: application/json" -H "Content-Type: application/json" -d "\"$input\"")
    fi

    serial_killer
    sleep 2
    write_conf
    sleep 2
    
    start_node

}

###########################################################################
###########################################################################           
### main()   
### 
###########################################################################
###########################################################################

serial_killer # Call it once at the start to kill any hanging processes

# Check for .log
first_run

#######################################
# Get various heights
# GLOBALS:
#   A_STRING_PREFIX
# ARGUMENTS:
#   String to print
# OUTPUTS:
#   Write String to stdout
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################


###########################################################################           
### This should open the browser (providing python is installed)
### At this stage you can check if your API key works as prompted.                                                        
###########################################################################
python -mwebbrowser http://127.0.0.1:9053/panel 


###########################################################################           
### This method pulls the latest height and header height from /info
###########################################################################
get_heights(){
    
    API_HEIGHT2==$(\
        curl --silent --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )
    API_HEIGHT=${API_HEIGHT2:92:6}
    #echo $API_HEIGHT
    
    #echo "Target height retrieved from API: $API_HEIGHT"

    HEADERS_HEIGHT=$(\
        curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
        | python -c "import sys, json; print json.load(sys.stdin)['headersHeight'];"\
    )
    #echo "Current header height: $HEADERS_HEIGHT"

    HEIGHT=$(\
    curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
    | python -c "import sys, json; print json.load(sys.stdin)['parameters']['height'];"\
    )
    
    let FULL_HEIGHT=$(\
    curl --silent --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
    | python -c "import sys, json; print json.load(sys.stdin)['fullHeight'];"\
    )
    echo "FULL_HEIGHT:" $FULL_HEIGHT

    # Set the percentages [ -n "$HEADERS_HEIGHT" ] && 
    if [ $HEADERS_HEIGHT -ne 0 ]; then
       # echo "api: $API_HEIGHT, hh:$HEADERS_HEIGHT"
       echo "API:" $API_HEIGHT "HEADERS_HEIGHT:" $HEADERS_HEIGHT "HEIGHT:"  $HEIGHT 
       let expr PERCENT_HEADERS=$(( ( ($API_HEIGHT - $HEADERS_HEIGHT) * 100) / $API_HEIGHT   )) 
        
    fi

    if [ $HEIGHT -ne 0 ]; then
        let expr PERCENT_BLOCKS=$(( ( ($API_HEIGHT - $HEIGHT) * 100) / $API_HEIGHT   ))
        echo "API:" $API_HEIGHT "HEIGHT:"  $HEIGHT 
    fi

    
    ###########################################################################           
    ### The `fullHeight` field should only be set when the node is sync'd
    ### This checks that height against the reported API height and 
    ###########################################################################
    #if [ -n "$FULL_HEIGHT" ] && [ $FULL_HEIGHT -ne 0 ]; then
    #    # echo $FULL_HEIGHT " != None"
    #    echo
    #    if [ $FULL_HEIGHT -ne $API_HEIGHT ]; then
    #        echo "##### WARN - Full height and API height do not match! ##### "
    #        echo "##### FULL_HEIGHT is $FULL_HEIGHT #####"
    #        echo "##### API_HEIGHT is $API_HEIGHT #####"
    #        echo "##### Writing my.log file and starting sync from scratch #####"
    #        echo "##### Please check the .log files for further details #####"
    #        echo "$dt - ERROR: MISSYNC - FULL_HEIGHT is $FULL_HEIGHT while API_HEIGHT is $API_HEIGHT" >> my.log
    #        sleep 20
    #        #rm -rf .ergo 
            
            # kill
    #        serial_killer
            
            # start node
    #        start_node

    #   else
    #        echo "$FULL_HEIGHT ne to $API_HEIGHT"
    #        echo "Successfully sync'd!"
    #        sleep 60
    #    fi
    #else
    #    echo
        #echo "fullheight is $FULL_HEIGHT" #0
    # fi

   
    
}

###########################################################################           
### Display progress to user
###########################################################################

# Dummy values to start
let PERCENT_BLOCKS=100
let PERCENT_HEADERS=100


while sleep 1
do
    clear
    
    
    printf "%s    \n\n" \
      "To use the API, enter your password ('$API_KEY') on 127.0.0.1:9053/panel under 'Set API key'."\
      "Please follow the next steps on docs.ergoplatform.org to initialise your wallet."  \
      "Sync Progress;"\
      "### Headers: ~$(( 100 - $PERCENT_HEADERS ))% Complete ($HEADERS_HEIGHT/$API_HEIGHT) ### "\
      "### Blocks:  ~$(( 100 - $PERCENT_BLOCKS ))% Complete ($HEIGHT/$API_HEIGHT) ### "
      
    echo ""
    echo "The most recent lines from server.log will be shown here:"

    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "$dt: HEADERS: $HEADERS_HEIGHT, HEIGHT:$HEIGHT" >> height.log

    get_heights
    error_log

done

# WARN  [ergoref-api-dispatcher-8] o.e.n.ErgoReadersHolder - Got GetReaders request in state (None,None,None,None)
# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux