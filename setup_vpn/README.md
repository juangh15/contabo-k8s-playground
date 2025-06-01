## Connect to the instance
Connect a user with root privileges. In this case, mainuser
```
export ipAddress=$(cntb get instances --output json | jq -r '.[] | select(.displayName=="MainVPS") | ."ipv4"')
ssh-keygen -R $ipAddress
ssh -i ~/.ssh/playground_ssh_private.key mainuser@$ipAddress
```

## Requirements on the instance
### 1. Install packages:
'Expect' package is required to auto-fill prompts of some OpenVPN processes:
```
sudo apt update && sudo apt install expect -y
```

### 2. Load your variables:
Run the command replacing each variable if you want
```
CONTABO_IP=$(curl -s ifconfig.me)   # OPTIONAL: Replace with a custom domain e.g: CONTABO_IP='mydomain.net'
OPENVPNDATA=~/openvpn-data          # Replace with a custom openvpn-data path
PASSPHRASE="123AbC456cDf78gHI9"     # Replace with a custom Passphrase
```

### 3. Pull openvpn image and create local data directory:
Run the following command
```
sudo docker pull kylemanna/openvpn
mkdir -p $OPENVPNDATA
```

### 4. Generate initial OpenVPN config
Run the following command
```
sudo docker run --rm -v $OPENVPNDATA:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://$CONTABO_IP
```

### 5. Generate CA certificates of OpenVPN Server
Run the following command. Expect blocks will auto-fill input commands.
```
# Remove previous keys
sudo rm -rf $OPENVPNDATA/pki      

# Initialize expect block
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
    { send "'$CONTABO_IP'\r" }
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
```

### 6. Remove previous OpenVPN Server containers
```
sudo docker ps -a | grep openvpn-server | awk '{print $1}' | xargs sudo docker rm -f 2>/dev/null
```

### 7. Run the OpenVPN Server
```
sudo docker run -d --name openvpn-server --cap-add=NET_ADMIN --net=host \
  --device /dev/net/tun \
  -v $OPENVPNDATA:/etc/openvpn \
  kylemanna/openvpn
```

### 8. Validate logs of running OpenVPN Server
```
sudo docker ps -a | grep openvpn-server | awk '{print $1}' | xargs sudo docker container logs 2>/dev/null
```

### 9. Generate a new **guest_user** certificates
```
NEW_OVPN_USER='guest_user'   # OPTIONAL: Replace with a custom user name if you want

# Remove previous user keys
sudo rm -rf $OPENVPNDATA/pki/reqs/$NEW_OVPN_USER.req
sudo rm -rf $OPENVPNDATA/pki/private/$NEW_OVPN_USER.key
sudo rm -rf $OPENVPNDATA/pki/issued/$NEW_OVPN_USER.crt

# Initialize expect block
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
```

### 10. Generate **.ovpn** file for **guest_user**
```
sudo docker run --rm \
    -v $OPENVPNDATA:/etc/openvpn \
    kylemanna/openvpn \
    ovpn_getclient $NEW_OVPN_USER > $NEW_OVPN_USER.ovpn
```

### 11. OPTIONAL: Routing traffic to Internet
Add these rules only if you want to allow users to access internet from your VPN.  
Copy the following command and run it inside the server.
```
# ROUTING RULES
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
```

### 12. OPTIONAL: Routing traffic to Internet
Add these rules only if you want to restrict the ports on the server.  
Copy the following command and run it inside the server.
```
# Enable outter traffic
sudo iptables -I INPUT 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# SSH:
sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
# Custom Web:
sudo iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
# HTTPS:
sudo iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
# OpenVPN:
sudo iptables -A INPUT -i eth0 -p udp --dport 1194 -j ACCEPT
# DNS:
sudo iptables -A INPUT -i eth0 -p udp --dport 53 -j ACCEPT
# DNS Loopback:
sudo iptables -A INPUT -i lo -p udp --dport 53 -j ACCEPT
# UDP VPN:
sudo iptables -A INPUT -i eth0 -p udp --dport 8388 -j ACCEPT
# UDP BADVPN:
sudo iptables -A INPUT -i eth0 -p udp --dport 7300 -j ACCEPT
# Outer traffic:
sudo iptables -A OUTPUT -o eth0 -j ACCEPT
# Deny Not specified traffic:
sudo iptables -A INPUT -j DROP
```

### 13. OPTIONAL: Make Traffic filtering permanent
The previous rules are ephemeral. Once a server restart occurs, all rules are wiped.  
You can make them permanent with the following commands:  
```
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
```

### 14. Exit from server to continue locally
```
exit
```

## Pull the **.ovpn** file for **guest_user**
Replace the variables and run the following command:
```
# Variables: --------------------------------------------------------------
CONTABO_IP=$(cntb get instances --output json | jq -r '.[] | select(.displayName=="MainVPS") | ."ipv4"')
NEW_OVPN_USER='guest_user'
SSH_USER='mainuser'
SSH_KEY_PATH='~/.ssh/playground_ssh_private.key'
# -------------------------------------------------------------------------

ssh-keygen -R $CONTABO_IP
ssh-keyscan -H $CONTABO_IP >> ~/.ssh/known_hosts
ssh -i $SSH_KEY_PATH $SSH_USER@$CONTABO_IP \
    "cat ~/$NEW_OVPN_USER.ovpn" \
    > ./$NEW_OVPN_USER.ovpn
```

## Instructions to connect:
1. Go to: https://openvpn.net/client/  
2. Install the OpenVPN client compatible with the device that you want to connect to the VPN. 
2. Copy the .ovpn file previously generated to the device
3. Open OpenVPN
4. Select "Upload File"
5. Search and select your ".ovpn" file
6. Connect

## Other debugging commands:
You can use some commands to debug, and try custom options:
```
# Restart the instance:
cntb restart instance $instanceId

# Manage container lifecycle:
sudo docker start openvpn
sudo docker stop openvpn

# List access rules with their numbers:
sudo iptables -L -v -n --line-numbers

# Remove custom access rule (replace 14 with the custom rule number)
sudo iptables -D INPUT 14
```