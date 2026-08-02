# 🟢 OPEN AI TERMINAL — Release v1.1.0

> DEVKiTZ™ Matrix Terminal System — Multiplexer · geschlossenes Agenten-System · Single-File · Skill-Importer · **Cloud Design System** · **Repo-Visualisierung** · **`oat://`-URI-Handler** · **Chat mit Werkzeugen**. Für Windows · Linux · Docker.

**Präsentation:** https://claude.ai/code/artifact/2282e2e8-3cf0-455f-a787-6125e648339a

---

## Neu in v1.1.0

### 🎨 Cloud Design System (`odysseus/design/`)
Ein Token-Satz für **alles** — Terminal, Zellij-Theme und jede Web-UI.
- `design/tokens.json` ist die **einzige** Stelle, an der eine Farbe steht (65 Tokens)
- `design/build.sh` erzeugt daraus **drei** Ziele: `oat-cloud.css` (Web), `oat-tokens.sh` (ANSI-256 für die Shell-Skripte), `oat-matrix.kdl` (Zellij-Theme)
- `design/build.sh --check` bricht ab, wenn CSS und Tokens auseinanderlaufen (CI-tauglich)
- `themes/inject.css` themt **OpenCloud · Nextcloud · Gitea · LibreChat** — nur über deren CSS-Variablen, keine Selektor-Hacks
- `styleguide.html` — lebendes Styleguide, Farbfelder aus dem echten Build
- Bauteile: `oat-pane` · `oat-card` · `oat-btn` · `oat-input` · `oat-table` · `oat-badge` · `oat-status` · `oat-tabs` · `oat-hud` · `oat-stat` · `oat-meter`

### ☁️ OpenCloud als Cloud-Dienst
- **OpenCloud** (Apache-2.0) ersetzt Nextcloud im Standardstart: ein Go-Binary, kein PHP, kein eigener DB-Container, offizieller Theme-Mechanismus
- `STORAGE_USERS_DRIVER: posix` → Dateien liegen als **normaler Baum**, damit Immich sie als External Library lesen kann
- Matrix-Theme per Bind-Mount (`opencloud.theme.json` + Logo/Favicon)
- **Nextcloud bleibt** als optionales Profil: `odysseus up --nextcloud`

### 📊 GITVIZ — Repo-Visualisierung (`odysseus gitviz`)
- `graph` — Commit-Graph, eingefärbt · `activity` — Sparkline über 30 Tage
- `authors` — Autoren-Balken · `branches` — mit ahead/behind
- `repos` / `issues` — aus der **Gitea-API** (Token aus `$GITEA_TOKEN` oder still aus dem Vault)
- `watch` — Dauerpanel; eigener **GITVIZ-Tab** im Terminal

### 🔗 `oat://` — URI-Handler (`odysseus uri`)
Links aus Gitea, Chat oder Notizen öffnen im **Terminal** statt im Browser.
- 14 Aktionen: `repo` · `commit` · `gitviz` · `cloud` · `fotos` · `chat` · `a2a` · `inbox` · `say` · `skills` · `vault` · `status` · `terminal` · `list`
- Registrierung: Linux `.desktop` + `xdg-mime`, Windows erzeugte `.reg` (WSL + Windows Terminal)
- **Sicherheit:** feste Whitelist (es gibt **kein `oat://run/…`**), Argumente werden nach dem Dekodieren gegen Shell-Metazeichen, `..` und führende `-` geprüft, nichts geht je durch eine Shell, Veränderndes fragt nach

### 🛠️ Chat mit Werkzeugen (`odysseus chat` / `odysseus tools`)
Das lokale Modell fragt das System **wirklich ab**.
- **12 Werkzeuge**, 10 rein lesend: `system_status` · `git_repos` · `git_log` · `git_activity` · `git_issues` · `cloud_list` (OpenCloud/WebDAV) · `skills_list` · `skills_registry` · `vault_list` (nur Namen, **nie** Werte) · `say`
- Verändernde (`a2a_send`, `skills_import`) sind **standardmäßig aus** — `OAT_TOOLS_ALLOW_WRITE=1`, und selbst dann wird nachgefragt
- Schema-Export im Ollama/OpenAI- **und** Anthropic-Format (`odysseus tools schema anthropic`)
- Grenzen im Code: kein Werkzeug führt Shell-Befehle aus, Argumentprüfung wie beim URI-Handler, Schleifenabbruch nach 6 Runden

