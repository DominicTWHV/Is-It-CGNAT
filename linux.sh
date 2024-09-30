#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#check if traceroute is installed
if ! command_exists traceroute; then
    echo "Installing traceroute for you."
    sudo apt install -y traceroute

    #check if successful
    if ! command_exists traceroute; then
        echo "Failed to install traceroute. Please install it manually!"
        exit 1
    fi
fi

#obtain public ip of yours
public_ip=$(curl -s ifconfig.me)

#get routing info
upstream_gateway=$(ip route | grep default | awk '{print $3}')
netmask=$(ifconfig | grep -A1 "$upstream_gateway" | grep 'Mask' | awk '{print $4}' | cut -d: -f2)

#display info
echo "Your public IP: $public_ip"
echo "Your upstream gateway: $upstream_gateway"
echo "Netmask: $netmask"

#try traceroute check
traceroute_output=$(traceroute -m 2 $public_ip 2>/dev/null)

# check if private ips are in traceroute (indicating CGNAT)
if echo "$traceroute_output" | grep -Eq '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])'; then
    echo "You may be behind CGNAT! For a definitive answer, log into your router at $upstream_gateway with the correct credentials. You should be able to find these on your router."
else
    echo "You are not behind CGNAT"
fi

echo -e "\nTraceroute output (first 2 hops):"
echo "$traceroute_output"
