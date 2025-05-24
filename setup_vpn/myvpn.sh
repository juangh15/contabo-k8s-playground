#!/bin/bash

read_init_args() {
    # Default HOST (own public ip):
    HOST=$(curl -s ifconfig.me)

    # Default OPENVPNDATA:
    OPENVPNDATA=~/openvpn-data

    # Default PASSPHRASE (random):
    PASSPHRASE=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --host) HOST="$2"; shift ;;
            --openvpn-data) OPENVPNDATA="$2"; shift ;;
            --passphrase) PASSPHRASE="$2"; shift ;;
            *) echo "Unknown Argument: $1"; exit 1 ;;
        esac
        shift
    done
    echo "ARGS: HOST=$HOST, OPENVPNDATA=$OPENVPNDATA, PASSPHRASE=$PASSPHRASE"
}



install_dependencies() {
    sudo apt-get install expect jq --no-install-recommends -y
    sudo docker pull kylemanna/openvpn
    sudo mkdir -p $OPENVPNDATA
}



generate_vpn_config() {
    sudo docker run --rm -v $OPENVPNDATA:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://$HOST
}



generate_server_ca_certs() {
    # Remove previous keys
    sudo rm -rf $OPENVPNDATA/pki      

    # Initialize expect block to generate PKI
    expect -c '''
    set timeout -1
    spawn sudo docker run --rm -it -v '$OPENVPNDATA':/etc/openvpn kylemanna/openvpn ovpn_initpki

    expect {
        "Enter New CA Key Passphrase:" 
        { send "'$PASSPHRASE'\r" }
    }
    expect {
        "Re-Enter New CA Key Passphrase:" 
        { send "'$PASSPHRASE'\r" }
    }
    expect {
        ".*" 
        { send "'$HOST'\r" }
    }
    expect {
        "Enter pass phrase for /etc/openvpn/pki/private/ca.key:" 
        { send "'$PASSPHRASE'\r" }
    }
    expect {
        "Enter pass phrase for /etc/openvpn/pki/private/ca.key:" 
        { send "'$PASSPHRASE'\r" }
    }
    expect eof
    '''
}



clean() {
    if [[ -n "$OPENVPNDATA" ]]; then
        echo "removing data: $OPENVPNDATA"
        sudo rm -rf $OPENVPNDATA
    fi
    sudo docker ps -a | grep openvpn-server | awk '{print $1}' | xargs sudo docker rm -f 2>/dev/null
}



first_run() {
    echo "First run of openvpn-server"
    sudo docker run -d --name openvpn-server --cap-add=NET_ADMIN --net=host \
    --device /dev/net/tun \
    -e PASSPHRASE="$PASSPHRASE" \
    -v $OPENVPNDATA:/etc/openvpn \
    kylemanna/openvpn
}



create_user() {
    # Validate user argument exists
    if [[ -z "$1" ]]; then
        echo "An argument is missing: You must enter the name of the user to be created"
        exit 1
    fi
    NEW_OVPN_USER=$1
    echo "Creating user: $NEW_OVPN_USER..."

    # Validate openvpn-server container exists
    if sudo docker ps -a | grep -q openvpn-server; then
        echo "starting openvpn-server"
        sudo docker start openvpn-server
    else
        echo "No openvpn-server container found. \nYou must run 'init' with args: --host --openvpn-data --passphrase"
        exit 1
    fi

    # Getting existing OPENVPNDATA directory
    OPENVPNDATA=$(sudo docker inspect openvpn-server | jq -r .[0].HostConfig.Binds[0] | cut -d ':' -f1)

    # Getting existing PASSPHRASE
    PASSPHRASE=$(sudo docker inspect openvpn-server | jq -r '.[0].Config.Env[] | select(contains("PASSPHRASE"))' | cut -d '=' -f2)

    # Remove previous user keys
    sudo rm -rf $OPENVPNDATA/pki/reqs/$NEW_OVPN_USER.req
    sudo rm -rf $OPENVPNDATA/pki/private/$NEW_OVPN_USER.key
    sudo rm -rf $OPENVPNDATA/pki/issued/$NEW_OVPN_USER.crt

    # Initialize expect block to generate CA for new user
    expect -c '''
    set timeout -1
    spawn \
    sudo docker run --rm -it \
        -v '$OPENVPNDATA':/etc/openvpn \
        kylemanna/openvpn \
        easyrsa build-client-full '$NEW_OVPN_USER' nopass

    expect {
        "Enter pass phrase for /etc/openvpn/pki/private/ca.key:" 
        { send "'$PASSPHRASE'\r" }
    }
    expect eof
    '''

    # Generate new user config
    sudo docker run --rm \
        -v $OPENVPNDATA:/etc/openvpn \
        kylemanna/openvpn \
        ovpn_getclient $NEW_OVPN_USER > $NEW_OVPN_USER.ovpn
    
    echo "New user with config path: ./$NEW_OVPN_USER.ovpn"
}



