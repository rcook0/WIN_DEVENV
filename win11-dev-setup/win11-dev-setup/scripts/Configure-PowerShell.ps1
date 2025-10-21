$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

# Ensure modules
if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
  Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber
}
if (-not (Get-Module -ListAvailable -Name posh-git)) {
  Install-Module posh-git -Scope CurrentUser -Force
}
# Oh My Posh (binary via winget)
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
  Write-Host "→ Installing Oh My Posh via winget"
  winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements --silent
}

# Nerd Font for glyphs (Cascadia Code)
winget install --id NerdFonts.CascadiaCode -e --accept-source-agreements --accept-package-agreements --silent

# FZF (winget) – used for history search
winget install --id junegunn.fzf -e --accept-source-agreements --accept-package-agreements --silent

# Write PowerShell profile
$profileContent = @'
# ---- Developer PowerShell profile ----
Import-Module PSReadLine
Import-Module posh-git

Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock { Invoke-FzfHistory }

function Invoke-FzfHistory {
  $item = (Get-Content (Get-PSReadLineOption).HistorySavePath) | fzf.exe
  if ($item) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($item) }
}

# Aliases
Set-Alias ll Get-ChildItem
Set-Alias g git

# Oh My Posh prompt
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
}
'@

$profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force
Write-Host "✓ PowerShell profile written to $PROFILE"
