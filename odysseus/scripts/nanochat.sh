#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // nanoCHAT — Terminal-Chat (LibreChat/Ollama, A2A)      ║
# ╚══════════════════════════════════════════════════════════════════╝
#  nanochat.sh                        interaktive Chat-Schleife
#  nanochat.sh ask "frage"            Einzelfrage
#  nanochat.sh a2a <agent> "msg"      Agent-zu-Agent: Nachricht in die
#                                     A2A-Inbox (data/a2a/<agent>.jsonl)
#  nanochat.sh inbox <agent>          A2A-Inbox lesen/verfolgen
#
#  Backend-Kette: Ollama direkt (http://127.0.0.1:11434) → LibreChat-UI-
#  Hinweis. Modell via NANOCHAT_MODEL (default llama3.2).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
A2A_DIR="$DIR/data/a2a"; mkdir -p "$A2A_DIR"
OLLAMA="${OLLAMA_URL:-http://127.0.0.1:11434}"
MODEL="${NANOCHAT_MODEL:-llama3.2}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; W='\033[38;5;255m'; N='\033[0m'

have_ollama() { curl -fsS --max-time 2 "$OLLAMA/api/tags" >/dev/null 2>&1; }

ask() {
    local q="$1"
    if have_ollama; then
        curl -fsS "$OLLAMA/api/generate" \
            -d "$(printf '{"model":"%s","prompt":%s,"stream":false}' "$MODEL" "$(printf '%s' "$q" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')")" \
            | python3 -c 'import json,sys;print(json.load(sys.stdin).get("response","(keine Antwort)"))'
    else
        echo -e "${R}[nanoChat] Kein lokales Modell erreichbar (${OLLAMA}).${N}"
        echo -e "${DIM}  → Ollama starten (ollama serve) oder LibreChat-UI nutzen:"
        echo -e "    http://127.0.0.1:${LIBRECHAT_PORT:-3080}${N}"
        return 1
    fi
}

case "${1:-repl}" in
    ask)   shift; ask "${*:?Frage fehlt}";;
    a2a)
        AGENT="${2:?Agent fehlt}"; shift 2
        MSG="${*:?Nachricht fehlt}"
        printf '{"ts":"%s","from":"%s","msg":%s}\n' \
            "$(date -Is)" "${NANOCHAT_FROM:-operator}" \
            "$(printf '%s' "$MSG" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')" \
            >> "$A2A_DIR/$AGENT.jsonl"
        echo -e "${G}[A2A] → $AGENT${N}"
        ;;
    inbox)
        AGENT="${2:?Agent fehlt}"
        touch "$A2A_DIR/$AGENT.jsonl"
        echo -e "${DIM}[A2A] Inbox $AGENT — Ctrl+C beendet${N}"
        tail -n 20 -f "$A2A_DIR/$AGENT.jsonl"
        ;;
    repl|*)
        echo -e "${G}╔═ ODYSSEUS nanoCHAT ═══════════════════════════════${N}"
        echo -e "${DIM}  Modell: $MODEL @ $OLLAMA — 'exit' beendet${N}"
        while true; do
            printf "${W}Operator:~$ ${N}"; read -r line || break
            [ "$line" = "exit" ] && break
            [ -z "$line" ] && continue
            printf "${G}pi-agent:${N} "; ask "$line" || true
        done
        ;;
esac
