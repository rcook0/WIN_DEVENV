#requires -version 7
param(
  [Parameter(Mandatory=$false)]
  [string[]] $Profiles = @("core","cli"),
  [switch] $EnableWSL,
  [switch] $ConfigureShell,
  [switch] $ConfigureTerminal
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptRoot\scripts\Utils.psm1"
. "$ScriptRoot\scripts\Install-WinGetApp.ps1"
. "$ScriptRoot\scripts\Install-FromManifest.ps1"

Write-Host "==> Windows 11 Dev Bootstrap | $(Get-Date -Format o)" -ForegroundColor Cyan
Test-Admin -WarnOnly

try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force | Out-Null } catch {}

Ensure-WinGet

if ($EnableWSL) { . "$ScriptRoot\scripts\Enable-WSL2.ps1" }

foreach ($p in $Profiles) {
  $manifestPath = Join-Path "$ScriptRoot\manifests" "$p.json"
  if (Test-Path $manifestPath) {
    Write-Host "==> Applying profile: $p"
    Install-FromManifest -ManifestPath $manifestPath
  } else {
    Write-Warning "Manifest not found: $manifestPath"
  }
}

if ($ConfigureShell)   { . "$ScriptRoot\scripts\Configure-PowerShell.ps1" }
if ($ConfigureTerminal){ . "$ScriptRoot\scripts\Configure-WindowsTerminal.ps1" }

Write-Host "==> Done. Restart terminal; reboot if features/WSL/Hyper-V were enabled." -ForegroundColor Green
