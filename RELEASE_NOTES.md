# 🟢 COSMO_V2 // ODYSSEUS — Release v1.0.0

> DEVKiTZ™ Matrix Terminal System — Multiplexer · geschlossenes Agenten-System · Single-File · Skill-Importer. Für Windows · Linux · Docker.

**Präsentation:** https://claude.ai/code/artifact/2282e2e8-3cf0-455f-a787-6125e648339a

---

## Was drin ist

### Version 1 — Cosmo Multiplexer (`multiplexer/`)
Zellij-Terminal im Matrix-Stil mit 5 Profilen und dem „Perfect Zsh Setup".
- Profile: **desktop · vps · agent · builder · monitor** (`cosmo <profil>`)
- **Teststrassen-Erfassung** (`testlane.sh`): Log + Exit-Code + Dauer → `summary.jsonl`
- Perfect Zsh: zinit, autosuggestions, syntax-highlighting, fzf-tab, zoxide, eza, Matrix-Prompt — Start ~103 ms
- Installer für Linux/macOS/WSL (`install.sh`) + Windows (`install.ps1`) + Docker

### Version 2 — Odysseus (`odysseus/`)
Geschlossenes System, alle Ports nur auf 127.0.0.1, alles in einem Gitea.
- **11 Docker-Services:** Gitea (Zentrum + A2A-Webhooks), Nextcloud, Immich (Foto-Oberfläche), LibreChat/nanoChat, Atuin (Logs), Piper-Voicebox (TTS), KeePass-Vault (Agenten-Keys), + Backends
- Matrix-Terminal (`odysseus`) mit Tabs BRIDGE · BROWSER · GITEA · LOGS
- Terminal-Browser-Kette (carbonyl → browsh → w3m → lynx), A2A-Inbox, Vault-CLI, Voice, Health-Watch
- Windows-Installation nach `C:\DEVKiTZ\odysseus`

### Version 3 — Single-File (`odysseus/exe/`)
Ein Launcher (Go, nur Stdlib, MIT) mit eingebettetem Komplettsystem.
- **`odysseus.exe`** (Windows, PE32+, ~2,1 MB) → entpackt nach `C:\DEVKiTZ\odysseus`
- **`odysseus-linux`** (statisch, ~2,0 MB) → `~/DEVKiTZ/odysseus`
- `.env` und `data/` werden nie überschrieben — Update = neue Datei ausführen

### Skill-System (`odysseus/skills/`)
Ein Link → alle Skills + Workflows.
- `odysseus skills <repo-oder-youtube-url>` → verlinkt alle SKILL.md + erzeugt FLOWS.md
- **Registry mit 43 per GitHub-API verifizierten Packs** (superpowers, anthropics/skills, Trail-of-Bits-Security, Obsidian, llm-wiki, DevOps, Data-Science, SEO/Marketing, Video u.a.)
- Skill `/import-skills`, gekoppelt an `writing-great-skills` (Skill-Builder)

---

## Assets

| Datei | Plattform | Größe |
|:--|:--|:--|
| `odysseus.exe` | Windows x64 | ~2,1 MB |
| `odysseus-linux` | Linux x64 (statisch) | ~2,0 MB |

## Schnellstart

```bash
cosmo desktop            # V1 — sofort
odysseus up && odysseus  # V2 — geschlossenes System
./odysseus.exe           # V3 — eine Datei
```

## Verifiziert in dieser Session
zellij 0.44.3 Config-Check bestanden · alle 5 Profile + Odysseus als echte Sessions gestartet · Zsh ~103 ms · Teststrasse pass/fail+JSONL · docker-compose 11 Services valide · beide Binaries gebaut (Linux end-to-end) · Skill-Import real (7iked/skills 39 + superpowers 14) · 43 Registry-Packs geprüft.

MIT © DEVKiTZ™ — Drittkomponenten unter ihren jeweiligen freien Lizenzen (siehe LICENSE).
