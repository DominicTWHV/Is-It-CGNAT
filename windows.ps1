#fetch your public ip
$publicIP = (curl ifconfig.me).Content.Trim()

#display your ip
Write-Output "Your public IP address: $publicIP"

#traceroute with 2 hops max
$tracertOutput = tracert -h 2 $publicIP

#check if more than 1 hop
$hopCount = ($tracertOutput | Select-String -Pattern '^\s*\d+\s+').Count

if ($hopCount -gt 1) {
    Write-Output "You are behind CGNAT"
} else {
    Write-Output "You are not behind CGNAT"
}

#display traceroute output
Write-Output "Traceroute output (first 2 hops):"
$tracertOutput | Select-String -Pattern '^\s*\d+\s+' | Select-Object -First 2
