@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Admin check ===
net session >nul 2>&1 || (echo [ERROR] Run as Administrator.& pause & exit /b 1)

title VBox SEC Bootstrap — ISO auto-pick + hardened VM (no PowerShell)

:: === Config ===
set "VMNAME=Ubuntu-SEC"
set "MEMGB=8"            :: RAM in GB
set "CPUS=4"
set "DISKGB=60"          :: Disk in GB
set "VRAM=64"            :: MB
set "DIST=ubuntu"        :: ubuntu | kubuntu

:: === Paths ===
set "BASE=%~dp0"
set "ISODIR=%BASE%isos"
if not exist "%ISODIR%" mkdir "%ISODIR%"

:: === Timestamp for logs (no PowerShell) ===
for /f "tokens=2 delims==" %%T in ('wmic os get LocalDateTime /value ^| find "="') do set "TS=%%T"
set "TS=%TS:~0,8%_%TS:~8,6%"

set "LOGDIR=%SystemDrive%\win11-dev-setup\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "LOG=%LOGDIR%\vbox-sec-%TS%.log"
echo Logging to %LOG%
call :main >> "%LOG%" 2>&1
set RC=%ERRORLEVEL%
echo === Log saved to: %LOG% ===
exit /b %RC%

:main
echo ==^> Start %DATE% %TIME%

:: --- Ensure VirtualBox via winget ---
where VBoxManage >nul 2>&1
if errorlevel 1 (
  echo [VBox] Installing VirtualBox (winget)...
  winget install -e --id Oracle.VirtualBox --accept-source-agreements --accept-package-agreements --silent || echo [WARN] winget install non-zero.
) else (
  echo [VBox] Found. Attempting upgrade (safe if current)...
  winget upgrade -e --id Oracle.VirtualBox --accept-source-agreements --accept-package-agreements --silent || echo [INFO] No upgrade or channel locked.
)

set "VBOXM=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
if not exist "%VBOXM%" ( where VBoxManage >nul 2>&1 && for /f "delims=" %%P in ('where VBoxManage') do set "VBOXM=%%P" )
if not exist "%VBOXM%" ( echo [ERROR] VBoxManage not found. Reopen a new admin cmd and retry.& exit /b 1 )

:: --- ISO candidates (25.10 -> 25.04.1 -> 24.04.3) ---
if /I "%DIST%"=="ubuntu" (
  set "C1=https://releases.ubuntu.com/25.10/ubuntu-25.10-desktop-amd64.iso"
  set "C2=https://releases.ubuntu.com/25.04.1/ubuntu-25.04.1-desktop-amd64.iso"
  set "C3=https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-desktop-amd64.iso"
) else (
  set "C1=https://cdimage.ubuntu.com/kubuntu/releases/25.10/release/kubuntu-25.10-desktop-amd64.iso"
  set "C2=https://cdimage.ubuntu.com/kubuntu/releases/25.04.1/release/kubuntu-25.04.1-desktop-amd64.iso"
  set "C3=https://cdimage.ubuntu.com/kubuntu/releases/24.04.3/release/kubuntu-24.04.3-desktop-amd64.iso"
)

call :pick_iso "%C1%" "%C2%" "%C3%"
if not defined ISOURL ( echo [ERROR] No reachable ISO candidate. Adjust URLs and retry.& exit /b 1 )
for %%I in ("%ISOURL%") do set "ISOFILE=%%~nxI"
set "ISOPATH=%ISODIR%\%ISOFILE%"
echo [ISO] Selected: %ISOURL%

:: --- Download ISO (curl first, certutil fallback) ---
if not exist "%ISOPATH%" (
  echo [ISO] Downloading -> %ISOPATH%
  where curl >nul 2>&1 && ( curl -L -f -o "%ISOPATH%" "%ISOURL%" || set "CURLFAIL=1" )
  if defined CURLFAIL (
    echo [ISO] curl failed or unavailable, falling back to certutil...
    certutil -urlcache -split -f "%ISOURL%" "%ISOPATH%" || ( echo [ERROR] ISO download failed.& exit /b 1 )
  )
) else (
  echo [ISO] Already present: %ISOPATH%
)

:: --- Optional: SHA256 compute (no remote fetch) ---
echo [ISO] Local SHA256:
certutil -hashfile "%ISOPATH%" SHA256

:: --- Create hardened VM (idempotent) ---
echo [VM] Provisioning "%VMNAME%"...
"%VBOXM%" list vms | findstr /I "\"%VMNAME%\"" >nul 2>&1
if errorlevel 1 (
  "%VBOXM%" createvm --name "%VMNAME%" --ostype Ubuntu_64 --register

  "%VBOXM%" modifyvm "%VMNAME%" ^
    --memory %MEMGB%000 --cpus %CPUS% --vram %VRAM% ^
    --firmware efi ^
    --nic1 nat --nictype1 82540EM ^
    --audio none ^
    --usb off --usbxhci off ^
    --clipboard disabled --draganddrop disabled ^
    --accelerate3d off ^
    --ioapic on --pae on --hwvirtex on --nestedpaging on --paravirtprovider kvm

  set "VMFOLDER=%UserProfile%\VirtualBox VMs\%VMNAME%"
  if not exist "%VMFOLDER%" mkdir "%VMFOLDER%"
  set "VDI=%VMFOLDER%\%VMNAME%.vdi"

  "%VBOXM%" createmedium disk --filename "%VDI%" --size %DISKGB%000 --format VDI
  "%VBOXM%" storagectl "%VMNAME%" --name "SATA" --add sata --controller IntelAhci
  "%VBOXM%" storageattach "%VMNAME%" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%VDI%"

  "%VBOXM%" storagectl "%VMNAME%" --name "IDE" --add ide
  "%VBOXM%" storageattach "%VMNAME%" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "%ISOPATH%"
) else (
  echo [VM] Already exists; skipping create.
)

echo [VM] Starting "%VMNAME%"...
"%VBOXM%" startvm "%VMNAME%" --type gui

echo.
echo Next steps:
echo   - Complete OS install, then detach ISO:
echo       "%VBOXM%" storageattach "%VMNAME%" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium none
echo   - Snapshot baseline:
echo       "%VBOXM%" snapshot "%VMNAME%" take baseline-%DATE% --live
echo.
exit /b 0

:pick_iso
:: Inputs: up to 3 URLs as %1 %2 %3. Output: ISOURL (uses curl HEAD if available; else first).
set "ISOURL="
where curl >nul 2>&1 || ( set "ISOURL=%~1" & goto :eof )
for %%U in (%*) do (
  if not defined ISOURL (
    curl -I -s -L -f "%%~U" >nul 2>&1 && set "ISOURL=%%~U"
  )
)
if not defined ISOURL set "ISOURL=%~1"
goto :eof
