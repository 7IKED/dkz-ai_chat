# 🎨 Cloud Design System

> Ein Token-Satz für alles: Terminal, Zellij-Theme und jede Web-UI im geschlossenen System.

```
tokens.json ──► build.sh ──┬──► dist/oat-cloud.css    Web (eigene Seiten, Styleguide)
                           ├──► dist/oat-tokens.sh    Shell-Skripte (ANSI-256)
                           └──► dist/oat-matrix.kdl   Zellij-Theme

themes/inject.css ─────────────► OpenCloud · Nextcloud · Gitea · LibreChat
```

Die Regel: **Farben stehen genau an einer Stelle** — `tokens.json`. Wer eine
Farbe ändert, ändert sie dort und baut neu; Terminal und Web ziehen mit.
`build.sh --check` bricht ab, wenn `css/tokens.css` und `tokens.json`
auseinanderlaufen.

## Bauen

```bash
cd odysseus/design
./build.sh            # dist/ erzeugen
./build.sh --check    # nur prüfen (CI-tauglich, kein Schreiben)
```

Keine Abhängigkeiten außer `bash` + `python3` (nur zum JSON-Lesen).

## Verwenden

| Ziel | So |
|:--|:--|
| Eigene HTML-Seite | `<link rel="stylesheet" href="design/dist/oat-cloud.css">` + `<body class="oat-crt">` |
| Shell-Skript | `. "$ODYSSEUS_DIR/design/dist/oat-tokens.sh"` → `${OAT_FG_PRIMARY}`, `${OAT_STATE_ERROR}`, `${OAT_RESET}` |
| Zellij | `dist/oat-matrix.kdl` nach `~/.config/zellij/themes/` → `theme "oat-matrix"` |
| Fremd-UI | `./apply-theme.sh` (siehe unten) |

Styleguide öffnen: `design/styleguide.html` im Browser — die Farbfelder werden
aus den **tatsächlich geladenen** CSS-Variablen erzeugt, zeigen also immer den
echten Build.

## Komponenten

`css/components.css` — bewusst klein, jede Klasse `oat-*`:

`oat-pane` · `oat-card` · `oat-btn` (`--primary` `--danger` `--ghost`) ·
`oat-input` / `oat-field` / `oat-label` / `oat-prompt` · `oat-table` ·
`oat-badge` · `oat-status` · `oat-tabs` · `oat-hud` · `oat-stat` ·
`oat-meter` · `oat-list` · `oat-caret` · Raster (`oat-grid`, `oat-grid-2..4`).

Gestaltungsregeln, die im Code stecken:
- **Eckig.** `--oat-radius: 0`. Rundung nur, wo eine Fremd-UI sie erzwingt.
- **Eine Schrift.** Monospace überall; Hierarchie über Größe, nie über Familie.
- **Fließtext ist nicht neon.** Lange Absätze in `--oat-fg-neutral` (#e5e7eb),
  Neon-Grün für Titel, Prompts, Zustände. `#00FF41` auf Schwarz = 15.3:1 (AAA),
  `#008F11` = 4.6:1 → nur Rahmen/Labels, nie Fließtext.
- **CRT ist Dekoration.** `.oat-crt` ist `pointer-events:none` und schaltet sich
  bei `prefers-contrast: more` ab; Animationen bei `prefers-reduced-motion`.

## Fremd-UIs themen

```bash
./apply-theme.sh            # alle laufenden Dienste
./apply-theme.sh gitea      # einzeln
./apply-theme.sh --status   # was ist gethemt?
```

`themes/inject.css` setzt ausschließlich die **CSS-Variablen** der jeweiligen
UI (`--oc-color-*`, `--color-primary`, `--surface-*` …) — keine Selektor-Hacks.
Das überlebt Updates der Fremdprojekte deutlich besser.

| UI | Weg | Verlässlichkeit |
|:--|:--|:--|
| **OpenCloud** | `themes/opencloud.theme.json` als Bind-Mount (im Compose verdrahtet) | gut — offizieller Theme-Mechanismus |
| **Gitea** | `theme-oat-matrix.css` nach `/data/gitea/public/assets/css/` | gut — offizieller Custom-Theme-Pfad |
| **Nextcloud** | `occ theming:config` + App *Custom CSS* für den Rest | teilweise ohne die App |
| **LibreChat** | baut CSS beim Image-Build → nur per Reverse-Proxy (`sub_filter`) oder Fork | eingeschränkt |

Der OpenCloud-Theme-Satz führt **beide** Token-Familien (`swatch-*`/`background-*`
der älteren ownCloud-Web-Builds und `role-*` der neueren). Unbekannte Schlüssel
ignoriert Web still — so passt dieselbe Datei über Versionen hinweg.

## Struktur

```
design/
├── tokens.json           # Quelle der Wahrheit (65 Tokens)
├── build.sh              # → dist/  ·  --check für CI
├── apply-theme.sh        # Theme in laufende Container tragen
├── styleguide.html       # lebendes Styleguide
├── css/
│   ├── tokens.css        # Custom Properties (--oat-*)
│   ├── base.css          # Reset, Typografie, CRT-Overlay
│   └── components.css    # oat-* Bauteile
├── themes/
│   ├── inject.css        # Variablen-Mapping für OpenCloud/Nextcloud/Gitea/LibreChat
│   ├── opencloud.theme.json
│   └── assets/           # logo.svg · favicon.svg
└── dist/                 # gebaut — nicht von Hand ändern
```

## Stand der Prüfung

Real geprüft in dieser Session: `build.sh` läuft durch (65 Tokens, 60
CSS-Variablen, Abgleich grün), das erzeugte `dist/oat-matrix.kdl` wurde von
**zellij 0.44.3** akzeptiert (`zellij setup --check` → *CONFIG FILE: Well
defined*), `styleguide.html` referenziert nur lokale Dateien (kein CDN).

Nicht geprüft: das Anwenden auf laufende Container — die Images lassen sich in
dieser Umgebung nicht ziehen (Registry gesperrt). `apply-theme.sh` ist deshalb
defensiv geschrieben (prüft Dienst, prüft Datei, meldet jeden Schritt einzeln).

MIT © DEVKiTZ™
