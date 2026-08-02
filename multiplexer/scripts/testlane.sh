#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
#  COSMO // TESTSTRASSEN-ERFASSUNG  (test-lane capture)
#  Fuehrt einen Build-/Test-Befehl aus und erfasst:
#    - stdout + stderr (mit Zeitstempel, live sichtbar)
#    - Exit-Code
#    - Dauer
#  Ergebnis-Log:  multiplexer/.captures/<lane>-<timestamp>.log
#  Zusammenfassung: multiplexer/.captures/summary.jsonl  (eine Zeile je Lauf)
#
#  Nutzung:
#    testlane.sh <lane-name> "<befehl>"     # Lauf erfassen
#    testlane.sh --tail                     # letzte Captures verfolgen
#    testlane.sh --summary                  # JSONL-Zusammenfassung anzeigen
# ─────────────────────────────────────────────────────────────────────
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUX_DIR="$(dirname "$SCRIPT_DIR")"
CAP_DIR="${COSMO_CAPTURE_DIR:-$MUX_DIR/.captures}"
mkdir -p "$CAP_DIR"

G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; Y='\033[38;5;214m'; N='\033[0m'

case "${1:-}" in
    --tail)
        echo -e "${DIM}[COSMO] verfolge $CAP_DIR ...${N}"
        latest="$(ls -t "$CAP_DIR"/*.log 2>/dev/null | head -1)"
        [ -n "${latest:-}" ] && tail -f "$latest" || { echo "Noch keine Captures."; exec bash; }
        ;;
    --summary)
        [ -f "$CAP_DIR/summary.jsonl" ] && cat "$CAP_DIR/summary.jsonl" || echo "Noch keine Laeufe."
        ;;
    "" )
        echo "usage: testlane.sh <lane> \"<cmd>\" | --tail | --summary"; exit 2
        ;;
    * )
        LANE="$1"; shift
        CMD="${*:-}"
        [ -z "$CMD" ] && { echo "kein Befehl angegeben"; exit 2; }
        TS="$(date +%Y%m%d-%H%M%S)"
        LOG="$CAP_DIR/${LANE}-${TS}.log"
        START=$(date +%s)

        echo -e "${G}╔═ COSMO TESTSTRASSE // ${LANE} ═══════════════════════${N}"
        echo -e "${DIM}  cmd : ${CMD}${N}"
        echo -e "${DIM}  log : ${LOG}${N}"
        echo -e "${G}╚══════════════════════════════════════════════════════${N}"

        # Live anzeigen + mit Zeitstempel ins Log schreiben
        {
            echo "# lane=$LANE ts=$TS cmd=$CMD"
        } > "$LOG"
        # shellcheck disable=SC2086
        stdbuf -oL -eL bash -lc "$CMD" 2>&1 \
            | while IFS= read -r line; do
                printf '%s | %s\n' "$(date +%H:%M:%S)" "$line" | tee -a "$LOG"
              done
        CODE=${PIPESTATUS[0]}
        END=$(date +%s); DUR=$((END-START))

        if [ "$CODE" -eq 0 ]; then
            echo -e "${G}✔ ${LANE} OK  (${DUR}s, exit ${CODE})${N}"
            STATUS="pass"
        else
            echo -e "${R}✘ ${LANE} FAIL (${DUR}s, exit ${CODE})${N}"
            STATUS="fail"
        fi

        printf '{"lane":"%s","ts":"%s","status":"%s","exit":%s,"duration_s":%s,"log":"%s"}\n' \
            "$LANE" "$TS" "$STATUS" "$CODE" "$DUR" "$LOG" >> "$CAP_DIR/summary.jsonl"
        exit "$CODE"
        ;;
esac
