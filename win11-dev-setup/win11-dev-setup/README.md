# Windows 11 Dev Environment — Bootstrap Kit

## TL;DR
1. **Unzip** this folder somewhere stable, e.g. `C:\win11-dev-setup`.
2. Open **PowerShell (Run as Administrator)**.
3. Run:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
   cd C:\win11-dev-setup
   .\setup.ps1 -Profiles core,cli,web,data,dotnet,syslangs,containers -EnableWSL -ConfigureShell
   ```
   > Add/remove profiles as needed (see `/manifests`).

## What you get
- Idempotent install via **winget** with graceful fallbacks.
- Optional **WSL2** enablement and Ubuntu bootstrap.
- PowerShell ergonomics: **PSReadLine**, **posh-git**, **Oh My Posh**, **fzf** bindings.
- Opinionated CLI set (ripgrep, fd, bat, eza, fzf, 7zip, wget/curl present by default).
- Language stacks: Python (+`pipx` + `uv` + `poetry`), Node (LTS + `pnpm`), .NET (8/9), Go, Rust, LLVM/Clang, CMake, Ninja.
- Containers: Docker Desktop (optional), Dev Containers CLI.
- Windows Terminal snippet for nice defaults.
- Repo sync helper reading `repos.txt` (optional).

## Profiles (manifests)
- `core.json` — base system & editors.
- `cli.json` — modern CLI tools.
- `web.json` — Node LTS, pnpm.
- `data-python.json` — Python, pipx, uv, poetry.
- `dotnet.json` — .NET SDKs, VS Build Tools (C++ workload optional).
- `syslangs.json` — Rust, Go, LLVM/Clang, CMake, Ninja.
- `containers.json` — Docker Desktop, Dev Containers CLI.
- `docs.json` — Pandoc, MikTeX (optional, heavy).
- Add your own JSON manifest in `/manifests` and pass it by name via `-Profiles`.

## Safe defaults
- Script is **idempotent**: re-runs won’t reinstall already present packages.
- Heavy installs (VS Build Tools, Docker) are **optional**; opt-in by including their profile.
- No risky network/registry tweaks are applied by default.

## WSL2
Use `-EnableWSL` to enable platform features and set WSL2 as default. To install Ubuntu 24.04 after reboot:
```powershell
wsl --install -d Ubuntu-24.04
# then inside Ubuntu:
bash /mnt/c/win11-dev-setup/wsl/ubuntu-setup.sh
```

## Repo sync (optional)
Add lines to `repos.txt` like:
```
https://github.com/OWNER/REPO.git;C:\dev\REPO
```
Then run:
```powershell
./scripts/Sync-Repos.ps1 -ListPath ./repos.txt
```

---
**Heads-up:** some packages may prompt the first time (e.g., Docker Desktop). Close/restart terminal after `-ConfigureShell` to load the profile.
