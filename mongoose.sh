#! /bin/bash


clever_db ()
{
TYPE=${1:="-read"}
ENV=${2:="prod"}
URL="mongodb$TYPE-$ENV.ops.clever.com"
return
}

DB='clever'
VPN="true"

while getopts "lwrc:" OPTION; do
    case "$OPTION" in
        "l")
            URL="localhost"
            VPN="false"
            ;;
        "w")
            clever_db "-write" "prod"
            ;;
        "r")
            clever_db "-read" "prod"
            ;;
        "c")
            DB="$OPTARG"
            shift $(( OPTIND - 1 ));
            ;;
    esac
done
shift $(( OPTIND - 1 ));


if [ $VPN == "true" ] && [ $(/Users/ericavonbuelow/dev/scripts/vpn-check.sh) == "false" ]; then
    echo "ERROR: Please connect to the VPN before connecting to that database."
    open 'https://vpn.ops.clever.com/?src=connect'
fi

if [ -z "$URL" ]; then
    clever_db "$1" "dev"
fi

CLEVER_DB="/Users/ericavonbuelow/dev/clever-db/lib/schemas.coffee"

mongoose -s $CLEVER_DB $URL/$DB
