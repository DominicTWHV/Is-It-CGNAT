#!/bin/bash

#obtain public ip of yours
public_ip=$(curl -s ifconfig.me)

#check traceroute with 2 hops max
hop_count=$(traceroute -m 2 $public_ip 2>/dev/null | grep -E '^\s*[0-9]+\s+' | wc -l)

#show public ip
echo "Your public IP address: $public_ip"

# Check if the user is behind CGNAT by checking if the traceroute shows 2 or more hops
if [ $hop_count -ge 2 ]; then
    echo "You are behind CGNAT"
else
    echo "You are not behind CGNAT"
fi

#output traceroute
echo "Traceroute output (first 2 hops):"
traceroute -m 2 $public_ip 2>/dev/null
