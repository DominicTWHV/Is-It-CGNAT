try {
    $public_ipv4 = (Invoke-RestMethod -Uri "http://ifconfig.me/ip").Trim()
    $public_ipv6 = (Invoke-RestMethod -Uri "https://v6.ipinfo.io/").Trim()
    Write-Host "[INFO] Public IPv4: $public_ipv4" -ForegroundColor Cyan
    Write-Host "[INFO] Public IPv6: $public_ipv6" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] Error executing checks. Please check that you are connected to the internet." -ForegroundColor Red
    exit 1
}

$gateway = $null
$subnet_mask = $null
$traceroute_output = $null

function Check-Port {
    param (
        [string]$public_ip,
        [int]$port
    )
    
    try {
        $port_status = Invoke-RestMethod -Uri "https://api.portchecktool.com/check?ip=$public_ip&port=$port" -Method Get
        return $port_status.open
    } catch {
        Write-Host "[ERROR] Error checking port $port. Ensure you have internet access." -ForegroundColor Red
    }
}

function Check-CGNAT {
    param (
        [string]$public_ip,
        [string]$address_family,
        [string]$gateway,
        [string]$subnet_mask
    )
    
    try {
        Write-Host "[INFO] Running traceroute for $address_family..." -ForegroundColor Yellow
        $traceroute_output = $(tracert -h 2 $public_ip 2>&1)
        echo $traceroute_output
    } catch {
        Write-Host "[ERROR] Error during traceroute for $address_family. Check your network settings." -ForegroundColor Red
        exit 1
    }

    $cgnat_ranges = '10\\.|172\\.(1[6-9]|2[0-9]|3[01])|192\\.168|100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])|fc00|fd00|::/128|::1'
    return ($traceroute_output -match $cgnat_ranges)
}

Write-Host "Please confirm your Minecraft server is up and running before pressing enter to proceed." -ForegroundColor Green
$null = Read-Host

$port = Read-Host "Which port does your Minecraft server run on? (e.g., 25565)"

if ($public_ipv4) {
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    $subnet_mask = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }).PrefixLength
    
    Write-Host "[INFO] Default Gateway: $gateway" -ForegroundColor Cyan
    Write-Host "[INFO] Subnet Mask: $subnet_mask" -ForegroundColor Cyan
    
    $is_cgnat = Check-CGNAT -public_ip $public_ipv4 -address_family "IPv4" -gateway $gateway -subnet_mask $subnet_mask
    $is_port_open = Check-Port -public_ip $public_ipv4 -port $port

    if ($is_cgnat) {
        Write-Host "[WARNING] You may be behind CGNAT for IPv4! Log into your router at ${gateway} with the correct credentials." -ForegroundColor Yellow
    } elseif (-not $is_port_open) {
        Write-Host "[ERROR] You should not be behind CGNAT for IPv4, but your TCP port $port is not open." -ForegroundColor Red
    } else {
        Write-Host "[SUCCESS] You are not behind CGNAT for IPv4 and TCP port $port is visible. Your server should not be having connection issues." -ForegroundColor Green
    }
} elseif ($public_ipv6) {
    $gateway = (Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.DestinationPrefix -eq "::/0" }).NextHop
    $subnet_mask = (Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }).PrefixLength
    
    Write-Host "[INFO] Default Gateway (IPv6): $gateway" -ForegroundColor Cyan
    Write-Host "[INFO] Subnet Mask (IPv6): $subnet_mask" -ForegroundColor Cyan
    
    $is_cgnat = Check-CGNAT -public_ip $public_ipv6 -address_family "IPv6" -gateway $gateway -subnet_mask $subnet_mask
    $is_port_open = Check-Port -public_ip $public_ipv6 -port $port

    if ($is_cgnat) {
        Write-Host "[WARNING] You may be behind CGNAT for IPv6! Log into your router at ${gateway} with the correct credentials." -ForegroundColor Yellow
    } elseif (-not $is_port_open) {
        Write-Host "[ERROR] You should not be behind CGNAT for IPv6, but your TCP port $port is not open." -ForegroundColor Red
    } else {
        Write-Host "[SUCCESS] You are not behind CGNAT for IPv6 and TCP port $port is visible. Your server should not be having connection issues." -ForegroundColor Green
    }
} else {
    Write-Host "[ERROR] Error executing checks. Please check that you are connected to the internet." -ForegroundColor Red
}
