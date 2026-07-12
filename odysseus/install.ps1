# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // WINDOWS-INSTALLER  →  C:\DEVKiTZ\odysseus             ║
# ╚══════════════════════════════════════════════════════════════════╝
#  ./install.ps1                   Installation nach C:\DEVKiTZ\odysseus
#  ./install.ps1 -Target D:\pfad   anderes Ziel
#  Voraussetzungen: Docker Desktop (Stack) + WSL2 (Terminal).
param(
    [string]$Target = "C:\DEVKiTZ\odysseus",
    [string]$Distro = ""
)
$ErrorActionPreference = "Stop"
function Say($m){ Write-Host "[ODYSSEUS] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[ODYSSEUS] $m" -ForegroundColor Yellow }

Say "Installation nach $Target"

# 1) Dateien kopieren -----------------------------------------------------
$src = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force -Path $Target | Out-Null
Copy-Item -Recurse -Force -Path (Join-Path $src "*") -Destination $Target `
    -Exclude @(".env","data")
if (-not (Test-Path (Join-Path $Target ".env"))) {
    Copy-Item (Join-Path $src ".env.example") (Join-Path $Target ".env")
    Warn ".env angelegt — BITTE Passwoerter in $Target\.env aendern!"
}

# 2) Docker pruefen --------------------------------------------------------
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Say "Docker gefunden — Stack starten mit:"
    Write-Host "    cd $Target; docker compose up -d" -ForegroundColor DarkGray
} else {
    Warn "Docker Desktop fehlt → https://docs.docker.com/desktop/setup/install/windows-install/"
}

# 3) WSL/Terminal ----------------------------------------------------------
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    $distroArg = @(); if ($Distro -ne "") { $distroArg = @("-d", $Distro) }
    # Pfad in WSL uebersetzen: C:\DEVKiTZ\odysseus -> /mnt/c/DEVKiTZ/odysseus
    $wslPath = "/mnt/" + $Target.Substring(0,1).ToLower() + ($Target.Substring(2) -replace '\\','/')
    & wsl.exe @distroArg -- bash -lc "chmod +x '$wslPath/bin/odysseus' '$wslPath'/scripts/*.sh 2>/dev/null; grep -q odysseus ~/.bashrc 2>/dev/null || echo 'export PATH=""$wslPath/bin:`$PATH""' >> ~/.bashrc"
    Say "WSL vorbereitet. Terminal starten:  wsl -- bash -lic 'odysseus'"
} else {
    Warn "WSL fehlt (fuer das Matrix-Terminal):  wsl --install -d Ubuntu"
}

# 4) Startmenue-Batch -------------------------------------------------------
$cmd = "@echo off`r`ncd /d $Target`r`nwsl -- bash -lic `"ODYSSEUS_DIR=$($Target -replace '\\','/' -replace '^C:','/mnt/c') odysseus`"`r`n"
Set-Content -Path (Join-Path $Target "odysseus.cmd") -Value $cmd -Encoding ASCII
Say "Launcher: $Target\odysseus.cmd"
Say "Naechste Schritte:  1) .env anpassen  2) docker compose up -d  3) odysseus init"
