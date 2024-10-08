#obtain public ip
try {
    $public_ipv4 = (Invoke-RestMethod -Uri "http://ifconfig.me/ip").Trim()
    $public_ipv6 = (Invoke-RestMethod -Uri "http://ifconfig.co/ip").Trim()
} catch {
    Write-Host "Error obtaining public IP. Check your internet connection."
    exit
}

#init vars
$gateway = $null
$subnet_mask = $null
$traceroute_output = $null

#determine which code to use
if ($public_ipv4) {
    #if v4
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    
    $networkAdapter = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" }

    if ($networkAdapter.Count -gt 1) {
        $networkAdapter = $networkAdapter[0]
    }
    
    $subnet_mask = $networkAdapter.PrefixLength
    
    #cidr to 0.0.0.0
    function Convert-CidrToNetmask {
        param ([int]$cidr)
        
        #calc mask by bit shifting
        $mask = [math]::Pow(2, 32) - [math]::Pow(2, 32 - $cidr)
        $octets = for ($i = 3; $i -ge 0; $i--) {
            (($mask -band ([math]::Pow(256, $i))) -shr (8 * $i))
        }
        return ($octets -join '.')
    }

    $subnet_mask = Convert-CidrToNetmask $subnet_mask
    
    #traceroute for v4
    try {
        $traceroute_output = tracert -h 2 $public_ipv4 2>$null
    } catch {
        Write-Host "Error during traceroute for IPv4. Check your network settings."
        exit
    }

    #check traceroute ranges for v4
    if ($traceroute_output -match '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])') {
        Write-Host "You may be behind CGNAT for IPv4! Log into your router at $gateway with the correct credentials."
    } else {
        Write-Host "You are not behind CGNAT for IPv4."
    }

    #display v4 results
    Write-Host "Your public IPv4: $public_ipv4"
    Write-Host "Your upstream gateway (IPv4): $gateway"
    Write-Host "Netmask (IPv4): $subnet_mask"
    Write-Host "`nTraceroute output (first 2 hops for IPv4):"
    Write-Host $traceroute_output

} elseif ($public_ipv6) {
    #use v6 if v4 doesnt exist
    $gateway = (Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.DestinationPrefix -eq "::/0" }).NextHop

    $networkAdapter_v6 = Get-NetIPAddress | Where-Object {
        $_.AddressFamily -eq "IPv6" -and $_.PrefixOrigin -ne "WellKnown" -and $_.AddressOrigin -eq "Dhcp"
    }
    
    if ($null -eq $networkAdapter_v6) {
        Write-Output "Error: No IPv6 Addr Found."
    } elseif ($networkAdapter_v6.Count -gt 1) {
        $networkAdapter_v6 = $networkAdapter_v6[0]
    }
    
    #use prefix length instead of converting
    $subnet_mask = $networkAdapter_v6.PrefixLength
    
    #traceroute with v6
    try {
        $traceroute_output = tracert -h 2 -d $public_ipv6 2>$null
    } catch {
        Write-Host "Error during traceroute for IPv6. Check your network settings."
        exit
    }

    #check cgnat ranges with v6
    if ($traceroute_output -match 'fc00|fd00|::/128|::1') {
        Write-Host "You may be behind CGNAT for IPv6! Log into your router at $gateway with the correct credentials."
    } else {
        Write-Host "You are not behind CGNAT for IPv6."
    }

    #display info for v6
    Write-Host "Your public IPv6: $public_ipv6"
    Write-Host "Your upstream gateway (IPv6): $gateway"
    Write-Host "Netmask (IPv6): $subnet_mask (CIDR)"
    Write-Host "`nTraceroute output (first 2 hops for IPv6):"
    Write-Host $traceroute_output

} else {
    Write-Host "No public IP address found. Check your internet connection."
}
