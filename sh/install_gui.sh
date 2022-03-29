#!/bin/bash
# Git test
# Shell script for installing Ergo Node on any platform.
# markglasgow@gmail.com 
# -------------------------------------------------------------------------
# Run this with
# bash -c "$(curl -s https://node.phenotype.dev)"


# / 
# Improvements
# / 
# 1. Better error logging + bug detection
# 2. Test-net options
# 3. Check for node mistakenly thinking it's sync'ed (headerChainDiff?)
# 4. Light-mode Yes/No
export BLAKE_HASH="324dcf027dd4a30a932c441f365a25e86b173defa4b8e58948253471b81b72cf"

# Set some environment variables
set_environment(){
    export API_KEY="dummy"
    
    let j=0
    #OS=$(uname -m)

    [ -d ergo ] || mkdir ergo && cd ergo
    
    
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    let i=0
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
   
    # check python version
    pyv=$(python -V 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
    #echo $pyv

    
    
    jver=`java -version 2>&1 | grep 'version' 2>&1 | awk -F\" '{ split($2,a,"."); print a[1]"."a[2]}'`

    if [[ $jver > "1.8" ]]; then                
        echo "Please update to the latest version"
        echo "curl -s "https://beta.sdkman.io" | bash"
        #exit 1
    else
        echo "Java="$jver
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
            #echo "JVM_HEAP_SIZE Set to:" $JVM_HEAP_SIZE
            
            #echo "Raspberry Pi detected, running node in light-mode" 

            #echo "blocksToKeep = 1440 # keep ~2 days of blocks"
            #export blocksToKeep="#blocksToKeep = 1440 # 1440 = ~2days"

            #echo "stateType = digest # Note: You cannot validate arbitrary block and generate ADProofs due to this"
            #export stateType="stateType = digest"

            #sleep 10

            ;;
    esac
    
}

set_configuration (){
        echo "
    ergo {
        node {
            # Full options available at 
            # https://github.com/ergoplatform/ergo/blob/master/src/main/resources/application.conf
            
            mining = false

            # Number of state snapshot diffs to keep. Defines maximum rollback depth
            #keepVersions = 32

            ### there's light regime where the node is not storing UTXO set, and can validate only limited in length suffix of full blocks . Such nodes are running on Raspberry Pi with 0.5 GB given even.
            # Skip validation of transactions in the mainnet before block 417,792 (in v1 blocks).
            # Block 417,792 is checkpointed by the protocol (so its UTXO set as well).
            # The node still applying transactions to UTXO set and so checks UTXO set digests for each block.
            skipV1TransactionsValidation = true
            
            # Number of last blocks to keep with transactions and ADproofs, for all other blocks only header will be stored.
            # Keep all blocks from genesis if negative
            # download and keep only ~4 days of full-blocks
            #$blocksToKeep
            
            # A node is considering that the chain is synced if sees a block header with timestamp no more
            # than headerChainDiff blocks on average from future
            # 800 blocks ~= 1600 minutes (~1.1 days)
            # headerChainDiff = 80

            # State type.  Possible options are:
            # "utxo" - keep full utxo set, that allows to validate arbitrary block and generate ADProofs
            # "digest" - keep state root hash only and validate transactions via ADProofs
            $stateType


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

                
                maxConnections = 10

            }
    }
        " > ergo/ergo.conf

}

start_node(){
    java -jar $JVM_HEAP_SIZE ergo.jar --mainnet -c ergo.conf > server.log 2>&1 & 
    echo "JVM Heap is set to:" $JVM_HEAP_SIZE
    echo "#### Waiting for a response from the server. ####"
    while ! curl --output /dev/null --silent --head --fail http://localhost:9053; do sleep 1 && echo -n error_log;  done;  # wait for node be ready with progress bar
    
}

# Set basic config for boot, boot & get the hash and then re-set config 
first_run() {

            
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

        
        
        start_node
        
        export BLAKE_HASH=$(curl --silent -X POST "http://localhost:9053/utils/hash/blake2b" -H "accept: application/json" -H "Content-Type: application/json" -d "\"$input\"")
        echo "$BLAKE_HASH" > blake.conf
        #echo "BLAKE_HASH:$BLAKE_HASH"
        
        func_kill

        # Add blake hash
        set_configuration
        
        start_node
        
        # Add blake hash
        #set_configuration

}

func_kill(){
    case "$(uname -s)" in

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo 'MS Windows'
        netstat -ano | findstr :9053
        taskkill /PID 9053 /F
        ;;

    armv7l*|aarch64)
        echo "on Pi!"
        #kill -9 $(lsof -t -i:9053)
        #kill -9 $(lsof -t -i:9030)
        killall -9 java
        sleep 10
        ;;
    *) #Other
        kill -9 $(lsof -t -i:9053)
        kill -9 $(lsof -t -i:9030)
        killall -9 java
        sleep 10
        ;;
    esac

}

