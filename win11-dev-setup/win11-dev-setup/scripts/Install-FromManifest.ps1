param(
  [Parameter(Mandatory=$true)][string] $ManifestPath
)

. "$PSScriptRoot\Utils.psm1"

if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
$manifest = Get-Content $ManifestPath | ConvertFrom-Json

# winget packages
foreach ($pkg in $manifest.winget) {
  $id = if ($pkg.PSObject.Properties.Name -contains 'id') { $pkg.id } else { $pkg }
  & "$PSScriptRoot\Install-WinGetApp.ps1" -Id $id
}

# pipx tools
if ($manifest.pipx) {
  # ensure pipx
  if (-not (Get-Command pipx -ErrorAction SilentlyContinue)) {
    Write-Host "→ Installing pipx (Python required)"
    python -m pip install --user pipx
    python -m pipx ensurepath
  }
  foreach ($tool in $manifest.pipx) {
    Write-Host "→ pipx install $tool"
    Try-Exec "pipx install $tool" | Out-Null
  }
}

# npm global (Node LTS required)
if ($manifest.npm_global) {
  Try-Exec "corepack enable" | Out-Null
  foreach ($g in $manifest.npm_global) {
    Write-Host "→ npm i -g $g"
    Try-Exec "npm i -g $g" | Out-Null
  }
}

# dotnet tools
if ($manifest.dotnet_tools) {
  foreach ($t in $manifest.dotnet_tools) {
    Write-Host "→ dotnet tool update -g $t"
    Try-Exec "dotnet tool update -g $t" | Out-Null
  }
}

# cargo installs (requires Rust)
if ($manifest.cargo) {
  foreach ($c in $manifest.cargo) {
    Write-Host "→ cargo install $c"
    Try-Exec "cargo install $c" | Out-Null
  }
}
