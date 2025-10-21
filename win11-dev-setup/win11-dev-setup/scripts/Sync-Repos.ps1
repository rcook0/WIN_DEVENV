param(
  [string] $ListPath = "./repos.txt"
)

if (-not (Test-Path $ListPath)) { throw "repos list not found at $ListPath" }

function Ensure-Dir { param($p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

Get-Content $ListPath | ForEach-Object {
  if (-not $_ -or $_.StartsWith("#")) { return }
  $parts = $_.Split(";",2)
  $url = $parts[0].Trim()
  $dst = $parts[1].Trim()
  Ensure-Dir (Split-Path -Parent $dst)
  if (Test-Path (Join-Path $dst ".git")) {
    Write-Host "→ Pull: $dst"
    git -C $dst pull --rebase --autostash
  } elseif (Test-Path $dst) {
    Write-Host "→ Directory exists but not a git repo: $dst (skipping)"
  } else {
    Write-Host "→ Clone: $url -> $dst"
    git clone $url $dst
  }
}
