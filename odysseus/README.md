# 🛰️ ODYSSEUS // DEVKiTZ Version 2 & 3

> Das geschlossene System: Gitea · Nextcloud · Immich · nanoChat (LibreChat) · KeePass-Vault · Atuin · Voicebox — alles FOSS, alles lokal, alles im Matrix-Terminal (schwarz / neon-grün).

```
 ██████╗ ██████╗ ██╗   ██╗███████╗███████╗███████╗██╗   ██╗███████╗
██╔═══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██╔════╝██╔════╝██║   ██║██╔════╝
██║   ██║██║  ██║ ╚████╔╝ ███████╗███████╗█████╗  ██║   ██║███████╗
██║   ██║██║  ██║  ╚██╔╝  ╚════██║╚════██║██╔══╝  ██║   ██║╚════██║
╚██████╔╝██████╔╝   ██║   ███████║███████║███████╗╚██████╔╝███████║
 ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝
```

## 🧭 Die drei Versionen

| Version | Was | Wo |
|:--|:--|:--|
| **1 — Cosmo Multiplexer** | Zellij-Profile + Perfect Zsh (bleibt wie sie ist) | [`../multiplexer/`](../multiplexer/) |
| **2 — Odysseus Terminal** | Geschlossenes Komplett-System in **einem Gitea** | dieses Verzeichnis |
| **3 — Single-File** | `odysseus.exe` / `odysseus-linux` — **eine Datei**, entpackt & startet alles | [`exe/`](exe/) |

## 🏗️ Architektur (alles lizenzfrei/FOSS)

```
                 ┌──────────────────────────────────────────┐
                 │       ODYSSEUS (127.0.0.1, geschlossen)  │
   Matrix-       │                                          │
   Terminal ──── │  GITEA :3300  ◄── A2A-Bus (Webhooks)     │
   (zellij)      │    │  alles in einem Gitea: Code+Issues  │
     │           │  NEXTCLOUD :8081 ──┐                     │
     ├ BRIDGE    │  IMMICH :2283 ◄────┘ (Foto-Oberflaeche,  │
     ├ BROWSER   │            liest Nextcloud-Daten ro)     │
     ├ GITEA     │  LIBRECHAT :3080  (nanoChat, Ollama)     │
     └ LOGS      │  ATUIN :8888      (History/Logs-Sync)    │
                 │  VOICEBOX :10200  (Piper TTS, deutsch)   │
                 │  VAULT (KeePass .kdbx — Agenten-Keys)    │
                 └──────────────────────────────────────────┘
```

| Dienst | Software | Lizenz | Zweck |
|:--|:--|:--|:--|
| GITEA | gitea | MIT | Zentrum: Code, Issues, **A2A-Webhooks** |
| NEXTCLOUD | nextcloud | AGPL | Dateien/Sync |
| IMMICH | immich | AGPL | **Foto-Oberfläche** (sieht Nextcloud-Daten) |
| nanoCHAT | LibreChat | MIT | Chat-UI + API, lokale Modelle via Ollama |
| ATUIN | atuin server | MIT | Shell-History/**Logs aller Agenten** |
| VOICEBOX | Piper TTS (wyoming) | MIT | Text→Sprache (`odysseus say "..."`) |
| VAULT | KeePassXC (.kdbx) | GPL | **Agenten-Zugangsdaten & API-Keys** |

## 🚀 Version 2 — Installation & Start

```bash
# Linux/WSL (Windows: ./install.ps1 → C:\DEVKiTZ\odysseus)
./install.sh                 # → ~/DEVKiTZ/odysseus + `odysseus` im PATH

cd ~/DEVKiTZ/odysseus
nano .env                    # Passwoerter setzen!
odysseus up                  # Stack hochfahren
odysseus init                # Gitea: Admin + Org DEVKITZ + Repo + Push
odysseus                     # das Matrix-Terminal (4 Tabs)
```

**Terminal-Tabs:** `BRIDGE` (Status-Watch · Operator-Shell · nanoChat · Vault) · `BROWSER` (Dienste im Terminal-Browser: carbonyl/browsh/w3m/lynx) · `GITEA` (Git + A2A-Inbox) · `LOGS` (Stack-Logs + Atuin).

### Agenten & ihre Keys (Vault)

```bash
odysseus vault init                          # .kdbx anlegen
odysseus vault set api/openrouter            # Key speichern (Prompt)
odysseus vault get api/openrouter            # Key holen
eval "$(odysseus vault agent-env api/openrouter api/xai)"   # → $API_OPENROUTER_KEY
```

Agenten setzen `ODYSSEUS_VAULT_PW` (z.B. aus systemd-creds) und ziehen sich ihre Keys selbst — **keine Klartext-.env für API-Keys**.

### A2A & nanoChat

```bash
odysseus chat                                # Chat-REPL (Ollama lokal)
odysseus chat a2a coder "Review lane-a"      # Nachricht an Agent 'coder'
odysseus chat inbox coder                    # dessen Inbox (live tail)
```
Gitea-Webhooks (push/issue) können per URL auf eigene Handler zeigen → der A2A-Bus läuft **im** geschlossenen System.

### Geschlossenes System

Alle Ports binden **nur 127.0.0.1**. Nach dem Ersteinrichten: Registrierungen schließen (`GITEA__service__DISABLE_REGISTRATION=true`, `ALLOW_REGISTRATION=false`, `ATUIN_OPEN_REGISTRATION=false`) — dann braucht und akzeptiert das System kein Internet mehr (Modelle/Images einmalig laden bzw. per `docker save/load` einspielen).

## 📦 Version 3 — Single-File

```bash
cd exe && ./build-exe.sh
# → dist/odysseus.exe    (Windows, PE32+, ~2 MB)
# → dist/odysseus-linux  (Linux, statisch, ~2 MB)
```

Eine Datei = komplettes System: entpackt sich nach `C:\DEVKiTZ\odysseus` (Windows) bzw. `~/DEVKiTZ/odysseus`, legt `.env` an, startet den Stack (falls Docker da ist) und zeigt die nächsten Schritte. Updates: einfach neue Datei ausführen — `.env` und `data/` werden **nie** überschrieben. Ziel ändern: `ODYSSEUS_TARGET=/pfad odysseus-linux`.

> Getestet: beide Binaries real gebaut (Go, nur Stdlib, MIT); Linux-Binary end-to-end verifiziert (Entpacken → Launcher ausführbar → .env erzeugt → Stack-Start).

## 📁 Struktur

```
odysseus/
├── bin/odysseus            # Launcher (terminal·up·init·vault·chat·say·browse)
├── docker-compose.yml      # der geschlossene Stack (11 Services)
├── .env.example            # Vorlage (→ .env, nie committet)
├── config/                 # zellij-config · librechat.yaml · vault.Dockerfile
├── layouts/odysseus.kdl    # Matrix-Terminal (BRIDGE·BROWSER·GITEA·LOGS)
├── scripts/                # vault · nanochat(A2A) · voice · browser · gitea-init · ctl
├── install.sh / install.ps1  # Linux · Windows (C:\DEVKiTZ\odysseus)
└── exe/                    # Version 3: main.go + build-exe.sh → dist/
```

MIT © DEVKiTZ™ — Komponenten unter ihren jeweiligen freien Lizenzen (MIT/AGPL/GPL).
