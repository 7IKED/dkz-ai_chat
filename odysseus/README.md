# 🛰️ OPEN AI TERMINAL // DEVKiTZ Version 2 & 3

> Das geschlossene System: Gitea · **OpenCloud** · Immich · Chat **mit Werkzeugen** · KeePass-Vault · Atuin · Voicebox — alles FOSS, alles lokal, alles im Matrix-Terminal (schwarz / neon-grün). Mit **Cloud Design System**, **Repo-Visualisierung** und **`oat://`-URI-Handler**.

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
                 │   OPEN AI TERMINAL (127.0.0.1, zu)       │
   Matrix-       │                                          │
   Terminal ──── │  GITEA :3300  ◄── A2A-Bus (Webhooks)     │
   (zellij)      │    │  alles in einem Gitea: Code+Issues  │
     │           │  OPENCLOUD :9200 ──┐                     │
     ├ BRIDGE    │  IMMICH :2283 ◄────┘ (Foto-Oberflaeche,  │
     ├ GITVIZ    │            liest OpenCloud-Dateien ro)   │
     ├ CLOUD     │  LIBRECHAT :3080  (nanoChat, Ollama)     │
     ├ GITEA     │  ATUIN :8888      (History/Logs-Sync)    │
     └ LOGS      │  VOICEBOX :10200  (Piper TTS, deutsch)   │
                 │  VAULT (KeePass .kdbx — Agenten-Keys)    │
                 └──────────────────────────────────────────┘
                        ▲                    ▲
                 oat://…│         ein Design │ design/tokens.json
                 URI-Handler        fuer alles│ → CSS · Shell · Zellij
```

| Dienst | Software | Lizenz | Zweck |
|:--|:--|:--|:--|
| GITEA | gitea | MIT | Zentrum: Code, Issues, **A2A-Webhooks** |
| **OPENCLOUD** | opencloud | **Apache-2.0** | **Dateien/Sync/Freigaben** — Single-Binary, kein PHP |
| IMMICH | immich | AGPL | **Foto-Oberfläche** (liest OpenCloud read-only) |
| nanoCHAT | LibreChat | MIT | Chat-UI + API, lokale Modelle via Ollama |
| ATUIN | atuin server | MIT | Shell-History/**Logs aller Agenten** |
| VOICEBOX | Piper TTS (wyoming) | MIT | Text→Sprache (`odysseus say "..."`) |
| VAULT | KeePassXC (.kdbx) | GPL | **Agenten-Zugangsdaten & API-Keys** |
| _NEXTCLOUD_ | nextcloud | AGPL | _optional_ — `odysseus up --nextcloud` |

**Warum OpenCloud als Cloud:** ein Go-Binary statt PHP+Apache, startet in Sekunden,
braucht keinen eigenen DB-Container und bringt einen offiziellen Theme-Mechanismus mit
— dadurch trägt das Cloud Design System dort sauber. Nextcloud bleibt als Profil
erhalten, falls die App-Landschaft gebraucht wird. Der POSIX-Speichertreiber ist
gesetzt (`STORAGE_USERS_DRIVER: posix`), damit die Dateien als **normaler Baum** auf
der Platte liegen und Immich sie als External Library lesen kann.

## 🚀 Version 2 — Installation & Start

```bash
# Linux/WSL (Windows: ./install.ps1 → C:\DEVKiTZ\odysseus)
./install.sh                 # → ~/DEVKiTZ/odysseus + `odysseus` im PATH
                             #   baut das Design System, fragt nach oat://

