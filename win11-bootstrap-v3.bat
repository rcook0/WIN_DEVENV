@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ---------- Admin check ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] Please run this .bat as Administrator.
  pause
  exit /b 1
)

:: ---------- Logging bootstrap (self-reinvoke with redirection) ----------
if not defined __REDIR__ (
  for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "$([DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss'))"` ) do set "TS=%%t"
  set "__REDIR__=1"
  set "BASE=%~dp0"
  set "LOGDIR=%SystemDrive%\win11-dev-setup\logs"
  if not exist "%LOGDIR%" mkdir "%LOGDIR%"
  set "LOG=%LOGDIR%\%~n0-%TS%.log"
  echo Logging to "%LOG%"
  call "%~f0" %* >> "%LOG%" 2>&1
  set "RC=%ERRORLEVEL%"
  echo.
  echo === Log saved to: %LOG% ===
  exit /b %RC%
)

title Win11 Dev Bootstrap v3 (.bat) - flags, logging, VS2022, WSL2, Kubuntu VM

echo ==^> Starting bootstrap at %DATE% %TIME%

:: ---------- Parse flags ----------
set "ONLY_CORE=0"
set "INSTALL_CLI=1"
set "INSTALL_WEB=1"
set "INSTALL_PY=1"
set "INSTALL_DOTNET=1"
set "INSTALL_SYSLANGS=1"
set "INSTALL_CONTAINERS=1"
set "INSTALL_DOCS=1"
set "INSTALL_VMTOOLS=1"
set "ENABLE_WSL=1"
set "ENABLE_HYPERV=1"
set "INSTALL_VS=1"
set "VS_MIN=0"

for %%A in (%*) do (
  if /I "%%~A"=="/only-core" set "ONLY_CORE=1"
  if /I "%%~A"=="/no-cli" set "INSTALL_CLI=0"
  if /I "%%~A"=="/no-web" set "INSTALL_WEB=0"
  if /I "%%~A"=="/no-py" set "INSTALL_PY=0"
  if /I "%%~A"=="/no-dotnet" set "INSTALL_DOTNET=0"
  if /I "%%~A"=="/no-sys" set "INSTALL_SYSLANGS=0"
  if /I "%%~A"=="/no-docker" set "INSTALL_CONTAINERS=0"
  if /I "%%~A"=="/no-docs" set "INSTALL_DOCS=0"
  if /I "%%~A"=="/no-vm" set "INSTALL_VMTOOLS=0"
  if /I "%%~A"=="/no-wsl" set "ENABLE_WSL=0"
  if /I "%%~A"=="/no-hyperv" set "ENABLE_HYPERV=0"
  if /I "%%~A"=="/skip-vs" set "INSTALL_VS=0"
  if /I "%%~A"=="/vs-min" set "VS_MIN=1"
)

:: ---------- Winget sanity ----------
where winget >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] winget not found. Install "App Installer" from Microsoft Store and re-run.
  exit /b 1
)
set "WINGET_CMD=winget install -e --accept-source-agreements --accept-package-agreements --source winget"

:: ---------- Package groups ----------
set CORE=Microsoft.PowerShell Git.Git GitHub.cli Microsoft.WindowsTerminal Microsoft.VisualStudioCode 7zip.7zip Google.Chrome
set CLI=BurntSushi.ripgrep sharkdp.fd sharkdp.bat eza-community.eza junegunn.fzf GnuPG.GnuPG WiresharkFoundation.Wireshark
set WEB=OpenJS.NodeJS.LTS
set PY=Python.Python.3.12
set DOTNET=Microsoft.DotNet.SDK.8 Microsoft.DotNet.SDK.9 Microsoft.VisualStudio.2022.BuildTools
set SYSLANGS=GoLang.Go Rustlang.Rustup LLVM.LLVM Kitware.CMake Ninja-build.Ninja
set CONTAINERS=Docker.DockerDesktop
set DOCS=Pandoc.Pandoc MiKTeX.MiKTeX
set VMTOOLS=Oracle.VirtualBox Hashicorp.Vagrant

:: ---------- Installer functions ----------
set "EMPTY="
for /f "delims=" %%# in ('2^>nul set ^| findstr /R "^_"') do set "%%#="

:install_group
:: %1 = group name, %2.. = package ids
set "_grp=%~1"
shift
:install_group_loop
if "%~1"=="" goto :eof
echo --^> %~1
%WINGET_CMD% --id %~1 || echo [WARN] Install returned non-zero for %~1
shift
goto install_group_loop

:: ---------- Execute installs ----------
echo.
echo [CORE] Installing core baseline...
call :install_group CORE %CORE%

if "%ONLY_CORE%"=="1" goto maybe_wsl

if "%INSTALL_CLI%"=="1" (
  echo.
  echo [CLI] Installing CLI tools...
  call :install_group CLI %CLI%
)

if "%INSTALL_WEB%"=="1" (
  echo.
  echo [WEB] Installing Node LTS...
  call :install_group WEB %WEB%
)

if "%INSTALL_PY%"=="1" (
  echo.
  echo [PY] Installing Python...
  call :install_group PY %PY%
)

if "%INSTALL_DOTNET%"=="1" (
  echo.
  echo [DOTNET] Installing .NET SDKs and VS Build Tools...
  call :install_group DOTNET %DOTNET%
)

if "%INSTALL_SYSLANGS%"=="1" (
  echo.
  echo [SYSLANGS] Installing system language toolchains...
  call :install_group SYSLANGS %SYSLANGS%
)

if "%INSTALL_CONTAINERS%"=="1" (
  echo.
  echo [CONTAINERS] Installing Docker Desktop...
  call :install_group CONTAINERS %CONTAINERS%
)

if "%INSTALL_DOCS%"=="1" (
  echo.
  echo [DOCS] Installing docs toolchain...
  call :install_group DOCS %DOCS%
)

if "%INSTALL_VMTOOLS%"=="1" (
  echo.
  echo [VM] Installing VirtualBox + Vagrant...
  call :install_group VMTOOLS %VMTOOLS%
)

:: ---------- Visual Studio Community (optional) ----------
if "%INSTALL_VS%"=="1" (
  echo.
  echo [+] Installing Visual Studio 2022 Community workloads...
  if "%VS_MIN%"=="1" (
    echo     Workloads: Minimal Managed Desktop only
    %WINGET_CMD% --id Microsoft.VisualStudio.2022.Community --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.ManagedDesktop"
  ) else (
    echo     Workloads: ManagedDesktop, NetWeb, NativeDesktop
    %WINGET_CMD% --id Microsoft.VisualStudio.2022.Community --override "--quiet --wait --norestart --includeRecommended --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.NativeDesktop"
  )
  if %errorlevel% neq 0 echo [WARN] VS2022 Community returned non-zero (you can rerun this section later).
)

:maybe_wsl
:: ---------- WSL2 enable ----------
if "%ENABLE_WSL%"=="1" (
  echo.
  echo [WSL] Enabling WSL and Virtual Machine Platform features...
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
  wsl --set-default-version 2

  echo [WSL] To install Ubuntu 24.04:
  echo     wsl --install -d Ubuntu-24.04
  echo [WSL] After first launch, inside Ubuntu run:
  echo     bash /mnt/c/win11-dev-setup/wsl/kubuntu-wsl-setup.sh

  :: Write the WSL Kubuntu helper script
  set "BASE=%~dp0"
  if not exist "%BASE%wsl" mkdir "%BASE%wsl"
  (
    echo #!/usr/bin/env bash
    echo set -euo pipefail
    echo if [ ! -f /etc/wsl.conf ] ^|^| ! grep -q "systemd=true" /etc/wsl.conf; then
    echo   sudo tee /etc/wsl.conf ^> /dev/null ^<^<'EOF'
    echo [boot]
    echo systemd=true
    echo [user]
    echo default=${USER}
    echo EOF
    echo   echo "Now exit WSL and run:  wsl --shutdown"
    echo fi
    echo sudo apt-get update
    echo sudo apt-get install -y kde-plasma-desktop sddm konsole dolphin kate okular plasma-discover plasma-discover-backend-flatpak flatpak mesa-utils dbus-x11
    echo echo "KDE Plasma installed. Restart WSL (wsl --shutdown) and launch GUI apps."
  )> "%BASE%wsl\kubuntu-wsl-setup.sh"
)

:: ---------- Hyper-V + Kubuntu VM ----------
if "%ENABLE_HYPERV%"=="1" (
  echo.
  echo [Hyper-V] Attempting to enable Hyper-V (safe to ignore on unsupported SKUs)...
  dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

  set "VMNAME=Kubuntu-24.04"
  set "MEMGB=8"
  set "CPUS=4"
  set "VHDSIZEGB=60"
  set "ISOURL=https://cdimage.ubuntu.com/kubuntu/releases/24.04/release/kubuntu-24.04.1-desktop-amd64.iso"
  set "BASE=%~dp0"
  set "ISODIR=%BASE%isos"
  set "ISOPATH=%ISODIR%\kubuntu-24.04.1-desktop-amd64.iso"

  if not exist "%ISODIR%" mkdir "%ISODIR%"

  echo [Hyper-V] Fetching Kubuntu ISO (if missing)...
  powershell -NoProfile -Command "if (-not (Test-Path '%ISOPATH%')) { Invoke-WebRequest -Uri '%ISOURL%' -OutFile '%ISOPATH%' }"

  echo [Hyper-V] Creating VM (idempotent)...
  powershell -NoProfile -Command ^
    "$vm='%VMNAME%';" ^
    "if (Get-Command Get-VM -ErrorAction SilentlyContinue) {" ^
    " if (Get-VM -Name $vm -ErrorAction SilentlyContinue) { Write-Host 'VM exists. Skipping.' } else {" ^
    "   $pub = [Environment]::GetFolderPath('CommonDocuments');" ^
    "   $vmroot = Join-Path $pub 'Hyper-V';" ^
    "   New-Item -ItemType Directory -Force -Path $vmroot ^| Out-Null;" ^
    "   New-VM -Name $vm -Generation 2 -MemoryStartupBytes (%MEMGB%GB) -SwitchName 'Default Switch' -Path $vmroot ^| Out-Null;" ^
    "   Set-VM -Name $vm -ProcessorCount %CPUS% -DynamicMemory -MemoryMinimumBytes (%MEMGB%GB) -MemoryMaximumBytes (%MEMGB%GB) ^| Out-Null;" ^
    "   Set-VMFirmware -VMName $vm -EnableSecureBoot On -SecureBootTemplate 'MicrosoftUEFICertificateAuthority';" ^
    "   $vhd=Join-Path $vmroot ($vm + '.vhdx'); New-VHD -Path $vhd -SizeBytes (%VHDSIZEGB%GB) -Dynamic ^| Out-Null; Add-VMHardDiskDrive -VMName $vm -Path $vhd ^| Out-Null;" ^
    "   Add-VMDvdDrive -VMName $vm -Path '%ISOPATH%' ^| Out-Null;" ^
    "   Write-Host 'VM created. Use: Start-VM %VMNAME%';" ^
    " }" ^
    "} else { Write-Host 'Hyper-V PowerShell module not available. Open Hyper-V Manager and create the VM manually.' }"

  echo.
  echo [Hyper-V] (Optional) Compute ISO SHA256 for manual verification:
  certutil -hashfile "%ISOPATH%" SHA256
)

echo.
echo === Completed at %DATE% %TIME% ===
echo Hints:
echo   - Lite mode:   %~n0.bat /only-core /vs-min /no-docker /no-docs /no-vm
echo   - Skip VS:     %~n0.bat /skip-vs
echo   - Skip WSL:    %~n0.bat /no-wsl
echo   - Skip Hyper-V:%~n0.bat /no-hyperv
echo.
endlocal
