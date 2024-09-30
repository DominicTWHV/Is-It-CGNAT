# Quickly check if you are behind CGNAT!


**Disclaimer:**

Using traceroute is the fastest, however not the most accurate approach to this. If the script may falsly report positives when too many hops are performed (if you are using a VPS like OCI or AWS). Always check with your router's WAN port to confirm.

**Linux Users:**

Run the following in your terminal:

```bash
curl -s https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/linux.sh | bash
```

**Windows Users:**

Run the following in PowerShell:

```shell
curl -o windows.ps1 https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/windows.ps1; ./windows.ps1
Remove-Item -Path "windows.ps1"
```

And if you encounter an issue running the script, try the following:

```shell
Set-ExecutionPolicy Bypass -Scope Process
```

Then try the above command once again.

