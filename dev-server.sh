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
    echo "  dev-server -p [read/write] use a production database (default write)"
    echo "  dev-server -l [port]       use localhost as database. use port [port] if given"
    echo "  dev-server -v              don't require vpn"
    echo ""
    echo "  [database]                 database name"
    echo "                             MONGO_URL set to:"
    echo "                               'mongodb-small-{database}-dev.ops.clever.com'"
    echo "                             or if -p flag set:"
    echo "                               'mongodb-{database or write}-prod.ops.clever.com'"
}

API="$API_PATH"
VPN_IP="50.18.217.135"
CHECK_VPN=true
# defaults
DB_NAME="jefff2"
DB_ENV="dev"
DB_TYPE="small"

while getopts ":-:hdlpv" opt; do
    case $opt in
        -)
            if [ "$*" = "--help" ]; then
                display_help
                exit 0
            else
                echo "Invalid option: -$OPTARG"
                display_usage
                exit 1
            fi
            ;;
        h)
            display_help
            exit 0
            ;;
        d)
            DEBUG=`basename "$PWD"`":*"
            shift $(( OPTIND - 1 ));
            ;;
        l)
            shift $(( OPTIND - 1 ));
            MONGO="localhost:${1:-27017}"
            ;;
        p)
            DB_ENV="prod"
            DB_NAME="write"
            DB_TYPE=""
            shift $(( OPTIND - 1 ));
            ;;
        v)
            CHECK_VPN=false
            shift $(( OPTIND - 1 ));
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "$USAGE"
            exit 1
            ;;
    esac
done


if [ $CHECK_VPN ]; then

   # get ip from external source
    MY_IP=`curl -s http://ipecho.net/plain ; echo`

    # check if there's more than an ip in the response
    if [[ -n $(echo $MY_IP | sed 's|[0-9\.]*||') ]]; then
        # try again with a different service
        MY_IP=`curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g'`
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

DB_NAME=${1:-$DB_NAME}

MONGO=${MONGO:-"mongodb-$DB_TYPE-$DB_NAME-$DB_ENV.ops.clever.com"}
MONGO=${MONGO//--/-}
KEY="$CLEVER_ADMIN_API_KEY"

blue='\033[0;36m'
clear='\033[0m'
green='\033[0;32m'
grey='\033[1;30m'
yellow='\033[1;33m'

echo -e "${green}Connecting to dev-server...${clear}"
echo -e "  Database${grey} at ${blue}$MONGO.${clear}"
echo -e "  Clever admin API key${grey} is set to ${blue}$KEY${clear}."
echo -e "  Clever API${grey} is at ${blue}$API${clear}."
if [ -n "$DEBUG" ]; then
    echo -e "  DEBUG${grey} is on for ${blue}$DEBUG${clear}."
fi
echo ""
DEBUG=$DEBUG MONGO_URL=$MONGO CLEVER_ADMIN_API_KEY=$KEY API_PATH=$API npm run-script dev-server
