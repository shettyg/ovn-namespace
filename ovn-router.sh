usage () {
    cat << EOF
usage: ovn-router COMMAND

Commands:
  create-router NAME
  connect-switch ROUTER SWITCH SUBNET
EOF
}

create_router () {
NAME=$1
if [ -z "$NAME" ]; then
    echo "No router name given" >& 2
    exit 1
fi

ovn-nbctl create Logical_Router name=$NAME
}

connect_switch () {
ROUTER_NAME="$1"
SWITCH_NAME="$2"
SUBNET="$3"

if [ -z "$ROUTER_NAME" ] || [ -z "$SWITCH_NAME" ]; then
echo >&2 "router name or switch name not given"
exit 1
fi

if [ -z "$SUBNET" ]; then
echo >&2 "subnet not given"
exit 1
fi

x=`shuf -i 1-99  -n 1`
y=`shuf -i 1-99  -n 1`
z=`shuf -i 1-99  -n 1`

LRP_MAC="00:00:00:$x:$y:$z"

lrp_uuid=`ovn-nbctl -- --id=@lrp create Logical_Router_port name=$SWITCH_NAME \
network=$SUBNET mac=\"$LRP_MAC\" -- add Logical_Router $ROUTER_NAME ports @lrp \
-- lport-add $SWITCH_NAME rp-"$SWITCH_NAME"`

ovn-nbctl set Logical_port rp-"$SWITCH_NAME" \
type=router options:router-port=$SWITCH_NAME addresses=\"$LRP_MAC\"

}

case $1 in
    "create-router")
        shift
        create_router "$@"
        exit 0
        ;;
    "connect-switch")
        shift
        connect_switch "$@"
        exit 0
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo >&2 "$UTIL: unknown command \"$1\" (use --help for help)"
        exit 1
        ;;
esac