cd ~/DEVKiTZ/odysseus
nano .env                    # ADMIN_PASS setzen!
odysseus up                  # Stack hochfahren (11 Dienste)
odysseus init                # Gitea: Admin + Org DEVKITZ + Repo + Push
odysseus design apply        # Matrix-Look in die Web-UIs tragen
odysseus                     # das Matrix-Terminal (5 Tabs)
```

**Terminal-Tabs:** `BRIDGE` (Status-Watch · Operator-Shell · **Chat mit Werkzeugen** · Vault) · `GITVIZ` (Commit-Graph · Aktivität · Repos live) · `CLOUD` (OpenCloud + Fotos im Terminal-Browser) · `GITEA` (Git + A2A-Inbox) · `LOGS` (Stack-Logs + Atuin).

### Agenten & ihre Keys (Vault)

```bash
odysseus vault init                          # .kdbx anlegen
odysseus vault set api/openrouter            # Key speichern (Prompt)
odysseus vault get api/openrouter            # Key holen
eval "$(odysseus vault agent-env api/openrouter api/xai)"   # → $API_OPENROUTER_KEY
```

Agenten setzen `ODYSSEUS_VAULT_PW` (z.B. aus systemd-creds) und ziehen sich ihre Keys selbst — **keine Klartext-.env für API-Keys**.

### Chat **mit Werkzeugen** (A2A inklusive)

Das Modell im Terminal redet nicht nur — es kann das System **abfragen**.

```bash
odysseus chat                                # REPL mit Werkzeugen
odysseus chat ask "Welche Dienste sind unten?"
odysseus tools list                          # welche Werkzeuge gibt es
odysseus tools schema anthropic              # Tool-Definitionen als JSON
odysseus tools call git_log '{"limit":5}'    # Werkzeug direkt (zum Testen)
odysseus chat a2a coder "Review lane-a"      # Nachricht an Agent 'coder'
odysseus chat inbox coder                    # dessen Inbox (live tail)
```

**12 Werkzeuge**, davon 10 rein lesend und sofort nutzbar:
`system_status` · `git_repos` · `git_log` · `git_activity` · `git_issues` ·
`cloud_list` (OpenCloud via WebDAV) · `skills_list` · `skills_registry` ·
`vault_list` (nur Namen, **nie** Werte) · `say`.
Verändernde Werkzeuge (`a2a_send`, `skills_import`) sind **standardmäßig aus** —
`OAT_TOOLS_ALLOW_WRITE=1` schaltet sie frei, und selbst dann wird nachgefragt.

Grenzen, die im Code stehen: kein Werkzeug führt beliebige Shell-Befehle aus,
jedes Argument wird gegen Metazeichen und `..` geprüft, nichts geht je durch
eine Shell, und die Werkzeug-Schleife bricht nach `OAT_TOOLS_MAX_ROUNDS` (6) ab.

Backend: Ollama (`/api/chat` mit `tools[]`). Schema-Export auch im
Anthropic-Format, falls die Werkzeuge an einem anderen Modell hängen sollen.
Gitea-Webhooks (push/issue) können auf eigene Handler zeigen → der A2A-Bus läuft
**im** geschlossenen System.

## 🎨 Cloud Design System

Ein Token-Satz für **alles** — Terminal, Zellij-Theme und jede Web-UI.

```bash
odysseus design build        # tokens.json → CSS · Shell-Farben · Zellij-Theme
odysseus design check        # CI: bricht ab, wenn Tokens auseinanderlaufen
odysseus design apply        # Matrix-Look in die laufenden Web-UIs tragen
odysseus design styleguide   # lebendes Styleguide öffnen
```

`design/tokens.json` ist die einzige Stelle, an der eine Farbe steht. Daraus
entstehen `dist/oat-cloud.css` (Web), `dist/oat-tokens.sh` (ANSI-256 für die
Shell-Skripte — `gitviz`, `uri` und `chat-tools` benutzen sie wirklich) und
`dist/oat-matrix.kdl` (Zellij). Details: [`design/README.md`](design/README.md).

## 📊 GITVIZ — Repos sichtbar machen

```bash
odysseus gitviz              # Übersicht: Gitea-Repos + lokales Repo
odysseus gitviz graph        # Commit-Graph, eingefärbt
odysseus gitviz activity     # Commits/Tag als Sparkline (30 Tage)
odysseus gitviz authors      # Autoren als Balken
odysseus gitviz branches     # Branches mit ahead/behind
odysseus gitviz repos        # alle Repos aus Gitea (Issues, Sterne, Größe)
odysseus gitviz issues DEVKITZ/odysseus
```

```
  ······▂·█······▄▂·············
  vor 30 Tagen         heute
  47 Commits in 30 Tagen   1.6 pro Tag im Schnitt
