function Test-Admin {
  param([switch]$WarnOnly)
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  if (-not $isAdmin) {
    if ($WarnOnly) { Write-Warning "Not running as Administrator. Some installs/features may fail." }
    else {
      Write-Error "Please run PowerShell as Administrator."
    }
  }
}

function Ensure-WinGet {
  if (Get-Command winget -ErrorAction SilentlyContinue) { return }
  Write-Error "winget not found. Install 'App Installer' from Microsoft Store and re-run."
}

function Exec {
  param([string]$Cmd, [int]$SuccessCode = 0)
  Write-Host ">> $Cmd" -ForegroundColor DarkGray
  $p = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile","-Command",$Cmd -Wait -PassThru -WindowStyle Hidden
  if ($p.ExitCode -ne $SuccessCode) {
    throw "Command failed with exit code $($p.ExitCode): $Cmd"
  }
}

function Try-Exec {
  param([string]$Cmd)
  try { Exec -Cmd $Cmd; return $true } catch { Write-Warning $_; return $false }
}

function Ensure-Path {
  param([string]$PathToAdd)
  $current = [Environment]::GetEnvironmentVariable("Path","User")
  if (-not ($current -split ";" | ForEach-Object {$_.Trim()} | Where-Object { $_ -eq $PathToAdd })) {
    [Environment]::SetEnvironmentVariable("Path",$current + ";" + $PathToAdd,"User")
    Write-Host "PATH += $PathToAdd"
  }
}