---

## Die drei Versionen

### Version 1 — Terminal-Multiplexer (`multiplexer/`)
Zellij-Terminal im Matrix-Stil mit 5 Profilen und dem „Perfect Zsh Setup".
- Profile: **desktop · vps · agent · builder · monitor** (`cosmo <profil>`)
- **Teststrassen-Erfassung** (`testlane.sh`): Log + Exit-Code + Dauer → `summary.jsonl`
- Perfect Zsh: zinit, autosuggestions, syntax-highlighting, fzf-tab, zoxide, eza — Start ~103 ms

### Version 2 — Geschlossenes System (`odysseus/`)
Alle Ports nur auf 127.0.0.1, alles in einem Gitea.
- **11 Dienste:** Gitea (Zentrum + A2A-Webhooks), **OpenCloud**, Immich, LibreChat/nanoChat, Atuin, Piper-Voicebox, KeePass-Vault + Backends (+ Nextcloud als Profil)
- Terminal mit 5 Tabs: **BRIDGE · GITVIZ · CLOUD · GITEA · LOGS**
- Terminal-Browser-Kette (carbonyl → browsh → w3m → lynx), A2A-Inbox, Vault-CLI, Voice, Health-Watch

### Version 3 — Single-File (`odysseus/exe/`)
Ein Launcher (Go, nur Stdlib, MIT) mit eingebettetem Komplettsystem.
- **`odysseus.exe`** (Windows, PE32+) → entpackt nach `C:\DEVKiTZ\odysseus`
- **`odysseus-linux`** (statisch) → `~/DEVKiTZ/odysseus`
- `.env` und `data/` werden nie überschrieben — Update = neue Datei ausführen

### Skill-System (`odysseus/skills/`)
- `odysseus skills <repo-oder-youtube-url>` → verlinkt alle SKILL.md + erzeugt FLOWS.md
- **43 per GitHub-API verifizierte Packs** in der Registry
- Skill `/import-skills`, gekoppelt an `writing-great-skills`

---

## Schnellstart

```bash
cosmo desktop                 # V1 — sofort
odysseus up && odysseus       # V2 — geschlossenes System
./odysseus.exe                # V3 — eine Datei

odysseus design apply         # Matrix-Look in die Web-UIs
odysseus gitviz               # Repos sichtbar machen
odysseus uri install          # oat:// im System registrieren
odysseus chat                 # Chat mit Werkzeugen
```

## Verifiziert in dieser Session

| Geprüft | Wie |
|:--|:--|
| Zellij | 0.44.3 Config-Check bestanden · 5 Profile + 5-Tab-Terminal als echte Sessions gestartet |
| Design System | Build läuft (65 Tokens, 60 CSS-Variablen, Abgleich grün); erzeugtes Zellij-Theme von zellij **akzeptiert** |
| Compose | `docker compose config` valide — 11 Dienste, Profil `nextcloud` greift |
| GITVIZ | `graph` · `activity` · `authors` · `branches` gegen dieses Repo gelaufen |
| Chat-Werkzeuge | Tool-Schleife **end-to-end** gegen einen Ollama-Stellvertreter: Modell fordert `git_log` an → Werkzeug läuft → Antwort mit echten Commit-Daten |
| Härtung | **13 Einschleusungsversuche** in URI-Handler und Werkzeug-Argumente abgewehrt |
| Installation | `install.sh` in leeres Ziel: Launcher, `design/dist/`, `.env` erzeugt |
| Binaries | beide gebaut, Linux end-to-end · Skill-Import real · 43 Registry-Packs geprüft |

**Nicht geprüft:** OpenCloud im Betrieb und `design apply` auf laufende Container — in dieser Umgebung lassen sich keine Container-Images ziehen (Registry gesperrt). Die Compose-Konfiguration ist validiert; `apply-theme.sh` prüft jeden Schritt einzeln und meldet Fehlschläge, statt Erfolg zu behaupten.

MIT © DEVKiTZ™ — Drittkomponenten unter ihren jeweiligen freien Lizenzen (siehe LICENSE).
