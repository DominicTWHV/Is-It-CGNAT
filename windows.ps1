try {
    $public_ipv4 = (Invoke-RestMethod -Uri "http://ifconfig.me/ip").Trim()
    Write-Host "[INFO] Public IPv4: $public_ipv4" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] Failed to retrieve public IPv4 address. Ensure you are connected to the internet." -ForegroundColor Red
    $public_ipv4 = $null
}

try {
    $public_ipv6 = (Invoke-RestMethod -Uri "https://v6.ipinfo.io/ip").Trim()
    Write-Host "[INFO] Public IPv6: $public_ipv6" -ForegroundColor Cyan
} catch {
    Write-Host "[WARNING] No public IPv6 detected. You may not have an IPv6 address. That is fine as long as you don't plan to run your server on IPv6." -ForegroundColor Yellow
    $public_ipv6 = $null
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
        $body = @{
            host  = $public_ip
            ports = @($port)
        } | ConvertTo-Json
        $port_status = Invoke-RestMethod -Uri "https://portchecker.io/api/query" -Method Post -Body $body -ContentType 'application/json'
        $port_check = $port_status.check | Where-Object { $_.port -eq $port }
        if ($port_check -and $port_check.status) {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Host "[ERROR] Error checking port $port. Ensure you have internet access." -ForegroundColor Red
        return $false
    }
}

function Check-CGNAT {
    param (
        [string]$public_ip,
        [string]$address_family,
        [string]$gateway
    )
    
    try {
        Write-Host "[INFO] Running traceroute for $address_family..." -ForegroundColor Yellow
        $traceroute_output = tracert -h 2 $public_ip 2>&1
        Write-Host $traceroute_output
        Write-Host "[INFO] --------------------------------------" -ForegroundColor Yellow
    } catch {
        Write-Host "[ERROR] Error during traceroute for $address_family. Check your network settings." -ForegroundColor Red
    }
    $cgnat_ranges = '100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])|198\\.18\\.|198\\.51\\.100\\.|203\\.0\\.113\\.'
    $internal_ip_count = 0
    foreach ($line in $traceroute_output) {
        if ($line -match $cgnat_ranges) {
            $internal_ip_count++
            if ($internal_ip_count -gt 1) {
                Write-Host "[INFO] CGNAT detected! A second internal IP was found in the traceroute." -ForegroundColor Red
                return $true
            }
        }
    }
    Write-Host "[INFO] No CGNAT detected. Only one or no internal IPs found." -ForegroundColor Green
    return $false
}

Write-Host "Please now confirm your Minecraft is turned ON and running properly."
$port = Read-Host "Which port does your Minecraft server run on? (e.g., 25565)"

if ($public_ipv4) {
    $gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
    
    Write-Host "[INFO] Default Gateway: $gateway" -ForegroundColor Cyan
    
    $is_cgnat = Check-CGNAT -public_ip $public_ipv4 -address_family "IPv4" -gateway $gateway
    $is_port_open = Check-Port -public_ip $public_ipv4 -port $port
    if ($is_cgnat) {
        Write-Host "[WARNING] You may be behind CGNAT for IPv4! Log into your router at ${gateway} with the correct credentials." -ForegroundColor Red
    } elseif (-not $is_port_open) {
        Write-Host "[ERROR] You should not be behind CGNAT for IPv4, but your TCP port $port is not open." -ForegroundColor Yellow
    } else {
        Write-Host "[SUCCESS] You are not behind CGNAT for IPv4 and TCP port $port is visible. Your server should not be having connection issues." -ForegroundColor Green
    }
} elseif ($public_ipv6) {
    $gateway = (Get-NetRoute -AddressFamily IPv6 | Where-Object { $_.DestinationPrefix -eq "::/0" }).NextHop
    $subnet_mask = (Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }).PrefixLength
    
    Write-Host "[INFO] Default Gateway (IPv6): $gateway" -ForegroundColor Cyan
    
    $is_cgnat = Check-CGNAT -public_ip $public_ipv6 -address_family "IPv6" -gateway $gateway
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
