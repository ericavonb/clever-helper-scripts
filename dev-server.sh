#! /bin/bash


USAGE="Usage: dev-server [-h] [-p] [-t] [database]"

display_help() {
    echo "$USAGE"
    echo ""
    echo "Runs 'npm run-script dev-server' with the necessary environment variables."
    echo ""
    echo "dev-server -p [database]   use production API and production database if none given"
    echo "dev-server -t [database]   use the team API key"
    echo "dev-server -h              display help message"
    echo ""
    echo "[database]                 database to use, if not a number then '{database}-dev' used"
    echo "  ie 'MONGO_URL=mongodb{database}(-dev).ops.getclever.com'"
    echo "  default: localhost, ie 'MONGO_URL=localhost'"
    echo ""
}

USE_API=0
API="$API_PATH"
KEY="$CLEVER_ADMIN_API_KEY"

while getopts ":-:hptdvwr" opt; do
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
        p)
            DB="4"
            API="https://api.getclever.com"
            shift $(( OPTIND - 1 ));
            ;;
        t)
            KEY="$CLEVER_TEAM_ADMIN_API_KEY"
            shift $(( OPTIND - 1 ));
            ;;
        d)
            DEBUG=`basename "$PWD"`":*"
            shift $(( OPTIND - 1 ));
            ;;
        v)
            MY_IP="$VPN_IP"
            shift $(( OPTIND - 1 ));
            ;;
        w)
            MONGO="mongodb-write-prod.ops.clever.com"
            ;;
        r)
            MONGO="mongodb-read-prod.ops.clever.com"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "$USAGE"
            exit 1
            ;;
    esac
done

MY_IP=`curl -s http://ipecho.net/plain ; echo`
NOT_OK=`echo $MY_IP | sed 's|[0-9\.]*||'`

if [[ -n "$NOT_OK" ]]; then
    MY_IP=`curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g'`
    NOT_OK=`echo $MY_IP | sed 's|[^0-9\.]||'`

    if [[ -n "$NOT_OK" ]]; then
        echo "on vpn"
    else
        VPN_IP="50.18.217.135"

        if [ "$MY_IP" == "$VPN_IP" ] || [ "$MY_IP" == `host vpn.ops.clever.com | sed 's/vpn.ops.clever.com has address //'` ]; then
            echo "on vpn"
        else
            echo "ERROR: Please connect to the VPN before starting the dev-server."
            exit 1
        fi

    fi

fi


DB=${DB:-"$1"}

if [ -z "$MONGO" ]; then
    if [ -z "$DB" ]; then
        MONGO="localhost"
    else
        MONGO="mongodb"`echo ${DB:-'jefff'}'-dev'`".ops.clever.com"
    fi
fi

if [[ $(basename "$PWD") = "clever-api" ]]; then
    cp package.json package_0.json
    echo "not npm installing"
    PCK=`sed 's/npm install &* //' package_0.json > package.json`
fi

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

if [[ "$REPO" = "clever-api" ]]; then
    cp package_0.json package.json
    rm package_0.json
fi
