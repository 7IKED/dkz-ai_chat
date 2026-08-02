#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // INSTALLER  (Linux / macOS / WSL)              ║
# ╚══════════════════════════════════════════════════════════════════╝
#  ./install.sh [zielverzeichnis]     Standard: ~/DEVKiTZ/odysseus
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$HOME/DEVKiTZ/odysseus}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; Y='\033[38;5;214m'; N='\033[0m'
say(){ echo -e "${G}[OAT]${N} $*"; }
warn(){ echo -e "${Y}[OAT]${N} $*"; }

say "Installation nach $TARGET"
mkdir -p "$TARGET"
# rsync falls da, sonst cp — .env und data/ nie ueberschreiben
if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude .env --exclude data "$SRC/" "$TARGET/"
else
    (cd "$SRC" && tar cf - --exclude=.env --exclude=data .) | (cd "$TARGET" && tar xf -)
fi
[ -f "$TARGET/.env" ] || { cp "$SRC/.env.example" "$TARGET/.env"; warn ".env angelegt — Passwoerter aendern!"; }
chmod +x "$TARGET/bin/odysseus" "$TARGET"/scripts/*.sh "$TARGET"/design/*.sh 2>/dev/null || true

mkdir -p "$HOME/.local/bin"
ln -sfn "$TARGET/bin/odysseus" "$HOME/.local/bin/odysseus"
say "launcher → ~/.local/bin/odysseus"

# Cloud Design System bauen (CSS-Bundle · Shell-Farben · Zellij-Theme)
if "$TARGET/design/build.sh" >/dev/null 2>&1; then
    say "Design System gebaut → design/dist/"
    # Zellij-Theme mitliefern, falls zellij-Config vorhanden
    if [ -d "$HOME/.config/zellij" ]; then
        mkdir -p "$HOME/.config/zellij/themes"
        cp "$TARGET/design/dist/oat-matrix.kdl" "$HOME/.config/zellij/themes/" 2>/dev/null \
            && say "Zellij-Theme → ~/.config/zellij/themes/oat-matrix.kdl"
    fi
else
    warn "Design System nicht gebaut (python3 fehlt?) — Skripte nutzen Ersatzfarben"
fi

command -v docker >/dev/null 2>&1 || warn "Docker fehlt → https://docs.docker.com/engine/install/"
command -v zellij >/dev/null 2>&1 || warn "zellij fehlt → ../multiplexer/install.sh (Version 1) ausfuehren"

# URI-Handler anbieten (nicht ungefragt registrieren — er ist von aussen erreichbar)
if [ -t 0 ] && [ "${OAT_INSTALL_URI:-ask}" = "ask" ]; then
    printf "${DIM}  URI-Handler oat:// registrieren? Links aus Gitea/Chat oeffnen dann\n"
    printf "  direkt im Terminal. [j/N] ${N}"
    read -r a || a=n
    case "$a" in j|J|y|Y) "$TARGET/scripts/uri.sh" install;; esac
elif [ "${OAT_INSTALL_URI:-}" = "1" ]; then
    "$TARGET/scripts/uri.sh" install
fi

say "Naechste Schritte:"
echo -e "  ${DIM}1) $TARGET/.env anpassen (ADMIN_PASS!)"
echo -e "  2) odysseus up        # Stack starten (11 Dienste)"
echo -e "  3) odysseus init      # Gitea: Admin + DEVKITZ/odysseus + Push"
echo -e "  4) odysseus design apply   # Matrix-Look in die Web-UIs"
echo -e "  5) odysseus           # das Terminal (BRIDGE·GITVIZ·CLOUD·GITEA·LOGS)${N}"
