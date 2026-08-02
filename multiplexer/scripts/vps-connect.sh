#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
#  COSMO // VPS-CONNECT  — waehlt aus COSMO_VPS_HOSTS den n-ten Host
#  und baut die SSH-Verbindung auf. Ohne Konfiguration: interaktiver Prompt.
#
#  Konfiguration (z.B. in ~/.config/cosmo/env oder Shell):
#     export COSMO_VPS_HOSTS="user@1.2.3.4 admin@vps.example.com root@10.0.0.9"
#  oder Hosts aus ~/.ssh/config (Host-Aliase).
# ─────────────────────────────────────────────────────────────────────
set -uo pipefail
IDX="${1:-1}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; N='\033[0m'

read -r -a HOSTS <<< "${COSMO_VPS_HOSTS:-}"
HOST="${HOSTS[$((IDX-1))]:-}"

echo -e "${G}╔═ COSMO VPS-STEUERUNG // Slot ${IDX} ═══════════════${N}"
if [ -z "$HOST" ]; then
    echo -e "${DIM}  Kein Host in COSMO_VPS_HOSTS[Slot ${IDX}].${N}"
    echo -e "${DIM}  Setze: export COSMO_VPS_HOSTS=\"user@ip ...\"${N}"
    echo -en "${G}  Host manuell (user@host) oder leer fuer Shell: ${N}"
    read -r HOST
    [ -z "$HOST" ] && exec bash
fi

echo -e "${G}  → ssh ${HOST}${N}"
# ServerAliveInterval haelt die Session am Leben; -t erzwingt TTY.
exec ssh -t -o ServerAliveInterval=30 -o ServerAliveCountMax=3 "$HOST" \
    || { echo -e "${DIM}[COSMO] Verbindung getrennt — Shell.${N}"; exec bash; }
