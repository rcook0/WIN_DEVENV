# Windows 11 Dev Environment — Bootstrap Kit (v2)

## Quick start
1. Unzip to `C:\win11-dev-setup`
2. PowerShell (Admin):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
   cd C:\win11-dev-setup
   .\setup.ps1 -Profiles core,cli,web,data,dotnet,syslangs,containers,vm -EnableWSL -ConfigureShell
   ```
   *This now includes **Visual Studio 2022 Community** (via `dotnet` profile) and optional **VM/Vagrant** tooling (via `vm`).*

## New in v2
- **Visual Studio 2022 Community** with sensible workloads (`.NET desktop`, `.NET web`, `C++/Native`) via winget **override**.
- **Kubuntu spin-up (three paths):**
  - **A) WSL2 + KDE (WSLg):** installs a lightweight Plasma stack inside Ubuntu WSL.
  - **B) Hyper-V VM:** one-command creation & ISO fetch of Kubuntu LTS VM.
  - **C) Vagrant + VirtualBox:** `vagrant up` builds a Kubuntu-like Ubuntu box with Plasma.

### A) WSL2 + KDE (WSLg)
After enabling WSL and installing Ubuntu 24.04:
```powershell
wsl --install -d Ubuntu-24.04
# then inside Ubuntu:
bash /mnt/c/win11-dev-setup/wsl/kubuntu-wsl-setup.sh
```
> This installs `plasma-desktop` + common utils (lighter than full `kubuntu-desktop`). WSLg renders GUI apps natively.

### B) Hyper-V Kubuntu VM
Enable Hyper-V, then build the VM:
```powershell
.\scripts\Enable-HyperV.ps1
.\scripts\New-KubuntuVM.ps1 -VMName Kubuntu-24.04 -MemoryGB 8 -CPUCount 4 -VhdSizeGB 60
Start-VM Kubuntu-24.04
```
The script fetches the Kubuntu 24.04 LTS ISO to `C:\win11-dev-setup\isos\` and wires a Gen2 VM with UEFI Secure Boot configured for Ubuntu.

### C) Vagrant (VirtualBox) Kubuntu-like VM
```powershell
winget install -e --id Oracle.VirtualBox
winget install -e --id Hashicorp.Vagrant
cd .\vagrant\kubuntu
vagrant up
```
The box starts from Ubuntu 22.04/24.04 and provisions **KDE Plasma** to approximate Kubuntu.

---

Full docs and manifests live under `/manifests` and `/scripts`.
