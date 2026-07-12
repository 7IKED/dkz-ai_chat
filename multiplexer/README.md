# 🖥️ COSMO_V2 // Multiplexer Umgebung

> 🟢 Zellij-basierte Terminal-Multiplexer Umgebung · DEVKiTZ™ Ecosystem · Matrix Theme

Die Terminal-Version der Cosmo Dashboards: **eine** Multiplexer-Basis, **fünf** vorkonfigurierte Profile, lauffähig unter **Linux, Windows (WSL) und Docker**.

```
 ██████╗ ██████╗ ███████╗███╗   ███╗ ██████╗
██╔════╝██╔═══██╗██╔════╝████╗ ████║██╔═══██╗   COSMO_V2 MULTIPLEXER
██║     ██║   ██║███████╗██╔████╔██║██║   ██║   Zellij · Matrix · DkZ
╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║╚██████╔╝
 ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝
```

---

## 🎛️ Die 5 Profile

| Profil | Befehl | Zweck | Tabs |
|:--|:--|:--|:--|
| 🏠 **Desktop** | `cosmo desktop` | Arbeitsplatz / Home Admin | Hauptdeck · Dateien · Logs |
| 🌐 **VPS** | `cosmo vps` | Remote-Server-Steuerung | Server · Docker · Uplink |
| 🤖 **Agent** | `cosmo agent` | Agenten-Basis (Dirigent/Swarm) | Orchestrator · Swarm |
| 🏗️ **Builder** | `cosmo builder` | Multi-Builder + **Teststrassen** | Build-Lanes · Teststrasse · Docker-Build |
| 🛡️ **Monitor** | `cosmo monitor` | Monitoring / Security | Grid · Global-Logs |

Jedes Profil ist ein Zellij-Layout (KDL) und startet als eigene benannte Session (`cosmo-<profil>`), an die man sich jederzeit wieder anhängen kann.

---

## 📦 Installation

### 🐧 Linux / macOS / WSL

```bash
cd multiplexer
./install.sh
```

Der Installer:
- installiert **zellij** (cargo / brew / pacman / apt-Binary — je nach System),
- verlinkt `config.kdl`, Theme und alle Layouts nach `~/.config/zellij`,
- legt den Launcher `cosmo` in `~/.local/bin` ab,
- erzeugt eine Beispiel-Env unter `~/.config/cosmo/env`.

Danach:
```bash
cosmo desktop        # oder: agent · builder · vps · monitor
```

> Nur Config ohne zellij-Installation: `./install.sh --no-zellij`

### 🪟 Windows (WSL2)

Zellij ist Unix-nativ — unter Windows läuft Cosmo über **WSL2**.

```powershell
cd multiplexer
./install.ps1                 # optional: -Distro Ubuntu
```

Das Script prüft WSL, führt den Linux-Installer **innerhalb** von WSL aus und legt einen `cosmo.cmd`-Wrapper an (im PATH). Danach in einem **neuen** Terminal:

```powershell
cosmo desktop
```

> Fehlt WSL:  `wsl --install -d Ubuntu` (Adminrechte), neu starten, erneut ausführen.

### 🐳 Docker

```bash
cd multiplexer/docker

# Image bauen
docker compose build

# Profil starten (interaktiv)
docker compose run --rm agent
docker compose run --rm builder
docker compose run --rm desktop
```

Oder pur mit Docker:
```bash
docker build -t devkitz/cosmo-mux -f docker/Dockerfile .
docker run -it --rm -v "$PWD":/work devkitz/cosmo-mux agent
```

Das Projekt-Root wird nach `/work` gemountet; erfasste Test-Läufe landen im Volume `cosmo-captures`.

---

## ⚙️ Konfiguration

Alle Profile lesen Umgebungsvariablen aus `~/.config/cosmo/env` (vom Launcher automatisch geladen).

```bash
# VPS-Steuerung — Hosts pro Slot
export COSMO_VPS_HOSTS="user@1.2.3.4 admin@vps.example.com root@10.0.0.9"
export COSMO_VPS_PING="1.1.1.1"

# Multi-Builder — Build-/Test-Befehle je Lane
export COSMO_BUILD_A="npm run build"
export COSMO_BUILD_B="cargo build --release"
export COSMO_BUILD_C="make"
export COSMO_TEST_CMD="npm test"
export COSMO_WATCH_CMD="npm run test:watch"

# Agenten-Basis
export COSMO_AGENT_CMD="python orchestrator.py"     # Runner-Pane
export COSMO_AGENT_STATUS_URL="http://localhost:8080/status"
export COSMO_WEBHOOK_LOG="/var/log/cosmo/webhooks.log"
export COSMO_SWARM_LOG="/var/log/cosmo/swarm.log"
```

---

## 🏗️ Teststrassen-Erfassung

Das Builder-Profil nutzt `scripts/testlane.sh`, um jeden Build-/Test-Lauf **live anzuzeigen** und gleichzeitig zu **erfassen**:

```bash
# Einzelnen Lauf erfassen (Zeitstempel, Exit-Code, Dauer)
scripts/testlane.sh backend "npm run build"

# Letzte Captures verfolgen
scripts/testlane.sh --tail

# Alle Läufe als JSONL
scripts/testlane.sh --summary
```

