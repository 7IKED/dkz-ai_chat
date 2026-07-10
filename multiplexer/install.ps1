# ╔══════════════════════════════════════════════════════════════════╗
# ║  COSMO_V2 // MULTIPLEXER INSTALLER  (Windows)                       ║
# ║  Zellij ist Unix-nativ → Cosmo laeuft unter Windows via WSL2.      ║
# ╚══════════════════════════════════════════════════════════════════╝
#  Nutzung (PowerShell):
#     ./install.ps1
#  Optional:  -Distro Ubuntu    (WSL-Distribution)
param(
    [string]$Distro = ""
)
$ErrorActionPreference = "Stop"
function Say($m){ Write-Host "[COSMO] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[COSMO] $m" -ForegroundColor Yellow }

Say "COSMO_V2 Multiplexer — Windows Installer"

# 1) WSL vorhanden? -------------------------------------------------------
$wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
if (-not $wsl) {
    Warn "WSL nicht gefunden. Installiere WSL2 (Adminrechte noetig):"
    Write-Host "        wsl --install -d Ubuntu" -ForegroundColor DarkGray
    Write-Host "  Danach PC neu starten und dieses Script erneut ausfuehren."
    exit 1
}

# 2) Repo-Pfad in WSL-Pfad uebersetzen -----------------------------------
$muxWin = Split-Path -Parent $MyInvocation.MyCommand.Path
# C:\a\b -> /mnt/c/a/b
$muxWsl = "/mnt/" + ($muxWin.Substring(0,1).ToLower()) + ($muxWin.Substring(2) -replace '\\','/')
Say "Multiplexer-Pfad (WSL): $muxWsl"

$distroArg = @()
if ($Distro -ne "") { $distroArg = @("-d", $Distro) }

# 3) Bash-Installer in WSL ausfuehren ------------------------------------
Say "starte Linux-Installer in WSL ..."
& wsl.exe @distroArg -- bash -lc "chmod +x '$muxWsl/install.sh' '$muxWsl/bin/cosmo' '$muxWsl'/scripts/*.sh 2>/dev/null; '$muxWsl/install.sh'"
if ($LASTEXITCODE -ne 0) { Warn "Installer im WSL meldete Fehler ($LASTEXITCODE)."; }

# 4) Windows-Wrapper (cosmo.cmd) in ein PATH-Verzeichnis ------------------
$binDir = Join-Path $env:LOCALAPPDATA "cosmo\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$distroCli = ""
if ($Distro -ne "") { $distroCli = "-d $Distro " }
$cmd = @"
@echo off
REM COSMO_V2 Multiplexer — Windows Wrapper (ruft cosmo in WSL)
wsl.exe $distroCli-- bash -lic "cosmo %*"
"@
Set-Content -Path (Join-Path $binDir "cosmo.cmd") -Value $cmd -Encoding ASCII
Say "Windows-Wrapper → $binDir\cosmo.cmd"

# 5) PATH ergaenzen (User) -----------------------------------------------
$userPath = [Environment]::GetEnvironmentVariable("Path","User")
if ($userPath -notlike "*$binDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
    Warn "PATH ergaenzt — neues Terminal oeffnen, damit `cosmo` verfuegbar ist."
}

Say "fertig. Neues Terminal:  cosmo desktop   (oder agent / builder / vps / monitor)"
Write-Host "  Tipp: direkt in WSL arbeiten gibt das beste Erlebnis." -ForegroundColor DarkGray
