#obtain your public ip
$public_ip = (Invoke-RestMethod -Uri "http://ifconfig.me").Trim()

#get routing info
$gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop
$netmask = (Get-NetIPAddress -InterfaceAlias (Get-NetIPInterface -AddressFamily IPv4 | Select-Object -First 1).InterfaceAlias | Where-Object { $_.IPAddress -eq $gateway }).PrefixLength

function Get-SubnetMask {
    param (
        [int]$prefixLength
    )
    
    $mask = 0xFFFFFFFF -band (-1 -shl (32 - $prefixLength))
    return [System.Net.IPAddress]::Parse(($mask -bor 0).ToString().Split(' ')[-1])
}

$subnetMask = Get-SubnetMask -prefixLength $netmask

#display info
Write-Host "Your public IP: $public_ip"
Write-Host "Your upstream gateway: $gateway"
Write-Host "Netmask: $subnetMask"

#try traceroute(cert)
$traceroute_output = tracert -h 2 $public_ip 2>$null

#check if private ip ranges exist
if ($traceroute_output -match '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])') {
    Write-Host "You may be behind CGNAT! For a definitive answer, log into your router at $gateway with the correct credentials. You should be able to find these on your router."
} else {
    Write-Host "You are not behind CGNAT"
}

Write-Host "`nTraceroute output (first 2 hops):"
Write-Host $traceroute_output
