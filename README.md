# Quickly check if you are behind CGNAT!

**Linux Users:**

Run the following in your terminal:

```bash
curl -s https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/linux.sh | bash
```

**Windows Users:**

Run the following in PowerShell:

```shell
curl -o check_cgnat.ps1 https://raw.githubusercontent.com/DominicTWHV/Is-It-CGNAT/refs/heads/main/windows.ps1; ./windows.ps1
```

And if you encounter an issue running the script, try the following:

```shell
Set-ExecutionPolicy Bypass -Scope Process
```

Then try the above command once again.

