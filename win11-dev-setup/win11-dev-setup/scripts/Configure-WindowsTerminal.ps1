$settingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (-not (Test-Path $settingsPath)) {
  Write-Warning "Windows Terminal settings.json not found (is Windows Terminal installed/launched once?). Skipping."
  return
}
$backup = "$settingsPath.bak_" + (Get-Date -Format "yyyyMMddHHmmss")
Copy-Item $settingsPath $backup -Force
Write-Host "Backup at: $backup"

# Best-effort: ensure default profile uses PowerShell 7 if present
$settings = Get-Content $settingsPath -Raw
$updated = $settings -replace '"defaultProfile"\s*:\s*".*?"','"defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}"' # pwsh GUID on many systems
$updated | Out-File $settingsPath -Encoding UTF8
Write-Host "✓ Windows Terminal default profile set to PowerShell 7 (best-effort)."
