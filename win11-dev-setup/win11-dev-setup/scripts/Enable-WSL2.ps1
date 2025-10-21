Write-Host "→ Enabling WSL and VM Platform (no reboot yet)"
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

Write-Host "→ Setting WSL 2 as default"
wsl --set-default-version 2

Write-Host "Tip: Reboot, then run:  wsl --install -d Ubuntu-24.04"
