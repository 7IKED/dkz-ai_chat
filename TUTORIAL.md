# 🟢 COSMO_V2 // Das komplette Tutorial

> Von den Matrix-HTML-Prototypen zur echten Terminal-Umgebung: Multiplexer (Zellij), Perfect Zsh Setup, Teststrassen-Erfassung — auf Linux, Windows (WSL) und Docker.

```
 ██████╗ ██████╗ ███████╗███╗   ███╗ ██████╗
██╔════╝██╔═══██╗██╔════╝████╗ ████║██╔═══██╗   COSMO_V2 TUTORIAL
██║     ██║   ██║███████╗██╔████╔██║██║   ██║   DEVKiTZ™ Ecosystem
╚██████╗╚██████╔╝███████║██║ ╚═╝ ██║╚██████╔╝
 ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝
```

**Inhalt**
1. [Das Konzept](#1-das-konzept)
2. [Installation](#2-installation)
3. [Erste Schritte: der `cosmo` Launcher](#3-erste-schritte-der-cosmo-launcher)
4. [Die 5 Profile im Detail](#4-die-5-profile-im-detail)
5. [Teststrassen-Erfassung (Workflow)](#5-teststrassen-erfassung-workflow)
6. [Das Perfect Zsh Setup](#6-das-perfect-zsh-setup)
7. [Zellij bedienen: Panes, Tabs, Sessions](#7-zellij-bedienen-panes-tabs-sessions)
8. [Die Prototypen-Galerie](#8-die-prototypen-galerie)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Das Konzept

Alles begann mit fünf **Matrix-Style HTML-Prototypen** (jetzt in [`prototypes/`](prototypes/index.html)):
das Zellij-Dashboard mit GSH-Shell, der Agent-Workspace mit Nanobot-Schwarm, das Vanilla-JS-Dashboard mit Profilen (Home/DevOps/Security) und Layouts (Split/Grid/Focus), die Canvas-Engine und die Canvas-Präsentation.

Dieses Tutorial zeigt die **echte** Umsetzung davon: [`multiplexer/`](multiplexer/) macht aus den Mockups eine
lauffähige Terminal-Umgebung —

| Prototyp (HTML) | Echte Umsetzung |
|:--|:--|
| Zellij Matrix Dashboard (Panes, Tabs, GSH) | Zellij mit `cosmo-matrix`-Theme + `config.kdl` |
| Vanilla-JS-Dashboard: Profile & Layouts | 5 Profile: `desktop` · `vps` · `agent` · `builder` · `monitor` |
| Agent Workspace (Dirigent, Swarm, Webhooks) | `cosmo agent` + `scripts/agent-ctl.sh` |
| GRID/FOCUS Security View | `cosmo monitor` |
| GSH-Terminal | Perfect Zsh Setup (`multiplexer/shell/`) |

---

## 2. Installation

### 2.1 🐧 Linux / macOS / WSL

```bash
git clone https://github.com/7IKED/dkz-ai_chat.git
cd dkz-ai_chat/multiplexer
./install.sh
```

Was passiert:
1. **zellij** wird installiert (je nach System: `cargo`, `brew`, `pacman` oder statisches Binary nach `~/.local/bin`),
2. `config.kdl` + alle Layouts werden nach `~/.config/zellij` **verlinkt** (bestehende Config wird gesichert: `config.kdl.bak.*`),
3. der Launcher landet als **`cosmo`** in `~/.local/bin`,
4. eine Beispiel-Umgebung wird nach `~/.config/cosmo/env` geschrieben,
5. optional wird das **Perfect Zsh Setup** mitinstalliert (Frage am Ende, oder direkt: `COSMO_WITH_ZSH=yes ./install.sh`).

> Nur Config, ohne zellij-Installation: `./install.sh --no-zellij`

### 2.2 🪟 Windows

Zellij ist Unix-nativ → unter Windows läuft Cosmo in **WSL2**:

```powershell
# Falls WSL fehlt (einmalig, Adminrechte, danach Neustart):
wsl --install -d Ubuntu

# Dann:
cd dkz-ai_chat\multiplexer
./install.ps1              # optional: -Distro Ubuntu
```

`install.ps1` führt den Linux-Installer **in** WSL aus und legt `cosmo.cmd` in den Windows-PATH.
Danach in einem **neuen** Terminal einfach `cosmo desktop` — auch direkt aus PowerShell.

### 2.3 🐳 Docker

```bash
cd dkz-ai_chat/multiplexer/docker
docker compose build          # Image mit zellij + zsh-Setup + Cosmo-Config
docker compose run --rm agent # oder: desktop · builder · vps · monitor
```

Im Image ist alles vorkonfiguriert: Zellij, das Zsh-Setup (`SHELL=/usr/bin/zsh`), das Projekt-Root wird nach `/work` gemountet, Teststrassen-Captures landen im Volume `cosmo-captures`. Ohne Compose:

```bash
docker build -t devkitz/cosmo-mux -f docker/Dockerfile .
docker run -it --rm -v "$PWD":/work devkitz/cosmo-mux builder
```

---

## 3. Erste Schritte: der `cosmo` Launcher

`cosmo help` zeigt alles (echte Ausgabe):

```
  ██████╗ ██████╗ ███████╗███╗   ███╗ ██████╗
 ██╔════╝██╔═══██╗██╔════╝████╗ ████║██╔═══██╗   COSMO_V2 MULTIPLEXER
 ...
Nutzung: cosmo <profil> [args]

  desktop   Arbeitsplatz  (Editor · Monitor · Logs)
  vps       VPS-Steuerung (SSH · Docker · Uplink)
  agent     Agenten-Basis (Dirigent · Swarm · Webhooks)
  builder   Multi-Builder + Teststrassen-Erfassung
  monitor   Monitoring / Security (Grid · Logs)

  ls          laufende Cosmo-Sessions
  kill <name> Session beenden
  attach <n>  an Session anhaengen
  config      Pfade anzeigen
```

Jedes Profil startet eine **benannte Session** (`cosmo-desktop`, `cosmo-agent`, …). Das heißt:

```bash
cosmo builder            # starten
# ... Ctrl+o dann d  →  Session detachen (laeuft weiter!)
cosmo ls                 # zeigt: cosmo-builder [Created ...]
cosmo attach cosmo-builder   # wieder anhaengen — alles laeuft noch
cosmo kill cosmo-builder     # beenden
```

Konfiguriert wird über `~/.config/cosmo/env` (wird automatisch geladen) — dort trägst du VPS-Hosts, Build-Befehle usw. ein. Details pro Profil unten.

---

## 4. Die 5 Profile im Detail

### 4.1 🏠 `cosmo desktop` — Arbeitsplatz

**Tabs:** `HAUPTDECK` · `DATEIEN` · `LOGS`

```
┌ HAUPTDECK ──────────────────────────────────────┐
│ ┌──────────────────┐ ┌───────────────────────┐ │
│ │                  │ │ SYSMON (btop/htop)    │ │
│ │  EDITOR (60%)    │ ├───────────────────────┤ │
│ │                  │ │ SHELL                 │ │
│ └──────────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────┘
```

- **EDITOR** öffnet `$EDITOR` (Fallback: nano → vi → Shell) im aktuellen Verzeichnis
- **SYSMON** nimmt das beste verfügbare Tool: `btop` → `htop` → `top`
- Tab **DATEIEN**: Dateimanager (`lf`/`ranger`/Fallback `ls`) + Git-Status-Pane
- Tab **LOGS**: `journalctl -f` (Fallback: syslog → Shell)

**Typischer Ablauf:** `cosmo desktop` → im Editor arbeiten → `Ctrl+p` `→` in die Shell wechseln → `Alt+4` öffnet bei Bedarf einen Builder-Tab dazu.

### 4.2 🌐 `cosmo vps` — VPS-Steuerung

**Tabs:** `SERVER` · `DOCKER` · `UPLINK`

Vorbereitung in `~/.config/cosmo/env`:
```bash
export COSMO_VPS_HOSTS="root@203.0.113.10 admin@vps.example.com"
export COSMO_VPS_PING="203.0.113.10"     # Ziel fuer das Ping-Pane
```

- **SERVER**: zwei SSH-Panes nebeneinander — Slot 1 und 2 aus `COSMO_VPS_HOSTS` (mit `ServerAliveInterval=30`, bricht die Verbindung ab, landet man in einer Shell). Ohne Konfiguration fragt das Pane interaktiv nach `user@host`.
- **DOCKER**: `docker ps` als Live-Tabelle (watch) + `docker stats`
- **UPLINK**: Netz-Monitor (`bmon`/`nload`/Fallback `ss`) + Dauer-Ping

💡 **Broadcast auf beide Server** (gleicher Befehl auf allen Panes): `Ctrl+t` → `s` (Sync-Tab) — tippen — `Ctrl+t` → `s` wieder aus.

### 4.3 🤖 `cosmo agent` — Agenten-Basis

Der Terminal-Nachbau des Agent-Workspace-Prototyps. **Tabs:** `ORCHESTRATOR` · `SWARM`

```
┌ ORCHESTRATOR ───────────────────────────────────┐
│ ┌ DIRIGENT ──────┐ ┌ AGENT-RUNNER ────────────┐ │
│ │ Status-Panel   │ │ $COSMO_AGENT_CMD         │ │
│ └────────────────┘ └──────────────────────────┘ │
│ ┌ nanoCHAT ──────────┐ ┌ WEBHOOKS ────────────┐ │
│ │ Chat-Shell         │ │ Live-Feed            │ │
│ └────────────────────┘ └──────────────────────┘ │
└─────────────────────────────────────────────────┘
```

Ohne Konfiguration zeigen die Panels eine Simulation (wie der Prototyp). **Echte Datenquellen** einhängen:

```bash
export COSMO_AGENT_CMD="python orchestrator.py"                 # dein Agent-Prozess
export COSMO_AGENT_STATUS_URL="http://localhost:8080/status"    # DIRIGENT curlt das
export COSMO_WEBHOOK_LOG="/var/log/cosmo/webhooks.log"          # WEBHOOKS tailt das
export COSMO_SWARM_LOG="/var/log/cosmo/swarm.log"               # SWARM-Tab tailt das
```

Echte Panel-Ausgabe (getestet):
```
╔═ COSMO AGENT // DIRIGENT ═══════════════════════
  Target      : pi-agent
  Swarm       : ONLINE (nanobot)
  A2A Traffic : 51.9 MB/s
  A2G Uplink  : ESTABLISHED
```

### 4.4 🏗️ `cosmo builder` — Multi-Builder + Teststrassen

**Tabs:** `BUILD-LANES` (4 parallele Lanes) · `TESTSTRASSE` (Runner + Watch + Capture-Tail) · `DOCKER-BUILD`

Vorbereitung:
```bash
export COSMO_BUILD_A="npm run build"
export COSMO_BUILD_B="cargo build --release"
export COSMO_BUILD_C="make -C lib"
export COSMO_BUILD_D="docker build -t app ."
export COSMO_TEST_CMD="npm test"
export COSMO_WATCH_CMD="npm run test:watch"
```

Beim Start laufen alle vier Lanes **parallel** los, jede erfasst ihren Lauf (→ Kapitel 5). Nach dem Lauf bleibt jede Lane als Shell offen — Befehl anpassen und erneut starten:
```bash
../multiplexer/scripts/testlane.sh lane-a "npm run build -- --prod"
```

### 4.5 🛡️ `cosmo monitor` — Monitoring / Security

Der GRID/FOCUS-View aus dem Prototyp. **Tabs:** `GRID` · `GLOBAL-LOGS`

- **GRID**: 4 Panes — System (btop) · Netzwerk (bmon/ss) · Security (letzte Logins + Auth-Failures) · Disk (df + größte Verzeichnisse)
- **GLOBAL-LOGS**: alles was das System hergibt (`journalctl -f`)

Auf dem VPS besonders nützlich: `cosmo monitor` starten, detachen, und bei Bedarf per `cosmo attach cosmo-monitor` reinschauen.

---

## 5. Teststrassen-Erfassung (Workflow)

Das Herzstück des Builder-Profils: `scripts/testlane.sh` führt Befehle aus und **protokolliert alles automatisch** — live sichtbar UND als Datei.

### Ein Lauf, Schritt für Schritt (echte Ausgabe)

```bash
$ multiplexer/scripts/testlane.sh demo-ok "echo baue...; sleep 1; echo fertig"
╔═ COSMO TESTSTRASSE // demo-ok ═══════════════════════
  cmd : echo baue...; sleep 1; echo fertig
  log : multiplexer/.captures/demo-ok-20260710-015747.log
╚══════════════════════════════════════════════════════
01:57:47 | baue...
01:57:48 | fertig
✔ demo-ok OK  (1s, exit 0)
```

Bei Fehlern wird der **Exit-Code durchgereicht** (wichtig für Skripte/CI):

```bash
$ multiplexer/scripts/testlane.sh demo-fail "echo starte; exit 3"
01:57:49 | starte
✘ demo-fail FAIL (1s, exit 3)
$ echo $?
3
```

### Auswertung

Jeder Lauf erzeugt zwei Dinge in `multiplexer/.captures/`:
1. `<lane>-<timestamp>.log` — komplettes Protokoll, jede Zeile mit Zeitstempel
2. eine Zeile in `summary.jsonl`:

```json
{"lane":"demo-ok","ts":"20260710-015747","status":"pass","exit":0,"duration_s":1,"log":"..."}
{"lane":"demo-fail","ts":"20260710-015748","status":"fail","exit":3,"duration_s":1,"log":"..."}
```

Damit geht z.B.:
```bash
testlane.sh --summary                                  # alle Laeufe
testlane.sh --tail                                     # letztes Log verfolgen
jq -r 'select(.status=="fail") | .lane' summary.jsonl  # was ist rot?
jq -s 'group_by(.lane) | map({lane: .[0].lane, avg: (map(.duration_s)|add/length)})' summary.jsonl   # Ø-Dauer je Lane
```

Im Zsh-Setup gibt es dafür den Alias **`lanes`** (= `testlane.sh --summary`).

### Eigene Teststrasse bauen

Beliebig viele Stationen hintereinander — bricht bei der ersten roten Station ab:
```bash
#!/usr/bin/env bash
T=multiplexer/scripts/testlane.sh
"$T" lint   "npm run lint"      && \
"$T" build  "npm run build"     && \
"$T" unit   "npm test"          && \
"$T" e2e    "npx playwright test"
echo "Strasse fertig: $?"
```

---

## 6. Das Perfect Zsh Setup

Umsetzung von **„The Perfect Zsh Setup For 2026"** ([Video](https://www.youtube.com/watch?v=1jE7rCvByHg)) im Matrix-Look. Installation:

```bash
multiplexer/shell/install-shell.sh
zsh    # erster Start: zinit klont die Plugins automatisch (einmalig)
```

### Was du danach hast (alles real getestet ✔)

| Feature | Bedienung | Was passiert |
|:--|:--|:--|
| **Autosuggestions** | einfach tippen | Grauer Ghost-Text schlägt Befehle aus deiner History vor — `→` übernimmt |
| **Syntax-Highlighting** | einfach tippen | Gültige Befehle **grün**, Tippfehler **rot** — Fehler siehst du VOR Enter |
| **fzf-tab** | `Tab` | Vervollständigung als Fuzzy-Suchmenü; bei `cd` mit Verzeichnis-**Preview** |
| **History-Suche** | `Ctrl+R` | Fuzzy-Suche über die ganze History (Matrix-farbig) |
| **Datei-Picker** | `Ctrl+T` | Fuzzy-Dateiauswahl direkt in die Kommandozeile |
| **Prefix-History** | `Ctrl+P`/`Ctrl+N` | Nur Befehle, die so anfangen wie das Getippte |
| **zoxide** | `cd mux` | Springt nach `~/dkz-ai_chat/multiplexer`, wenn du mal dort warst |
| **sudo-Toggle** | `ESC` `ESC` | Setzt `sudo` vor die aktuelle/letzte Zeile |
| **Matrix-Prompt** | — | `┌─[user@host] ~/pfad (branch)` / `└─▶` — Pfeil rot nach Fehler |

Aliases (Auszug aus `shell/aliases.zsh`):
```bash
ll        # eza -lah mit Git-Status-Spalte
lt        # Verzeichnisbaum (eza --tree)
cat       # bat mit Syntax-Highlighting
gs / gl   # git status -sb / git log --graph
cxa cxb cxd cxm cxv   # cosmo agent/builder/desktop/monitor/vps
lanes     # Teststrassen-Zusammenfassung
```

### History-Tuning (aus dem Video)

10.000 Einträge, **geteilt zwischen allen offenen Panes** (`sharehistory` — perfekt im Multiplexer!), Duplikate werden gelöscht (`HISTDUP=erase` + `hist_ignore_all_dups`), Befehle mit führendem Leerzeichen bleiben privat (`hist_ignore_space`).

### Gemessene Startzeit

Mit **allen** Plugins geladen: **~103 ms** (Cloud-Container, 4 Kerne). Zum Vergleich: volles Oh-My-Zsh liegt typisch bei 400 ms+. zinit lädt asynchron — die Shell ist sofort benutzbar.

### Optionale Extras

- **Starship-Prompt**: `cargo install starship` — die Matrix-Config (`shell/starship.toml`) wird automatisch benutzt, inkl. Git-Status, Node/Rust/Python-Version, Befehlsdauer
- **Atuin** (durchsuchbare Sync-History wie im Agent-Prototyp): `cargo install atuin` — übernimmt Ctrl+R automatisch

Fehlt eins davon: Fallbacks greifen, nichts bricht.

---

## 7. Zellij bedienen: Panes, Tabs, Sessions

Zellij zeigt die Tasten **immer unten in der Statusleiste** — man muss nichts auswendig lernen. Grundmuster: `Ctrl+<modus>` aktiviert einen Modus, dann Einzeltasten, `Enter`/`Esc` zurück.

| Kombination | Aktion |
|:--|:--|
| `Ctrl+p` dann `n` / `d` / `r` | **Pane** neu (rechts/unten) / umbenennen |
| `Ctrl+p` dann `←↑↓→` | Pane-Fokus bewegen |
| `Ctrl+p` dann `x` | Pane schließen |
| `Ctrl+p` dann `f` | Pane als Fullscreen togglen (≙ FOCUS-View!) |
| `Ctrl+t` dann `n` | neuer **Tab** |
| `Ctrl+t` dann `1..9` | Tab wechseln |
| `Ctrl+t` dann `s` | **Sync-Tab**: Eingabe geht an ALLE Panes (Broadcast) |
| `Ctrl+n` dann `←↑↓→` | Pane **vergrößern/verkleinern** |
| `Ctrl+s` | **Scroll-Modus** (`/` = suchen!) |
| `Ctrl+o` dann `d` | **Detach** — Session läuft im Hintergrund weiter |
| `Ctrl+q` | Zellij beenden |
| `Alt+1` … `Alt+5` | 🟢 Cosmo: neuen Tab mit Profil-Layout (desktop/vps/agent/builder/monitor) |

**Die Alt-Shortcuts sind der Trick:** du bist im Desktop-Profil und brauchst kurz die Build-Lanes? `Alt+4` — ein `BUILDER`-Tab öffnet sich **in derselben Session** (technisch: die Einzel-Tab-Layouts `layouts/*-tab.kdl`). Prototyp-Feeling: Profile wie im Vanilla-JS-Dashboard umschalten.

> ✔ Verifiziert mit **zellij 0.44.3**: Config-Check bestanden, alle 5 Profile als echte Sessions gestartet (Tabs `ORCHESTRATOR`/`SWARM` etc. korrekt), Alt-Shortcut-Mechanik live in eine laufende Session getestet.

**Floating Panes** (schwebendes Terminal über allem): `Ctrl+p` dann `w`.

---

## 8. Die Prototypen-Galerie

Alle Original-Prototypen liegen in [`prototypes/`](prototypes/) — Einstieg über **`prototypes/index.html`** (Matrix-Galerie, einfach im Browser öffnen):

| Datei | Inhalt | Offline? |
|:--|:--|:--|
| `zellij_matrix_dashboard.html` | Zellij-UI mit GSH-Shell (`help`, `status`, `matrix`, `nav`) | CDN nötig |
| `cosmo_agent_workspace.html` | Dirigent · Nanobot-Canvas-Schwarm · Keras · Webhooks · nanoChat | CDN nötig |
| `cosmo_vanilla_js_dashboard.html` | Profile Home/DevOps/Security · Layouts Split/Grid/Focus | CDN nötig |
| `3x_canvas_dashboard.html` | Canvas-Engine: SPLIT/GRID/FOCUS pur gerendert | ✔ offline |
| `canvas_praesentation.html` | 3 animierte Slides (Klick/Pfeiltaste) | ✔ offline |

Die drei CDN-Varianten laden Tailwind von `cdn.tailwindcss.com` und brauchen daher Internet.

---

## 9. Troubleshooting

**`cosmo: command not found`** → `~/.local/bin` fehlt im PATH: `export PATH="$HOME/.local/bin:$PATH"` in die Shell-RC. Unter Windows: neues Terminal öffnen (PATH wird beim Start gelesen).

**zellij-Installation schlägt fehl (GitHub-Releases blockiert/403)** → Alternative: `cargo install zellij --locked` (baut aus crates.io, dauert ~15 min) oder Distro-Paket (`pacman -S zellij`, `brew install zellij`).

**Session hängt / Layout kaputt** → `cosmo kill cosmo-<profil>` und neu starten. Alle Sessions: `zellij list-sessions`, aufräumen: `zellij delete-all-sessions`.

**Pane zeigt `btop: command not found`-Ähnliches** → nichts kaputt: die Layouts haben Fallback-Ketten (btop→htop→top). Fehlt alles, bleibt eine Shell. Tools nachinstallieren: `apt install btop lf bmon`.

**Zsh: Plugins laden nicht (erster Start offline)** → zinit braucht einmalig GitHub-Zugriff. Später erneut: `zinit self-update && exec zsh`. Die Shell läuft auch ohne Plugins.

**fzf Ctrl+R geht nicht** → In Containern fehlt oft `/usr/share/doc` — deshalb hat die zshrc ein **eingebautes** Fallback-Widget; `exec zsh` nach Updates. Prüfen: `bindkey '^r'` → sollte `fzf-history-widget` zeigen.

**WSL: `cosmo` aus PowerShell startet nicht** → testen mit `wsl -- bash -lic "cosmo help"`. Falls die Distro nicht Standard ist: `install.ps1 -Distro <name>` erneut ausführen.

**Docker: Panes sofort zu** → Interaktivität fehlt: `docker compose run --rm <profil>` verwenden (setzt `-it`), nicht `docker compose up`.

---

*MIT © DEVKiTZ™ · Teil des `dkz-ai_chat` Moduls · Quelle Zsh-Setup: [The Perfect Zsh Setup For 2026](https://www.youtube.com/watch?v=1jE7rCvByHg)*
