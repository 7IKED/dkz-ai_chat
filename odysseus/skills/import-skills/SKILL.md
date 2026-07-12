---
name: import-skills
description: EIN Link — alle Skills übernommen. Gib eine Git-Repo-URL oder einen YouTube-Link ein; alle SKILL.md werden verlinkt und pro Pack wird eine FLOWS.md (Workflows in wenigen Schritten) erzeugt. Nutze bei "importiere Skills von <url>", "übernimm dieses Skill-Pack", "mach Workflows aus diesem Video/Repo", oder um aus der kuratierten Registry zu installieren.
---

# import-skills

Übernimmt Skill-Packs aus beliebigen Quellen in EINEM Schritt und erzeugt
sofort nutzbare Workflows. Motor: `odysseus/scripts/skill-import.sh`.

## Wann

- Der Nutzer gibt einen **Repo-Link** ("importiere die Skills von github.com/x/y").
- Der Nutzer gibt einen **YouTube-Link** ("mach einen Skill/Workflow aus diesem Video").
- Der Nutzer will aus der **Registry** installieren ("hol das obsidian-Pack", "alle Packs").

## Ablauf

1. **Quelle erkennen**
   - `github.com/…` oder `*.git` → Repo-Import
   - `youtube.com/…` / `youtu.be/…` → YouTube-Skill-Gerüst
   - bekannter Pack-Name → Registry (`odysseus/skills/registry/packs.tsv`)

2. **Import ausführen**
   ```bash
   odysseus/scripts/skill-import.sh <url>            # Repo oder YouTube
   odysseus/scripts/skill-import.sh --pack <name>    # aus Registry
   odysseus/scripts/skill-import.sh --all-registry   # alle Packs
   odysseus/scripts/skill-import.sh --list           # was ist installiert
   ```
   Das Script klont nach `odysseus/skills/packs/<pack>/`, verlinkt jede
   `SKILL.md` kollisionssicher (Pack-Prefix bei Namenskollision) nach
   `~/.claude/skills/` und schreibt `FLOWS.md` in den Pack.

3. **Workflows anbieten** — die erzeugte `FLOWS.md` zeigen: pro Skill eine
   3-Schritt-Kurzanleitung. So setzt der Nutzer alles in wenigen Schritten um.

4. **Bei YouTube**: Das Gerüst (`skills/packs/yt-<id>/SKILL.md`) inhaltlich
   füllen — Transkript/Kernaussagen als Arbeitsschritte formulieren. Für die
   Zusammenfassung `research`- oder `ask-matt`-Skill nutzen, falls vorhanden.

## Skill-Builder-Kopplung

Neue Skills aus einem Import verfeinern: mit dem `writing-great-skills`-Skill
(aus 7IKED/skills) Beschreibung/Trigger schärfen. So wird aus einem rohen
Import ein sauber getriggerter Skill.

## Registry

`odysseus/skills/registry/packs.tsv` (Tab-getrennt: name · url · kategorie ·
beschreibung). Erweitern: eine Zeile anhängen, dann `--pack <name>`.
