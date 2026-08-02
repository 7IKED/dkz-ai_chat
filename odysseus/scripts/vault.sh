#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // VAULT — KeePass fuer Agenten-Zugangsdaten & API-Keys  ║
# ╚══════════════════════════════════════════════════════════════════╝
#  Die Agenten holen ihre Keys NUR von hier — nie aus Env-Dateien.
#
#  vault.sh init                      neue Datenbank anlegen
#  vault.sh set  <eintrag>            Passwort/Key speichern (Prompt)
#  vault.sh get  <eintrag>            Key holen (stdout — fuer $(...) )
#  vault.sh list                      Eintraege zeigen
#  vault.sh agent-env <eintrag...>    export-Zeilen fuer Agenten erzeugen
#
#  Master-Passwort: interaktiv oder via ODYSSEUS_VAULT_PW (fuer Agenten).
#  Backend: keepassxc-cli lokal ODER im vault-Container (docker compose).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDBX="${ODYSSEUS_KDBX:-$DIR/data/odysseus.kdbx}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; N='\033[0m'

# keepassxc-cli finden: lokal → vault-Container
if command -v keepassxc-cli >/dev/null 2>&1; then
    KP() { keepassxc-cli "$@"; }
elif docker compose -f "$DIR/docker-compose.yml" ps vault 2>/dev/null | grep -q vault; then
    KDBX="/vault/odysseus.kdbx"
    KP() { docker compose -f "$DIR/docker-compose.yml" exec -T vault keepassxc-cli "$@"; }
else
    echo -e "${R}[VAULT] keepassxc-cli fehlt und vault-Container laeuft nicht.${N}"
    echo -e "${DIM}        apt install keepassxc  ODER  docker compose up -d vault${N}"
    exit 127
fi

pw() {  # Master-Passwort auf stdin liefern
    if [ -n "${ODYSSEUS_VAULT_PW:-}" ]; then printf '%s\n' "$ODYSSEUS_VAULT_PW"
    else read -rs -p "Vault Master-Passwort: " p </dev/tty; echo >&2; printf '%s\n' "$p"; fi
}

CMD="${1:-help}"; shift || true
case "$CMD" in
    init)
        mkdir -p "$(dirname "$KDBX")" 2>/dev/null || true
        pw | KP db-create -p "$KDBX" \
            && echo -e "${G}[VAULT] Datenbank angelegt: $KDBX${N}"
        ;;
    set)
        E="${1:?Eintrag fehlt (z.B. api/openrouter)}"
        pw | KP add -p "$KDBX" "$E" \
            && echo -e "${G}[VAULT] '$E' gespeichert.${N}"
        ;;
    get)
        E="${1:?Eintrag fehlt}"
        pw | KP show -sa password "$KDBX" "$E"
        ;;
    list)
        pw | KP ls -R "$KDBX"
        ;;
    agent-env)
        # Erzeugt export-Zeilen:  eval "$(vault.sh agent-env api/openrouter api/xai)"
        for E in "$@"; do
            VAR="$(echo "$E" | tr 'a-z/-' 'A-Z__')_KEY"
            VAL="$(pw | KP show -sa password "$KDBX" "$E" 2>/dev/null)" \
                && printf 'export %s=%q\n' "$VAR" "$VAL"
        done
        ;;
    help|*)
        sed -n '5,15p' "$0"
        ;;
esac
