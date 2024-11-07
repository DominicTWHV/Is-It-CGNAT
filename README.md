# Quickly check if you are behind CGNAT!


**Disclaimer:**

Using traceroute is the fastest, however not the most accurate approach to this. If the script may falsly report positives/negatives. If unsure, check your router's WAN interface to confirm it.

The `Netmask` output may be slightly broken. However that does not affect the functions.

The functionality of the script is still being tested. Feel free to open a PR/issue if improvements can be made.

**Linux Users:**

Run the following in your terminal:

```bash
curl -s https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/linux.sh | bash
```

**Windows Users:**

Run the following in PowerShell:

```shell
iex (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/windows.ps1")
```

And if you encounter an issue running the script, try the following:

```shell
Set-ExecutionPolicy Bypass -Scope Process
```

Then try the above command once again.

