param(
  [string] $VMName = "Kubuntu-24.04",
  [int] $MemoryGB = 8,
  [int] $CPUCount = 4,
  [int] $VhdSizeGB = 60,
  [string] $SwitchName = "Default Switch",
  [string] $IsoUrl = "https://cdimage.ubuntu.com/kubuntu/releases/24.04/release/kubuntu-24.04.1-desktop-amd64.iso"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$isoDir = Join-Path $root "..\isos"
$isoDir = (Resolve-Path $isoDir).Path
$isoPath = Join-Path $isoDir (Split-Path $IsoUrl -Leaf)

if (-not (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V | Where-Object {$_.State -eq "Enabled"})) {
  Write-Error "Hyper-V is not enabled. Run .\scripts\Enable-HyperV.ps1 and reboot first."
}

New-Item -ItemType Directory -Force -Path $isoDir | Out-Null

if (-not (Test-Path $isoPath)) {
  Write-Host "→ Downloading Kubuntu ISO to $isoPath"
  Invoke-WebRequest -Uri $IsoUrl -OutFile $isoPath
} else { Write-Host "✓ ISO already present: $isoPath" }

# Create VM storage
$vmPath = Join-Path $env:PUBLIC "Documents\Hyper-V\$VMName"
New-Item -ItemType Directory -Force -Path $vmPath | Out-Null

# New VM
Write-Host "→ Creating Hyper-V VM: $VMName"
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
  Write-Warning "VM $VMName already exists. Skipping creation."
  return
}

New-VM -Name $VMName -Generation 2 -MemoryStartupBytes (${MemoryGB}GB) -SwitchName $SwitchName -Path $vmPath | Out-Null
Set-VM -Name $VMName -ProcessorCount $CPUCount -DynamicMemory -MemoryMinimumBytes (${MemoryGB}GB) -MemoryMaximumBytes (${MemoryGB*2}GB) | Out-Null

# Secure Boot template for Ubuntu
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

# Disk
$vhdPath = Join-Path $vmPath "$VMName.vhdx"
New-VHD -Path $vhdPath -SizeBytes (${VhdSizeGB}GB) -Dynamic | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path $vhdPath | Out-Null

# DVD drive
Add-VMDvdDrive -VMName $VMName -Path $isoPath | Out-Null

Write-Host "✓ VM created. Start installation with:  Start-VM $VMName"