```

Liest die **Gitea-API** (Token aus `$GITEA_TOKEN` oder still aus dem Vault:
`api/gitea`) und das lokale Git. Ohne Gitea zeigt es trotzdem alles Lokale.

## 🔗 `oat://` — Links landen im Terminal

Ein Link in einem Gitea-Issue, einer Chat-Nachricht oder einer Notiz öffnet die
richtige Stelle **im Terminal** statt im Browser.

```bash
odysseus uri install                    # als Systemhandler registrieren
odysseus uri list                       # alle unterstützten URIs
odysseus uri test 'oat://gitviz/graph'  # Trockenlauf
```

| URI | Wirkung |
|:--|:--|
| `oat://repo/DEVKITZ/odysseus` | Repo/Issues in GITVIZ |
| `oat://gitviz/activity` | Aktivitätsansicht |
| `oat://commit/<sha>` | Commit anzeigen |
| `oat://cloud/Projekte` | Ordner in OpenCloud |
| `oat://chat/coder` | Chat mit Werkzeugen |
| `oat://a2a/coder?msg=…` | Nachricht in die A2A-Inbox |
| `oat://say?text=…` | Voicebox |
| `oat://status` · `oat://terminal` | Status · Terminal |

**Sicherheit:** Ein URI-Handler ist eine Tür von außen — jede Webseite kann
`oat://…` aufrufen. Deshalb: feste Whitelist (es gibt **kein** `oat://run/…`),
Argumente werden nach dem Dekodieren gegen Shell-Metazeichen, `..` und
führende `-` geprüft, nichts wird je an eine Shell gereicht, und alles
Verändernde (`skills`, `vault`) fragt nach.

Registriert wird unter Linux per `.desktop` + `xdg-mime`, unter Windows per
erzeugter `oat-uri.reg` (WSL + Windows Terminal).

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

## 🧠 Skill-System (Repo/YouTube → Skills + Workflows)

Ein Link genügt — Odysseus übernimmt alle Skills und erzeugt sofort nutzbare Workflows.

```bash
odysseus skills https://github.com/obra/superpowers   # Repo → Skills + FLOWS.md
odysseus skills https://youtu.be/1jE7rCvByHg          # YouTube → Skill-Gerüst + FLOWS
odysseus skills --pack obsidian-skills                 # aus der Registry
odysseus skills --all-registry                         # alle 43 Packs
odysseus skills --link /pfad/zu/devkitz-workspace      # lokales Verzeichnis filtern
odysseus skills --list                                 # was ist installiert
```

Jede `SKILL.md` wird **kollisionssicher** (Pack-Prefix bei Namensgleichheit) nach `~/.claude/skills/` verlinkt; pro Pack entsteht eine **`FLOWS.md`** mit 3-Schritt-Workflows je Skill. Der gleichnamige Skill [`import-skills`](skills/import-skills/SKILL.md) macht das aus dem Chat heraus (`/import-skills <url>`) und koppelt an `writing-great-skills` (Skill-Builder) aus `7IKED/skills`.

**Registry:** [`skills/registry/packs.tsv`](skills/registry/packs.tsv) — **43 per GitHub-API verifizierte Packs**: superpowers (+lab/skills), anthropics/skills, Matt Pocock, beastmode, Trail-of-Bits-Security (7 Security-Packs), Obsidian (3), llm-wiki (2), DevOps/SRE (5), Data-Science/Science (5), SEO/Marketing (5), YouTube/Video (3), Mobile/Frontend, Anti-Slop-Writing (3), u.a.

