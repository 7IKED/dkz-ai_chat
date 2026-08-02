# 🛰️ Claude Session Monitor

Visualisiert die **parallel laufenden Claude-Code-Chats** und verknüpft sie mit der **Git-Historie**:
Welche Session lief wann, wie lange, auf welchem Branch — und welcher Commit stammt aus welchem Chat.

## Nutzung

```bash
# 1. Daten aus den echten Transkripten erzeugen
python3 scripts/scan-claude-sessions.py

# 2. Viewer oeffnen (funktioniert auch direkt per file://)
open session-monitor/index.html
```

Optionen:

```bash
python3 scripts/scan-claude-sessions.py \
    --claude-root ~/.claude \                 # Wurzel der Transkripte
    --out session-monitor/sessions-data.js \  # Ziel fuer den Viewer
    --json /tmp/sessions.json \               # zusaetzlich als reines JSON
    --repo /pfad/zu/weiterem/repo             # zusaetzliches Repo (wiederholbar)
```

## Was angezeigt wird

| Bereich | Inhalt |
|:--|:--|
| **Kennzahlen** | Sessions, Projekte, Branches, parallele Überlappungen, Tokens, API-Fehler |
| **Zeitachse** | Swimlane pro Session auf gemeinsamer Zeitachse — Überlappung = paralleles Arbeiten (gelb umrandet) |
| **Sessions** | Erster Prompt, Branch, Laufzeit, Turns, Tokens, Modelle, Tools, Subagenten, Fehler |
| **Git-Historie** | Commit-Graph mit Lanes und Merges; 🛰️ markiert Commits/Branches einer Session |

## Datenquelle

Claude Code schreibt pro Session eine JSONL-Datei:

```
~/.claude/projects/<projekt-slug>/<sessionId>.jsonl
```

Der Scanner liest daraus ausschließlich **Metadaten**:
`sessionId`, `cwd`, `gitBranch`, `timestamp`, `type`, `isSidechain`, `isApiErrorMessage`,
`message.model`, `message.usage` und Tool-Namen. Nachrichteninhalte werden **nicht** übernommen —
einzige Ausnahme ist der erste Prompt (auf 220 Zeichen gekürzt) als Titel der Session.

Die Git-Daten kommen aus `git for-each-ref` und `git log --all` des jeweiligen Repos,
die Zuordnung Session→Branch über das `gitBranch`-Feld der Transkripte.

## Sicherheit

`sessions-data.js` ist **bewusst gitignored**: die Datei enthält lokale Pfade und den ersten Prompt
jeder Session. Sie wird lokal erzeugt und nie committet — im Repo liegen nur Generator und Viewer.

## Warum `.js` statt `.json`

Der Viewer wird oft direkt per `file://` geöffnet. Ein `fetch()` auf eine lokale `.json` scheitert
dort an der Same-Origin-Policy (das ist die klassische Ursache für eine weiße Seite), ein
`<script src>` dagegen nicht. Der Generator schreibt deshalb `window.DKZ_SESSIONS = {...}`.
