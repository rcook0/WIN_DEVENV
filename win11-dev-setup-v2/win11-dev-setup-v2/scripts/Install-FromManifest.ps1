param(
  [Parameter(Mandatory=$true)][string] $ManifestPath
)

. "$PSScriptRoot\Utils.psm1"

if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
$manifest = Get-Content $ManifestPath | ConvertFrom-Json

foreach ($pkg in $manifest.winget) {
  if ($pkg.PSObject.Properties.Name -contains 'id') {
    $id = $pkg.id
    $override = $null
    if ($pkg.PSObject.Properties.Name -contains 'override') { $override = $pkg.override }
    & "$PSScriptRoot\Install-WinGetApp.ps1" -Id $id -OverrideArgs $override
  } else {
    & "$PSScriptRoot\Install-WinGetApp.ps1" -Id $pkg
  }
}

if ($manifest.pipx) {
  if (-not (Get-Command pipx -ErrorAction SilentlyContinue)) {
    Write-Host "→ Installing pipx (Python required)"
    python -m pip install --user pipx
    python -m pipx ensurepath
  }
  foreach ($tool in $manifest.pipx) { Try-Exec "pipx install $tool" | Out-Null }
}

if ($manifest.npm_global) {
  Try-Exec "corepack enable" | Out-Null
  foreach ($g in $manifest.npm_global) { Try-Exec "npm i -g $g" | Out-Null }
}

if ($manifest.dotnet_tools) {
  foreach ($t in $manifest.dotnet_tools) { Try-Exec "dotnet tool update -g $t" | Out-Null }
}

if ($manifest.cargo) {
  foreach ($c in $manifest.cargo) { Try-Exec "cargo install $c" | Out-Null }
}
