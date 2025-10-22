@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: === Admin check ===
net session >nul 2>&1 || (echo [ERROR] Run as Administrator.& pause & exit /b 1)

title VBox SEC Bootstrap — ISO fetch + hardened VM

:: === Config (edit as needed) ===
set "VMNAME=Kubuntu-SEC"
set "MEMGB=8"             :: RAM in GB
set "CPUS=4"
set "DISKGB=60"           :: Disk in GB
set "VRAM=64"             :: MB (keep modest in secure contexts)

:: ISO (adjust to latest if desired)
set "ISOURL=https://cdimage.ubuntu.com/kubuntu/releases/24.04/release/kubuntu-24.04.1-desktop-amd64.iso"
set "SHAURL=https://cdimage.ubuntu.com/kubuntu/releases/24.04/release/SHA256SUMS"

:: === Prep paths ===
set "BASE=%~dp0"
set "ISODIR=%BASE%isos"
if not exist "%ISODIR%" mkdir "%ISODIR%"

:: === Install/upgrade VirtualBox (idempotent) ===
where VBoxManage >nul 2>&1
if errorlevel 1 (
  echo [VBox] Installing VirtualBox via winget...
  winget install -e --id Oracle.VirtualBox --accept-source-agreements --accept-package-agreements --silent || echo [WARN] winget install returned non-zero.
) else (
  echo [VBox] Found: %ProgramFiles%\Oracle\VirtualBox
  echo [VBox] Attempting upgrade (safe if already current)...
  winget upgrade -e --id Oracle.VirtualBox --accept-source-agreements --accept-package-agreements --silent || echo [INFO] No upgrade needed / channel locked.
)
set "VBOXM=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
if not exist "%VBOXM%" (
  where VBoxManage >nul 2>&1 && for /f "delims=" %%P in ('where VBoxManage') do set "VBOXM=%%P"
)
if not exist "%VBOXM%" (echo [ERROR] VBoxManage not found. Re-open a new admin cmd and retry.& exit /b 1)

:: === Resolve ISO filename from URL ===
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$u='%ISOURL%'; [IO.Path]::GetFileName([uri]$u)"`) do set "ISOFILE=%%I"
set "ISOPATH=%ISODIR%\%ISOFILE%"

:: === Download ISO if missing ===
if not exist "%ISOPATH%" (
  echo [ISO] Downloading %ISOFILE% ...
  powershell -NoProfile -Command "Invoke-WebRequest -Uri '%ISOURL%' -OutFile '%ISOPATH%'"
) else (
  echo [ISO] Already present: %ISOPATH%
)

:: === (Optional) Verify SHA256 ===
echo [ISO] Computing local SHA256 (optional)...
for /f "tokens=* delims=" %%L in ('certutil -hashfile "%ISOPATH%" SHA256 ^| findstr /R "^[0-9A-F ]*$"') do set "HASHLINE=%%L"
set "LOCALSHA=%HASHLINE: =%"
echo [ISO] Local SHA256: %LOCALSHA%

echo [ISO] Fetching publisher checksums (optional)...
powershell -NoProfile -Command "(Invoke-WebRequest -Uri '%SHAURL%').Content" > "%ISODIR%\SHA256SUMS" || echo [WARN] Could not download SHA256SUMS.
if exist "%ISODIR%\SHA256SUMS" (
  for /f "tokens=1,* delims= " %%A in ('findstr /C:" %ISOFILE%" "%ISODIR%\SHA256SUMS"') do set "PUBSHA=%%A"
  if defined PUBSHA (
    if /I "%LOCALSHA%"=="%PUBSHA%" (echo [ISO] SHA256 match ✓) else (echo [WARN] SHA256 mismatch! Validate manually.)
  ) else (
    echo [INFO] No matching line found in SHA256SUMS (may be a point release change). Validate manually if required.
  )
)

:: === Create hardened VM ===
echo [VM] Provisioning "%VMNAME%" (idempotent)...
"%VBOXM%" list vms | findstr /I "\"%VMNAME%\"" >nul 2>&1
if errorlevel 1 (
  "%VBOXM%" createvm --name "%VMNAME%" --ostype Ubuntu_64 --register

  :: Core hardware + hardening
  "%VBOXM%" modifyvm "%VMNAME%" ^
    --memory %MEMGB%000 --cpus %CPUS% --vram %VRAM% ^
    --firmware efi ^
    --nic1 nat --nictype1 82540EM ^
    --audio none ^
    --usb off --usbxhci off ^
    --clipboard disabled --draganddrop disabled ^
    --accelerate3d off ^
    --ioapic on --pae on --hwvirtex on --nestedpaging on --paravirtprovider kvm

  :: Storage
  set "VMFOLDER=%UserProfile%\VirtualBox VMs\%VMNAME%"
  if not exist "%VMFOLDER%" mkdir "%VMFOLDER%"
  set "VDI=%VMFOLDER%\%VMNAME%.vdi"
  "%VBOXM%" createmedium disk --filename "%VDI%" --size %DISKGB%000 --format VDI
  "%VBOXM%" storagectl "%VMNAME%" --name "SATA" --add sata --controller IntelAhci
  "%VBOXM%" storageattach "%VMNAME%" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%VDI%"

  :: ISO on IDE (separate bus keeps it obvious)
  "%VBOXM%" storagectl "%VMNAME%" --name "IDE" --add ide
  "%VBOXM%" storageattach "%VMNAME%" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "%ISOPATH%"

) else (
  echo [VM] Already exists; skipping create.
)

:: === Launch installer ===
echo [VM] Starting "%VMNAME%"...
"%VBOXM%" startvm "%VMNAME%" --type gui

echo.
echo Next steps:
echo   - Complete OS install, then remove ISO:
echo       "%VBOXM%" storageattach "%VMNAME%" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium none
echo   - Snapshot baseline (post-patch):
echo       "%VBOXM%" snapshot "%VMNAME%" take "baseline-%DATE%" --live
echo.
echo Hardened defaults applied: NAT only, no USB, no shared clipboard, no drag^&drop, 3D accel off, audio off.
echo Adjust RAM/CPU above if your host policy allows.
echo.
pause
