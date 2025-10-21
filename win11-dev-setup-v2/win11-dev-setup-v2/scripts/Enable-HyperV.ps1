Write-Host "→ Enabling Hyper-V (Management + Platform)"
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart | Out-Null
Write-Host "Hyper-V enabled (reboot required)."
