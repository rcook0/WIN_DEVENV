param(
  [Parameter(Mandatory=$true)][string] $Id,
  [string] $OverrideArgs
)

# Already installed?
$installed = winget list --exact --id $Id 2>$null | Select-String $Id
if ($installed) {
  Write-Host "✓ $Id already installed."
  return
}

# Build command
if ([string]::IsNullOrWhiteSpace($OverrideArgs)) {
  Write-Host "→ Installing $Id via winget..."
  $cmd = "winget install --id `"$Id`" --accept-source-agreements --accept-package-agreements --silent --exact"
} else {
  Write-Host "→ Installing $Id via winget with overrides..."
  $cmd = "winget install --id `"$Id`" --accept-source-agreements --accept-package-agreements --exact --override `"$OverrideArgs`""
}

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile","-Command",$cmd -Wait -PassThru -WindowStyle Hidden

if ($proc.ExitCode -eq 0) { Write-Host "✓ $Id installed." }
else { Write-Warning "$Id install returned exit $($proc.ExitCode). You may retry manually: $cmd" }
