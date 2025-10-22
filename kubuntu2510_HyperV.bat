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
