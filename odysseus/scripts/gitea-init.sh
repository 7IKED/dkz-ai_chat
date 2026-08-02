#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // GITEA-INIT — alles in EINEM Gitea (geschlossen)       ║
# ╚══════════════════════════════════════════════════════════════════╝
#  Nach `docker compose up -d`:
#    gitea-init.sh            Admin + Org DEVKiTZ + Repo odysseus anlegen
#    gitea-init.sh push       dieses Repo ins lokale Gitea pushen
#  Danach laeuft die gesamte Entwicklung gegen das interne Gitea —
#  Webhooks aus Gitea sind der A2A-Bus (→ nanochat.sh inbox <agent>).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; N='\033[0m'
PORT="${GITEA_PORT:-3300}"
URL="http://127.0.0.1:${PORT}"
ADMIN="${ADMIN_USER:-odysseus}"
PASS="${ADMIN_PASS:?ADMIN_PASS setzen (.env laden: set -a; . .env; set +a)}"

CE() { docker compose -f "$DIR/docker-compose.yml" exec -T -u 1000 gitea "$@"; }

case "${1:-setup}" in
setup)
    echo -e "${G}[GITEA] warte auf ${URL} ...${N}"
    for i in $(seq 1 30); do curl -fsS "$URL/api/healthz" >/dev/null 2>&1 && break; sleep 2; done
    echo -e "${G}[GITEA] lege Admin '$ADMIN' an${N}"
    CE gitea admin user create --admin --username "$ADMIN" \
        --password "$PASS" --email "$ADMIN@odysseus.local" 2>/dev/null \
        || echo -e "${DIM}[GITEA] Admin existiert schon${N}"
    echo -e "${G}[GITEA] Org DEVKITZ + Repo odysseus${N}"
    curl -fsS -u "$ADMIN:$PASS" -X POST "$URL/api/v1/orgs" \
        -H 'Content-Type: application/json' \
        -d '{"username":"DEVKITZ","visibility":"private"}' >/dev/null 2>&1 \
        || echo -e "${DIM}[GITEA] Org existiert schon${N}"
    curl -fsS -u "$ADMIN:$PASS" -X POST "$URL/api/v1/orgs/DEVKITZ/repos" \
        -H 'Content-Type: application/json' \
        -d '{"name":"odysseus","private":true,"auto_init":false}' >/dev/null 2>&1 \
        || echo -e "${DIM}[GITEA] Repo existiert schon${N}"
    echo -e "${G}[GITEA] fertig → ${URL}/DEVKITZ/odysseus${N}"
    echo -e "${DIM}[GITEA] Registrierung jetzt schliessen: GITEA__service__DISABLE_REGISTRATION=true${N}"
    ;;
push)
    cd "$DIR/.."
    git remote remove gitea 2>/dev/null || true
    git remote add gitea "http://$ADMIN:$PASS@127.0.0.1:${PORT}/DEVKITZ/odysseus.git"
    git push -u gitea --all
    echo -e "${G}[GITEA] Repo gepusht → ${URL}/DEVKITZ/odysseus${N}"
    ;;
*) echo "usage: gitea-init.sh [setup|push]";;
esac
