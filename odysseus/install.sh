#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // INSTALLER  (Linux / macOS / WSL)                      ║
# ╚══════════════════════════════════════════════════════════════════╝
#  ./install.sh [zielverzeichnis]     Standard: ~/DEVKiTZ/odysseus
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HOME/DEVKiTZ/odysseus}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; Y='\033[38;5;214m'; N='\033[0m'
say(){ echo -e "${G}[ODYSSEUS]${N} $*"; }
warn(){ echo -e "${Y}[ODYSSEUS]${N} $*"; }

say "Installation nach $TARGET"
mkdir -p "$TARGET"
# rsync falls da, sonst cp — .env und data/ nie ueberschreiben
if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude .env --exclude data "$SRC/" "$TARGET/"
else
    (cd "$SRC" && tar cf - --exclude=.env --exclude=data .) | (cd "$TARGET" && tar xf -)
fi
[ -f "$TARGET/.env" ] || { cp "$SRC/.env.example" "$TARGET/.env"; warn ".env angelegt — Passwoerter aendern!"; }
chmod +x "$TARGET/bin/odysseus" "$TARGET"/scripts/*.sh

mkdir -p "$HOME/.local/bin"
ln -sfn "$TARGET/bin/odysseus" "$HOME/.local/bin/odysseus"
say "launcher → ~/.local/bin/odysseus"

command -v docker >/dev/null 2>&1 || warn "Docker fehlt → https://docs.docker.com/engine/install/"
command -v zellij >/dev/null 2>&1 || warn "zellij fehlt → ../multiplexer/install.sh (Version 1) ausfuehren"

say "Naechste Schritte:"
echo -e "  ${DIM}1) $TARGET/.env anpassen"
echo -e "  2) odysseus up        # Stack starten"
echo -e "  3) odysseus init      # Gitea: Admin + DEVKITZ/odysseus + Push"
echo -e "  4) odysseus           # Matrix-Terminal${N}"
