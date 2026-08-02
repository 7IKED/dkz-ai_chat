#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // CONTROL — Status des geschlossenen Systems            ║
# ╚══════════════════════════════════════════════════════════════════╝
#  odysseus-ctl.sh status    Dienste + Health (Standard)
#  odysseus-ctl.sh up|down   Stack starten/stoppen
#  odysseus-ctl.sh logs      alle Logs verfolgen
#  odysseus-ctl.sh watch     Status-Dauerpanel (fuer Layout-Pane)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DC() { docker compose -f "$DIR/docker-compose.yml" "$@"; }
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; N='\033[0m'

health() {
    printf "${G}╔═ OPEN AI TERMINAL // SYSTEM-STATUS ═══════════════${N}\n"
    local svc url
    for svc in "GITEA:http://127.0.0.1:${GITEA_PORT:-3300}/api/healthz" \
               "OPENCLOUD:http://127.0.0.1:${OPENCLOUD_PORT:-9200}/status.php" \
               "IMMICH:http://127.0.0.1:${IMMICH_PORT:-2283}/api/server/ping" \
               "nanoCHAT:http://127.0.0.1:${LIBRECHAT_PORT:-3080}/health" \
               "ATUIN:http://127.0.0.1:${ATUIN_PORT:-8888}"; do
        url="${svc#*:}"
        if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
            printf "  %-10s ${G}● ONLINE${N}   ${DIM}%s${N}\n" "${svc%%:*}" "$url"
        else
            printf "  %-10s ${R}○ OFFLINE${N}  ${DIM}%s${N}\n" "${svc%%:*}" "$url"
        fi
    done
    printf "${DIM}"; DC ps --format 'table {{.Name}}\t{{.Status}}' 2>/dev/null | head -14; printf "${N}"
}

case "${1:-status}" in
    status) health;;
    up)
        shift
        # `up --nextcloud` nimmt die optionale Zweit-Cloud dazu
        if [ "${1:-}" = "--nextcloud" ]; then
            docker compose -f "$DIR/docker-compose.yml" --profile nextcloud up -d --build && health
        else
            DC up -d --build && health
        fi
        ;;
    down)   DC --profile nextcloud down;;
    logs)   DC logs -f --tail=40;;
    watch)  while true; do clear; health; sleep 5; done;;
    *)      echo "usage: odysseus-ctl.sh [status|up [--nextcloud]|down|logs|watch]";;
esac
