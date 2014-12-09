#! /bin/bash

DB='clever'

VPN="true"

while getopts ":l:wrc:" OPTION; do
    case "$OPTION" in
        "l")
            if eval [[ "$"$(($OPTIND-1))"" = "$OPTARG" ]]; then
                URL="localhost"
                ((--OPTIND))
            else
                URL="--port $OPTARG localhost"
            fi
            VPN="false"
            ;;
        "w")
            URL="mongodb-write-prod.ops.clever.com"
            ;;
        "r")
            URL="mongodb-read-prod.ops.clever.com"
            ;;
        "c")
            DB="$OPTARG"
            ;;
        ":")
            if [[ "$OPTARG" == "l" ]]; then
                VPN="false"
                URL="localhost"
            else
                echo "no database given with -c option." >&2
            fi
            ;;
        "?")
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

shift $(( OPTIND - 1 ));


if [ $VPN == "true" ] && [ $(/Users/ericavonbuelow/dev/scripts/vpn-check.sh) == "false" ]; then
    echo "ERROR: Please connect to the VPN before connecting to that database."
    exit 0
fi


mongo ${URL:-"mongodb"`echo ${1:-'jefff'}'-dev'`".ops.clever.com"}/$DB