init() {
    read_init_args "$@"
    clean "$@"
    install_dependencies
    generate_vpn_config "$@"
    generate_server_ca_certs "$@"
    first_run "$@"
    create_user default_user
}



start() {
    if sudo docker ps -a | grep -q openvpn-server; then
        echo "starting openvpn-server"
        sudo docker start openvpn-server
    else
        echo "No openvpn-server container found. \nYou must run 'init' with args: --host --openvpn-data --passphrase"
        exit 1
    fi
}



stop() {
    if sudo docker ps -a | grep -q openvpn-server; then
        echo "stopping openvpn-server"
        sudo docker stop openvpn-server
    else
        echo "No openvpn-server container found. \nYou must run 'init' with args: --host --openvpn-data --passphrase"
        exit 1
    fi
}



enable_internet_browsing() {
    # Validate server exists
    if sudo docker ps -a | grep -q openvpn-server; then
        echo "starting openvpn-server"
        sudo docker start openvpn-server
    else
        echo "No openvpn-server container found. \nYou must run 'init' with args: --host --openvpn-data --passphrase"
        exit 1
    fi

    # Get subnet from existing openvpndata
    OPENVPNDATA=$(sudo docker inspect openvpn-server | jq -r .[0].HostConfig.Binds[0] | cut -d ':' -f1)
    VPN_SUBNET=$(cat $OPENVPNDATA/openvpn.conf | grep server | awk '{print $2 "/" $3}')

    # Enable packet forward:
    sudo sysctl -w net.ipv4.ip_forward=1

    # Masking VPN traffic towards internet:
    sudo iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o eth0 -j MASQUERADE

    # Allow related and stablished connections:
    sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Allow packets forwarding from VPN:
    sudo iptables -A FORWARD -s $VPN_SUBNET -i tun0 -o eth0 -j ACCEPT
}



disable_internet_browsing() {
    # Validate server exists
    if sudo docker ps -a | grep -q openvpn-server; then
        echo "starting openvpn-server"
        sudo docker start openvpn-server
    else
        echo "No openvpn-server container found. \nYou must run 'init' with args: --host --openvpn-data --passphrase"
        exit 1
    fi

    # Get subnet from existing openvpndata
    OPENVPNDATA=$(sudo docker inspect openvpn-server | jq -r .[0].HostConfig.Binds[0] | cut -d ':' -f1)
    VPN_SUBNET=$(cat $OPENVPNDATA/openvpn.conf | grep server | awk '{print $2 "/" $3}')

    # Disable packet forward:
    sudo sysctl -w net.ipv4.ip_forward=0

    # Remove previous rule: Masking VPN traffic towards internet:
    sudo iptables -t nat -D POSTROUTING -s $VPN_SUBNET -o eth0 -j MASQUERADE

    # Remove previous rules: Allow related and stablished connections:
    sudo iptables -D INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Remove previous rule: Allow packets forwarding from VPN:
    sudo iptables -D FORWARD -s $VPN_SUBNET -i tun0 -o eth0 -j ACCEPT
}



# Parse functions
if declare -f "$1" > /dev/null; then
  FUNC="$1"
  shift
  $FUNC "$@"
else
  echo "Invalid function: $1"
  echo "Available functions:"
  declare -F | awk '{print $3}'
  exit 1
fi