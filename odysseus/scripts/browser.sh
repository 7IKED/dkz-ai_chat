#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // TERMINAL-BROWSER — Dienste im Terminal surfen         ║
# ╚══════════════════════════════════════════════════════════════════╝
#  browser.sh              Dienste-Menue → Auswahl oeffnen
#  browser.sh <url|dienst> direkt oeffnen (gitea|cloud|fotos|chat|atuin)
#  Browser-Kette: carbonyl (Chromium im Terminal!) → browsh → w3m → lynx
set -uo pipefail
G='\033[38;5;46m'; DIM='\033[38;5;28m'; N='\033[0m'

url_for() {
    case "$1" in
        gitea) echo "http://127.0.0.1:${GITEA_PORT:-3300}";;
        cloud|opencloud) echo "http://127.0.0.1:${OPENCLOUD_PORT:-9200}";;
        nextcloud) echo "http://127.0.0.1:${NEXTCLOUD_PORT:-8081}";;
        fotos|immich) echo "http://127.0.0.1:${IMMICH_PORT:-2283}";;
        chat|librechat|nanochat) echo "http://127.0.0.1:${LIBRECHAT_PORT:-3080}";;
        atuin) echo "http://127.0.0.1:${ATUIN_PORT:-8888}";;
        *) echo "$1";;
    esac
}

open_url() {
    local u="$1"
    echo -e "${G}[BROWSER] → $u${N}"
    if command -v carbonyl >/dev/null 2>&1; then exec carbonyl "$u"
    elif command -v browsh >/dev/null 2>&1;  then exec browsh "$u"
    elif command -v w3m >/dev/null 2>&1;     then exec w3m "$u"
    elif command -v lynx >/dev/null 2>&1;    then exec lynx "$u"
    else
        echo -e "${DIM}[BROWSER] Kein Terminal-Browser installiert."
        echo "  apt install w3m        (leicht)"
        echo "  npm i -g carbonyl      (Chromium im Terminal, volle Web-UI!)"
        echo "  URL zum Selbstoeffnen: $u${N}"
        exec bash
    fi
}

if [ $# -ge 1 ]; then open_url "$(url_for "$1")"; fi

echo -e "${G}╔═ OPEN AI TERMINAL // DIENSTE ═════════════════════${N}"
echo -e "  ${G}1${N}  GITEA      (Code/Issues/A2A)   :${GITEA_PORT:-3300}"
echo -e "  ${G}2${N}  OPENCLOUD  (Dateien/Sync)      :${OPENCLOUD_PORT:-9200}"
echo -e "  ${G}3${N}  IMMICH     (Foto-Oberflaeche)  :${IMMICH_PORT:-2283}"
echo -e "  ${G}4${N}  nanoCHAT   (LibreChat)         :${LIBRECHAT_PORT:-3080}"
echo -e "  ${G}5${N}  ATUIN      (History-Sync)      :${ATUIN_PORT:-8888}"
echo -e "  ${DIM}6  NEXTCLOUD  (nur --profile)      :${NEXTCLOUD_PORT:-8081}${N}"
read -rp "Auswahl [1-6]: " c
case "$c" in
    1) open_url "$(url_for gitea)";; 2) open_url "$(url_for cloud)";;
    3) open_url "$(url_for fotos)";; 4) open_url "$(url_for chat)";;
    5) open_url "$(url_for atuin)";; 6) open_url "$(url_for nextcloud)";;
    *) exec bash;;
esac
