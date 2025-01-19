# Obtain public IP
try {
    $public_ipv4 = (Invoke-RestMethod -Uri "http://ifconfig.me/ip").Trim()
    $public_ipv6 = (Invoke-RestMethod -Uri "http://ifconfig.co/ip").Trim()
} catch {
    Write-Host "Error obtaining public IP. Check your internet connection."
    exit 1
}

# Initialize variables
$gateway = $null
$subnet_mask = $null
$traceroute_output = $null

# Function to perform traceroute and check CGNAT
function Check-CGNAT {
    param (
        [string]$public_ip,
        [string]$address_family,
        [string]$gateway,
        [string]$subnet_mask
    )

    try {
        $traceroute_output = tracert -h 2 $public_ip 2>$null
    } catch {
        Write-Host "Error during traceroute for $address_family. Check your network settings."
        exit 1
    }

    $cgnat_ranges = '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])|fc00|fd00|::/128|::1'
    if ($traceroute_output -match $cgnat_ranges) {
        Write-Host "You may be behind CGNAT for ${address_family}! Log into your router at ${gateway} with the correct credentials."
    } else {
        Write-Host "You are not behind CGNAT for ${address_family}."
    }

    # Display results
    Write-Host "Your public ${address_family}: ${public_ip}"
    Write-Host "Your upstream gateway (${address_family}): ${gateway}"
    Write-Host "Netmask (${address_family}): ${subnet_mask}"
    Write-Host "`nTraceroute output (first 2 hops for ${address_family}):"
    Write-Host $traceroute_output
}

# Determine which code to use
if ($public_ipv4) {
    # IPv4
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    Check-CGNAT -public_ip $public_ipv4 -address_family "IPv4" -gateway $gateway -subnet_mask $subnet_mask
} elseif ($public_ipv6) {
    # IPv6
    $gateway = (Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.DestinationPrefix -eq "::/0" }).NextHop
    
    $networkAdapter_v6 = Get-NetIPAddress | Where-Object {
        $_.AddressFamily -eq "IPv6" -and $_.PrefixOrigin -ne "WellKnown" -and $_.AddressOrigin -eq "Dhcp"
    }
    
    if ($null -eq $networkAdapter_v6) {
        Write-Host "Error: No IPv6 Addr Found."
        exit 1
    } elseif ($networkAdapter_v6.Count -gt 1) {
        $networkAdapter_v6 = $networkAdapter_v6[0]
    }
    
    $subnet_mask = $networkAdapter_v6.PrefixLength
    Check-CGNAT -public_ip $public_ipv6 -address_family "IPv6" -gateway $gateway -subnet_mask $subnet_mask
} else {
    Write-Host "No public IP address found. Check your internet connection."
}