**DEVKITZ-Filter:** Dein `7IKED/devkitz-workspace` klonen und `odysseus skills --link <pfad>` — alle dortigen `SKILL.md` werden gefiltert übernommen (Duplikate durch Pack-Prefix entschärft), sodass die „überall brauchbaren" Skills einheitlich unter `~/.claude/skills/` landen. Der Workflow-Builder (`FLOWS.md`) und der Skill-Builder (`writing-great-skills`) sind so verbunden.

## 📁 Struktur

```
odysseus/
├── bin/odysseus            # Launcher (terminal·up·init·gitviz·chat·uri·design·vault·skills)
├── docker-compose.yml      # der geschlossene Stack (11 Dienste + Profil nextcloud)
├── .env.example            # Vorlage (→ .env, nie committet)
├── config/                 # zellij-config · librechat.yaml · vault.Dockerfile
├── layouts/odysseus.kdl    # Terminal (BRIDGE·GITVIZ·CLOUD·GITEA·LOGS)
├── design/                 # 🎨 Cloud Design System
│   ├── tokens.json         #    die einzige Stelle mit Farben
│   ├── build.sh            #    → dist/ (CSS · Shell · Zellij)
│   ├── apply-theme.sh      #    Theme in laufende Container tragen
│   ├── styleguide.html     #    lebendes Styleguide
│   ├── css/ · themes/      #    Bauteile · OpenCloud/Nextcloud/Gitea/LibreChat
│   └── dist/               #    gebaut (nicht im Repo)
├── scripts/
│   ├── gitviz.sh           # 📊 Repo-Visualisierung (Gitea-API + lokales Git)
│   ├── uri.sh              # 🔗 oat://-Handler (+ install für Linux/Windows)
│   ├── chat-tools.sh       # 🛠️ Chat mit Werkzeugen (Tool-Calling)
│   └── vault · nanochat(A2A) · voice · browser · gitea-init · ctl · skill-import
├── skills/                 # import-skills Skill · registry/packs.tsv (43 Packs)
├── install.sh / install.ps1  # Linux · Windows (C:\DEVKiTZ\odysseus)
└── exe/                    # Version 3: main.go + build-exe.sh → dist/
```

## ✅ Was in dieser Session real geprüft wurde

| Geprüft | Wie |
|:--|:--|
| Design-Build | `build.sh` läuft: 65 Tokens, 60 CSS-Variablen, Abgleich grün |
| Zellij-Theme | erzeugtes `oat-matrix.kdl` von **zellij 0.44.3** akzeptiert |
| Terminal-Layout | 5-Tab-Layout als echte zellij-Session gestartet |
| Compose | `docker compose config` valide — 11 Dienste, Profil `nextcloud` greift |
| GITVIZ | `graph`, `activity`, `authors`, `branches` gegen dieses Repo gelaufen |
| URI-Handler | 6 gültige URIs im Trockenlauf, **13 Einschleusungsversuche abgewehrt** |
| Chat-Werkzeuge | Tool-Schleife end-to-end gegen einen Ollama-Stellvertreter: Modell fordert `git_log` an → Werkzeug läuft → Antwort mit echten Commit-Daten |
| Werkzeug-Härtung | Schreibwerkzeuge gesperrt, Argument-Einschleusung abgewiesen |
| Installation | `install.sh` in ein leeres Ziel: Launcher, `dist/`, `.env` erzeugt |

**Nicht geprüft:** das Anwenden auf laufende Container und OpenCloud selbst — in
dieser Umgebung lassen sich keine Images ziehen (Registry gesperrt). Compose ist
syntaktisch validiert; `apply-theme.sh` prüft jeden Schritt einzeln und meldet
Fehlschläge, statt Erfolg zu behaupten.

MIT © DEVKiTZ™ — Komponenten unter ihren jeweiligen freien Lizenzen (MIT/Apache-2.0/AGPL/GPL).
