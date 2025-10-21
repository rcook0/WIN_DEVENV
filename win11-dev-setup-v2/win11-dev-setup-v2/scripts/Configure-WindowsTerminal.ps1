$settingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (-not (Test-Path $settingsPath)) { Write-Warning "Windows Terminal settings.json not found. Launch the app once, then re-run."; return }
$backup = "$settingsPath.bak_" + (Get-Date -Format "yyyyMMddHHmmss")
Copy-Item $settingsPath $backup -Force
$settings = Get-Content $settingsPath -Raw
$updated = $settings -replace '"defaultProfile"\s*:\s*".*?"','"defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}"'
$updated | Out-File $settingsPath -Encoding UTF8
Write-Host "✓ Windows Terminal default profile set to PowerShell 7."