error_log(){
    inputFile=ergo.log
    
    if egrep 'ERROR\|WARN' "$inputFile" ; then
        echo "WARN/ERROR:" $egrep
        echo "$egrep" >> error.log
    elif egrep 'Got GetReaders request in state (None,None,None,None)\|port' "$inputFile" ; then
        echo "Readers not ready. If this keeps happening we'll attempt to restart: $i"
        ((i=i+1)) 
    elif egrep 'Invalid z bytes' "$inputFile" ; then
        echo "zBYTES error:" $egrep
        echo "$egrep" >> error.log
    
    fi

    if [ $i -gt 10 ]; then
        i=0
        echo i: $i
        #func_kill
        curl -X POST --max-time 10 "http://127.0.0.1:9053/node/shutdown" -H "api_key: $API_KEY"
        start_node
        
    fi

}

check_status(){
    LRED="\033[1;31m" # Light Red
    LGREEN="\033[1;32m" # Light Green
    NC='\033[0m' # No Color

    string=$(curl -sf --max-time 20 "${1}")
    
    if [ -z "$string" ]; then
        echo -e "${LRED}${1} is down${NC}"
        func_kill
        
        start_node
        print_console
    else
       echo -e "${LGREEN}${1} is online${NC}"
    fi
}

get_heights(){

    check_status "localhost:9053/info"

    if [[ ${pyv:0:1} == "3" ]]; then 
        API_HEIGHT2==$(\
                curl --silent --max-time 10 --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )

        HEADERS_HEIGHT=$(\
            curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
            | python -c "import sys, json; print(json.load(sys.stdin)['headersHeight']);"\
        )

        HEIGHT=$(\
        curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
        | python -c "import sys, json; print(json.load(sys.stdin)['parameters']['height']);"\
        )
        
        FULL_HEIGHT=$(\
        curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
        | python -c "import sys, json; print(json.load(sys.stdin)['fullHeight']);"\
        )               
        
    fi

    if [[ ${pyv:0:1} == "2" ]]; then                
       API_HEIGHT2==$(\
                curl --silent --max-time 10 --output -X GET "https://api.ergoplatform.com/api/v1/networkState" -H "accept: application/json" )

        HEADERS_HEIGHT=$(\
            curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json" \
            | python -c "import sys, json; print json.load(sys.stdin)['headersHeight'];"\
        )

        HEIGHT=$(\
        curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
        | python -c "import sys, json; print json.load(sys.stdin)['parameters']['height'];"\
        )
        
        FULL_HEIGHT=$(\
        curl --silent --max-time 10 --output -X GET "http://localhost:9053/info" -H "accept: application/json"   \
        | python -c "import sys, json; print json.load(sys.stdin)['fullHeight'];"\
        )
    fi

    
    API_HEIGHT=${API_HEIGHT2:92:6}
    # Calculate %
    if [ -n "$API_HEIGHT" ] && [ "$API_HEIGHT" -eq "$API_HEIGHT" ] 2>/dev/null; then
        
        
        if [ -n "$HEADERS_HEIGHT" ] && [ "$HEADERS_HEIGHT" -eq "$HEADERS_HEIGHT" ] 2>/dev/null; then
            let expr PERCENT_HEADERS=$(( ( ($API_HEIGHT - $HEADERS_HEIGHT) * 100) / $API_HEIGHT   )) 
        fi

        if [ -n "$HEIGHT" ] && [ "$HEIGHT" -eq "$HEIGHT" ] 2>/dev/null; then
            let expr PERCENT_BLOCKS=$(( ( ($API_HEIGHT - $HEIGHT) * 100) / $API_HEIGHT   ))
        fi        
        
        if [ -n "$h_tmp" ] && [ "$HEIGHT" -eq "$h_tmp" ] 2>/dev/null; then
            echo "height changed"
            echo "height:$HEIGHT, h_temp:$h_temp"
            j=0
            sleep 5
        else 
            echo "height same"
            j=$((j+1))
            echo "height:$HEIGHT==h_temp:$h_temp, j:$j"
            sleep 5
        fi
        h_temp=$HEIGHT

        # if height==headersHeight then we are syncronised. 
        if [ -n "$HEADERS_HEIGHT" ] && [ "$HEADERS_HEIGHT" -eq "$HEIGHT" ] 2>/dev/null; then
            echo "HeadersHeight == Height"
            echo "Node is syncronised"
            exit 1

        fi

        # If HeadersHeight < Height then something has gone wrong
        if [ -n "$HEADERS_HEIGHT" ] && [ "$HEADERS_HEIGHT" -lt "$HEIGHT" ] 2>/dev/null; then
            echo "HeadersHeight < Height"
            echo "Mis-sync!"
            exit 1

        fi
   
        

    fi
    
} 
    
print_console() {
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
        error_log
        dt=$(date '+%d/%m/%Y %H:%M:%S');
        echo "$dt: HEADERS: $HEADERS_HEIGHT, HEIGHT:$HEIGHT" >> height.log

        get_heights  

     

        
        

    done
}


# /
# main()
# / 
set_configuration
# Set some environment variables
set_environment     

# Cross-platform killer
func_kill   

# Check for the prescence of log files
count=`ls -1 blake.conf 2>/dev/null | wc -l`
if [ $count != 0 ]; then   
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
set_configuration   

# Launch in browser
python${ver:0:1} -mwebbrowser http://127.0.0.1:9053/info 

# Print to console
print_console   