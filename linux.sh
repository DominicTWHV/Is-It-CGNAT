#!/bin/bash

#function to check cmd
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#colorful echo!
color_echo() {
    case $1 in
        "green") echo -e "\e[32m$2\e[0m" ;;
        "red") echo -e "\e[31m$2\e[0m" ;;
        "yellow") echo -e "\e[33m$2\e[0m" ;;
        "blue") echo -e "\e[34m$2\e[0m" ;;
        *) echo "$2" ;;
    esac
}

#check if traceroute is installed
if ! command_exists traceroute; then
    color_echo "yellow" "Installing traceroute for you."
    sudo apt install -y traceroute

    #check if successful
    if ! command_exists traceroute; then
        color_echo "red" "Failed to install traceroute. Please install it manually!"
        exit 1
    fi
fi

#check if curl is installed
if ! command_exists curl; then
    color_echo "yellow" "Installing curl for you."
    sudo apt install -y curl

    #check if successful
    if ! command_exists curl; then
        color_echo "red" "Failed to install curl. Please install it manually!"
        exit 1
    fi
fi

#get public ip
public_ip=$(curl -s ipinfo.io/ip)

#get routing info
upstream_gateway=$(ip route | grep default | awk '{print $3}')
netmask=$(ip addr show | grep -A3 "$upstream_gateway" | grep 'inet ' | awk '{print $2}' | cut -d/ -f2)

#fetch mask
if [ "$netmask" -le 30 ]; then
    netmask="255.255.255.$((256 - (1 << (32 - netmask))))"
else
    netmask="255.255.255.255"
fi

#display info
color_echo "blue" "Your public IP: $public_ip"
color_echo "blue" "Your upstream gateway: $upstream_gateway"
color_echo "blue" "Netmask: $netmask"

#traceroute
traceroute_output=$(traceroute -m 5 $public_ip 2>/dev/null)

#check if private ips are in traceroute
if echo "$traceroute_output" | grep -Eq '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])'; then
    color_echo "red" "You may be behind CGNAT! For a definitive answer, log into your router at $upstream_gateway with the correct credentials. You should be able to find these on your router."
else
    color_echo "green" "You are not behind CGNAT"
fi

#output traceroute
color_echo "blue" "\nTraceroute output (first 5 hops):"
echo "$traceroute_output"
