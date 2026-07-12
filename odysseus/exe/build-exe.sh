#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // EXE-BUILDER  ·  baut Version 3 (Single-File)          ║
# ╚══════════════════════════════════════════════════════════════════╝
#  ./build-exe.sh          baut dist/odysseus.exe (Windows) +
#                          dist/odysseus-linux (Linux) mit eingebettetem
#                          Komplett-System (payload.tar.gz)
set -euo pipefail
EXE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ODY_DIR="$(dirname "$EXE_DIR")"
G='\033[38;5;46m'; N='\033[0m'
say(){ echo -e "${G}[BUILD]${N} $*"; }

command -v go >/dev/null 2>&1 || { echo "Go fehlt (apt install golang-go)"; exit 127; }

# 1) Payload packen: das komplette odysseus/ (ohne exe/, data/, .env)
say "packe payload.tar.gz"
tar -C "$ODY_DIR" -czf "$EXE_DIR/payload.tar.gz" \
    --exclude=exe --exclude=data --exclude=.env --exclude='dist' \
    --transform 's|^\./||' .

# 2) Go-Modul + Cross-Compile
cd "$EXE_DIR"
[ -f go.mod ] || go mod init devkitz.local/odysseus >/dev/null 2>&1
mkdir -p dist
say "baue Windows exe  (GOOS=windows GOARCH=amd64)"
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o dist/odysseus.exe .
say "baue Linux binary (GOOS=linux GOARCH=amd64)"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o dist/odysseus-linux .

ls -lh dist/ | awk '{print "  "$5"  "$9}'
say "fertig → exe/dist/  (eine Datei = komplettes System, doppelklicken/ausfuehren)"
