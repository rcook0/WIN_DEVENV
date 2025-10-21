$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

if (-not (Get-Module -ListAvailable -Name PSReadLine)) { Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber }
if (-not (Get-Module -ListAvailable -Name posh-git)) { Install-Module posh-git -Scope CurrentUser -Force }

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
  winget install --id JanDeDobbeleer.OhMyPosh -e --accept-source-agreements --accept-package-agreements --silent
}

winget install --id NerdFonts.CascadiaCode -e --accept-source-agreements --accept-package-agreements --silent
winget install --id junegunn.fzf -e --accept-source-agreements --accept-package-agreements --silent

$profileContent = @'
Import-Module PSReadLine
Import-Module posh-git
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function Complete
Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock { Invoke-FzfHistory }
function Invoke-FzfHistory { $item = (Get-Content (Get-PSReadLineOption).HistorySavePath) | fzf.exe; if ($item) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($item) } }
Set-Alias ll Get-ChildItem
Set-Alias g git
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression }
'@
$profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force
Write-Host "✓ PowerShell profile written to $PROFILE"
