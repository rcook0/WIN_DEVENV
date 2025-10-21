#requires -version 7
<#
.SYNOPSIS
  Windows 11 Dev Environment Bootstrapper
#>

param(
  [Parameter(Mandatory=$false)]
  [string[]] $Profiles = @("core","cli"),
  [switch] $EnableWSL,
  [switch] $ConfigureShell,
  [switch] $ConfigureTerminal
)

$ErrorActionPreference = "Stop"

# --- Utility imports ---
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptRoot\scripts\Utils.psm1"
. "$ScriptRoot\scripts\Install-WinGetApp.ps1"
. "$ScriptRoot\scripts\Install-FromManifest.ps1"

Write-Host "==> Windows 11 Dev Bootstrap | $(Get-Date -Format o)" -ForegroundColor Cyan
Test-Admin -WarnOnly

# Execution policy
try {
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force | Out-Null
} catch {}

# Winget sanity
Ensure-WinGet

# Optional: Enable WSL2 and VM Platform
if ($EnableWSL) {
  . "$ScriptRoot\scripts\Enable-WSL2.ps1"
}

# Install profiles
foreach ($p in $Profiles) {
  $manifestPath = Join-Path "$ScriptRoot\manifests" "$p.json"
  if (Test-Path $manifestPath) {
    Write-Host "==> Applying profile: $p"
    Install-FromManifest -ManifestPath $manifestPath
  } else {
    Write-Warning "Manifest not found: $manifestPath"
  }
}

# Configure PowerShell profile & shell ergonomics
if ($ConfigureShell) {
  . "$ScriptRoot\scripts\Configure-PowerShell.ps1"
}

# Configure Windows Terminal (best-effort)
if ($ConfigureTerminal) {
  . "$ScriptRoot\scripts\Configure-WindowsTerminal.ps1"
}

Write-Host "==> Done. Consider restarting the terminal or rebooting if WSL/features were enabled." -ForegroundColor Green
