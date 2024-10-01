#obtain your public IP
try {
    $public_ip = (Invoke-RestMethod -Uri "http://ifconfig.me").Trim()
} catch {
    Write-Host "Error obtaining public IP. Check your internet connection."
    exit
}

#get routing info
$gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq "0.0.0.0/0" }).NextHop

#get subnet mask from ipconfig
$ipconfig_output = ipconfig
$subnet_mask = ($ipconfig_output | Select-String -Pattern "Subnet Mask" | ForEach-Object { $_.ToString().Trim().Split(':')[1].Trim() })[0]

#display info
Write-Host "Your public IP: $public_ip"
Write-Host "Your upstream gateway: $gateway"
Write-Host "Netmask: $subnet_mask"

#try traceroute (limited hops)
try {
    $traceroute_output = tracert -h 2 $public_ip 2>$null
} catch {
    Write-Host "Error during traceroute. Check your network settings."
    exit
}

#check if private IP ranges exist
if ($traceroute_output -match '10\.|172\.(1[6-9]|2[0-9]|3[01])|192\.168|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])') {
    Write-Host "You may be behind CGNAT! For a definitive answer, log into your router at $gateway with the correct credentials. You should be able to find these on your router."
} else {
    Write-Host "You are not behind CGNAT."
}

Write-Host "`nTraceroute output (first 2 hops):"
Write-Host $traceroute_output
