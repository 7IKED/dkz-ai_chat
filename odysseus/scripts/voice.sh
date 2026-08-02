#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // VOICEBOX — Text → Sprache (Piper TTS, MIT)            ║
# ╚══════════════════════════════════════════════════════════════════╝
#  voice.sh "text"              spricht (oder speichert wav)
#  voice.sh --out out.wav "t"   nur Datei
#  Backend: piper lokal → voicebox-Container (piper CLI im Image).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; N='\033[0m'
OUT=""
[ "${1:-}" = "--out" ] && { OUT="$2"; shift 2; }
TEXT="${*:?Text fehlt}"
WAV="${OUT:-$DIR/data/voice-$(date +%s).wav}"
mkdir -p "$(dirname "$WAV")"
MODEL="${VOICE_MODEL:-de_DE-thorsten-medium}"

if command -v piper >/dev/null 2>&1; then
    printf '%s' "$TEXT" | piper --model "$MODEL" --output_file "$WAV"
elif docker compose -f "$DIR/docker-compose.yml" ps voicebox 2>/dev/null | grep -q voicebox; then
    # piper-CLI im wyoming-piper-Image nutzen (Modell liegt in /data)
    printf '%s' "$TEXT" | docker compose -f "$DIR/docker-compose.yml" exec -T voicebox \
        sh -c "piper --model /data/$MODEL.onnx --output_file -" > "$WAV" 2>/dev/null \
        || { echo -e "${R}[VOICE] Container-Synthese fehlgeschlagen (Modell noch am Laden?)${N}"; exit 1; }
else
    echo -e "${R}[VOICE] Kein piper gefunden und voicebox-Container laeuft nicht.${N}"
    echo -e "${DIM}        docker compose up -d voicebox${N}"; exit 127
fi
echo -e "${G}[VOICE] → $WAV${N}"
# Abspielen falls moeglich (Desktop)
command -v aplay >/dev/null 2>&1 && [ -z "$OUT" ] && aplay -q "$WAV" 2>/dev/null || true