Erfasst wird nach `multiplexer/.captures/`:
- `<lane>-<timestamp>.log` — vollständiges Protokoll mit Zeitstempeln
- `summary.jsonl` — eine Zeile pro Lauf:
  ```json
  {"lane":"backend","ts":"20260710-142530","status":"pass","exit":0,"duration_s":42,"log":".captures/backend-20260710-142530.log"}
  ```

Damit lassen sich CI-artige Pipelines lokal fahren und auswerten (grep/jq auf `summary.jsonl`).

---

## 🐚 Perfect Zsh Setup

Das Shell-Modul (`shell/`) setzt „The Perfect Zsh Setup For 2026" im Matrix-Look um — **zinit** als Plugin-Manager, **Autosuggestions** (Ghost-Text aus der History), **Syntax-Highlighting** (gültige Befehle grün, ungültige rot), **fzf-tab** (Tab-Vervollständigung als Fuzzy-Menü mit Verzeichnis-Preview), **zoxide** (`cd` lernt deine Verzeichnisse), **eza/bat/ripgrep**-Aliases und ein Matrix-Prompt (Starship-Config, mit reinem Zsh-Fallback).

```bash
multiplexer/shell/install-shell.sh     # Pakete + ~/.zshrc + Login-Shell
zsh                                    # erster Start: zinit klont die Plugins
```

Alles defensiv: Fehlt ein Tool (starship, atuin, eza …), läuft die Shell trotzdem — inklusive eingebautem Ctrl+R/Ctrl+T-Fallback, falls die fzf-Distro-Keybindings fehlen. Im Docker-Image ist das Setup vorinstalliert (`SHELL=/usr/bin/zsh`).

## ⌨️ Tastenkürzel

Zellij-Defaults plus Cosmo-Ergänzungen (siehe Statusleiste unten):

| Taste | Aktion |
|:--|:--|
| `Ctrl p` | Pane-Modus (teilen, fokussieren) |
| `Ctrl t` | Tab-Modus |
| `Ctrl n` | Resize-Modus |
| `Ctrl s` | Scroll / Suche |
| `Ctrl o` → `d` | Session **detachen** (läuft weiter) |
| `Alt 1..5` | Neuen Tab mit Profil-Layout (desktop…monitor) |

Wieder anhängen:
```bash
cosmo ls                 # laufende Sessions
cosmo attach cosmo-agent
```

---

## 📁 Struktur

```
multiplexer/
├── bin/
│   ├── cosmo               # Launcher (bash)
│   └── cosmo.ps1           # Launcher (PowerShell → WSL)
├── config/
│   └── config.kdl          # Zellij-Config + Cosmo-Matrix-Theme + Keybinds
├── themes/
│   └── cosmo-matrix.kdl    # Theme separat (optional)
├── layouts/
│   ├── desktop.kdl         # Profil 1 (mehrere Tabs)
│   ├── vps.kdl             # Profil 2
│   ├── agent.kdl           # Profil 3
│   ├── builder.kdl         # Profil 4
│   ├── monitor.kdl         # Profil 5
│   └── *-tab.kdl           # Einzel-Tab-Varianten (fuer Alt+1..5 Shortcuts)
├── scripts/
│   ├── testlane.sh         # Teststrassen-Erfassung
│   ├── vps-connect.sh      # SSH-Slot-Verbindung
│   └── agent-ctl.sh        # Agent-Statuspanels
├── shell/                  # 🐚 Perfect Zsh Setup (Matrix)
│   ├── zshrc               # zinit · autosuggestions · syntax-hl · fzf-tab
│   ├── aliases.zsh         # eza/bat/rg-Aliases + Cosmo-Kurzbefehle (cxa, cxb …)
│   ├── cosmo-prompt.zsh    # Matrix-Prompt (Fallback ohne Starship)
│   ├── starship.toml       # Starship-Prompt im Matrix-Theme
│   └── install-shell.sh    # Installer (Pakete + ~/.zshrc + chsh)
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── install.sh              # Installer (Linux/macOS/WSL)
├── install.ps1             # Installer (Windows)
└── README.md
```

---

## 🧩 Erweitern

- **Neues Profil**: `layouts/<name>.kdl` anlegen und in `bin/cosmo` (case-Zweig) ergänzen.
- **Panes anpassen**: KDL-`pane`-Blöcke mit `command`/`args`/`name` — jedes Pane ist ein eigener Prozess.
- **Reale Datenquellen** in der Agenten-Basis: `COSMO_*_URL` / `COSMO_*_LOG` setzen, dann zeigt `agent-ctl.sh` echte Feeds statt Simulation.

Die Panes sind bewusst **defensiv** geschrieben (`btop || htop || top`), damit die Layouts auf minimalen Systemen und in Containern nicht abbrechen.

---

## 🔗 Teil des DEVKiTZ™ Ecosystem

Passt zu den Cosmo/Matrix-Dashboards des `dkz-ai_chat` Moduls — gleiche Farbwelt (`#00FF41` / `#008F11`), gleiche Sprache (Dirigent, Nanobot-Swarm, Webhooks-ontherun), jetzt als echte Terminal-Multiplexer-Umgebung.

MIT © [DEVKiTZ™](https://github.com/7IKED/devkitz-workspace)
