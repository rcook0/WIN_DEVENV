@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] Please run this .bat as Administrator.
  pause
  exit /b 1
)

title Win11 Dev Bootstrap (.bat) - Core, VS2022, WSL2, Kubuntu VM

echo ==^> Starting bootstrap at %DATE% %TIME%

:: --- Winget sanity ---
where winget >nul 2>&1
if %errorlevel% neq 0 (
  echo [ERROR] winget not found. Install "App Installer" from Microsoft Store and re-run.
  exit /b 1
)

set "WINGET_CMD=winget install -e --accept-source-agreements --accept-package-agreements --source winget"

:: --- Profiles (flat lists) ---
set CORE=Microsoft.PowerShell Git.Git GitHub.cli Microsoft.WindowsTerminal Microsoft.VisualStudioCode 7zip.7zip Google.Chrome
set CLI=BurntSushi.ripgrep sharkdp.fd sharkdp.bat eza-community.eza junegunn.fzf GnuPG.GnuPG WiresharkFoundation.Wireshark
set WEB=OpenJS.NodeJS.LTS
set PY=Python.Python.3.12
set DOTNET=Microsoft.DotNet.SDK.8 Microsoft.DotNet.SDK.9 Microsoft.VisualStudio.2022.BuildTools
set SYSLANGS=GoLang.Go Rustlang.Rustup LLVM.LLVM Kitware.CMake Ninja-build.Ninja
set CONTAINERS=Docker.DockerDesktop
set DOCS=Pandoc.Pandoc MiKTeX.MiKTeX
set VMTOOLS=Oracle.VirtualBox Hashicorp.Vagrant

echo.
echo [1/6] Installing CORE profile...
for %%I in (%CORE%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [2/6] Installing CLI profile...
for %%I in (%CLI%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [3/6] Installing WEB + PYTHON...
for %%I in (%WEB% %PY%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [4/6] Installing .NET SDKs and VS Build Tools...
for %%I in (%DOTNET%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [5/6] Installing system languages toolchain...
for %%I in (%SYSLANGS%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [6/6] Installing Containers + Docs + VM tools (optional block)...
for %%I in (%CONTAINERS% %DOCS% %VMTOOLS%) do (
  echo --^> %%I
  %WINGET_CMD% --id %%I || echo [WARN] Install returned non-zero for %%I
)

echo.
echo [+] Installing Visual Studio 2022 Community with workloads (ManagedDesktop, NetWeb, NativeDesktop)...
%WINGET_CMD% --id Microsoft.VisualStudio.2022.Community --override "--quiet --wait --norestart --includeRecommended --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.NativeDesktop"
if %errorlevel% neq 0 echo [WARN] VS2022 Community returned non-zero (you can rerun this section later).

:: --- Enable WSL2 (no reboot here) ---
echo.
echo [WSL] Enabling WSL and Virtual Machine Platform features...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2

echo [WSL] To install Ubuntu 24.04:
echo     wsl --install -d Ubuntu-24.04
echo [WSL] After first launch, inside Ubuntu run:
echo     bash /mnt/c/win11-dev-setup/wsl/kubuntu-wsl-setup.sh

:: --- Write the WSL Kubuntu helper script to C:\win11-dev-setup\wsl ---
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

:: --- Optional: Enable Hyper-V and create a Kubuntu VM (requires reboot after enabling) ---
echo.
echo [Hyper-V] Attempting to enable Hyper-V (safe to ignore on unsupported SKUs)...
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

:: VM params
set "VMNAME=Kubuntu-24.04"
set "MEMGB=8"
set "CPUS=4"
set "VHDSIZEGB=60" 25.10/release/kubuntu-25.10-desktop-amd64.iso
set "ISOURL=https://cdimage.ubuntu.com/kubuntu/releases/25.10/release/kubuntu-25.10-desktop-amd64.iso"
set "ISODIR=%BASE%isos"
set "ISOPATH=%ISODIR%\kubuntu-25.10-desktop-amd64.iso"

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
echo === Bootstrap complete. Recommended next steps ===
echo 1) Reboot if features were enabled (WSL/Hyper-V).
echo 2) Install Ubuntu:  wsl --install -d Ubuntu-24.04
echo 3) Inside Ubuntu:   bash /mnt/c/win11-dev-setup/wsl/kubuntu-wsl-setup.sh
echo 4) To start VM:     Start-VM %VMNAME%  (from PowerShell) or use Hyper-V Manager GUI.
echo.
pause

