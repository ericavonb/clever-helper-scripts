#! /bin/bash


USAGE="Usage: dev-server [--help] [-hpdlv] [-l PORT]  [database]"

display_help() {
    echo "$USAGE"
    echo ""
    echo "Runs 'npm run-script dev-server' with the necessary environment variables."
    echo ""
    echo "  dev-server --help          display help message"
    echo "  dev-server -h              display help message"
    echo "  dev-server -d              put on debug for current repo ('DEBUG=<repo>:*)'"
    echo "  dev-server -p              use a production database and api"
    echo "  dev-server -l [port]       use localhost as database. use port [port] if given"
    echo "  dev-server -v              don't require vpn"
    echo ""
    echo "  [database]                 dev database name"
    echo "                             MONGO_URL set to:"
    echo "                               'mongodb-small-{database}-dev.ops.clever.com'"
    echo "CONFIG FILE (optional)"
    echo "  - sources the file named '.dev-config' in current directory "
    echo ""
}


# defaults
source ./.dev-config &> /dev/null
API=${API_PATH:-"localhost:5001"}
VPN_IP="50.18.217.135"
CHECK_VPN=true
DEV_DB="nathan"
MONGO_HOST=""
#"$MONGO_URL"

connect_to_prod_db() {
    PORT="30000"
    ssh -f ubuntu@mongodb-write-prod.ops.clever.com -L $PORT:mongodb-write-prod.ops.clever.com:27017 -N &> /dev/null
    MONGO_HOST="localhost:$PORT"
    return
}

while getopts ":-hdpl:v:" OPT; do
    case $OPT in
        l)
            MONGO_HOST="localhost"
            # LOCAL FLAG
            LOCAL=true
            if eval [[ -n "$"$(($OPTIND-0))"" ]]; then
                MONGO_HOST="--port $OPTARG localhost"
            else
                if [[ -n "$OPTARG" ]]; then
                    MONGO_HOST="--port $OPTARG localhost"

                else
                    ((--OPTIND))
                fi
            fi
            ;;
        -)
            if [ "$*" = "--help" ]; then
                display_help
                exit 0
            fi
            echo "Invalid option: -$OPTARG"
            echo "$USAGE"
            exit 1
            ;;
        h)
            display_help
            exit 0
            ;;
        d)
            DEBUG=${DEBUG:-`basename "$PWD"`":*"}
            ;;
        p)
            # PROD FLAG
            PROD=true
            ;;
        v)
            CHECK_VPN=false
            ;;
        :)
            if [ "$OPTARG" = "l" ]; then
                MONGO_HOST="--port localhost"
                # LOCAL FLAG
                LOCAL=true
            else
                if [ "$OPTARG" = "v" ]; then
                    CHECK_VPN=false
                else
                    echo "Invalid options: cannot use both -$OPTARG"
                    echo "$USAGE"
                    exit 1
                fi
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "$USAGE"
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))

if [ $PROD ]; then
    if [ $LOCAL ]; then
        echo "Invalid options: cannot use both -p and -l"
        echo "$USAGE"
        exit 1
    fi
    connect_to_prod_db

fi

if [ $CHECK_VPN ]; then
   # get ip from external source
    MY_IP=`curl --connect-timeout 5 -s http://ipecho.net/plain ; echo`

    # check if there's more than an ip in the response
    if [[ -n $(echo $MY_IP | sed 's|[0-9\.]*||') ]]; then
        # try again with a different service
        MY_IP=`curl --connect-timeout 5 -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g'`
        # check if there's more than an ip from second service
        if [[ -n $(echo $MY_IP | sed 's|[0-9\.]*||') ]]; then
            echo "Could not get external IP. Proceeding without VPN check."
        fi
    fi
    if [ "$MY_IP" != "$VPN_IP" ] && [ "$MY_IP" != `host vpn.ops.clever.com | sed 's/vpn.ops.clever.com has address //'` ]; then
        echo "ERROR: Please connect to the VPN before starting the dev-server."
        exit 1
    fi
fi

DEV_DB=${1:-"$DEV_DB"}
MONGO_HOST=${MONGO_HOST:-"mongodb-small-$DEV_DB-dev.ops.clever.com"}

KEY="$CLEVER_ADMIN_API_KEY"

blue='\033[0;36m'
clear='\033[0m'
green='\033[0;32m'
grey='\033[1;30m'
yellow='\033[1;33m'

echo -e "${green}Connecting to dev-server...${clear}"
echo -e "  Database${grey} at ${blue}$MONGO_HOST.${clear}"
echo -e "  Clever admin API key${grey} is set to ${blue}$KEY${clear}."
echo -e "  Clever API${grey} is at ${blue}$API${clear}."
if [ -n "$DEBUG" ]; then
    echo -e "  DEBUG${grey} is on for ${blue}$DEBUG${clear}."
fi
echo ""
DEBUG=$DEBUG MONGO_URL=$MONGO_HOST CLEVER_ADMIN_API_KEY=$KEY API_PATH=$API npm run-script dev-server
