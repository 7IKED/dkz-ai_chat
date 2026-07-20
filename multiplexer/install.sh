#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // INSTALLER  (Linux · macOS · WSL)          ║
# ╚══════════════════════════════════════════════════════════════════╝
#  - installiert zellij (falls fehlt)
#  - verlinkt config + layouts nach ~/.config/zellij
#  - legt `cosmo` in ~/.local/bin ab
#  Nutzung:  ./install.sh           (interaktiv)
#            ./install.sh --no-zellij  (nur Config + Launcher)
set -euo pipefail

MUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; Y='\033[38;5;214m'; N='\033[0m'
say() { echo -e "${G}[COSMO]${N} $*"; }
warn(){ echo -e "${Y}[COSMO]${N} $*"; }

SKIP_ZELLIJ=0
[ "${1:-}" = "--no-zellij" ] && SKIP_ZELLIJ=1

# 1) zellij installieren --------------------------------------------------
install_zellij() {
    command -v zellij >/dev/null 2>&1 && { say "zellij bereits vorhanden ($(zellij --version))"; return; }
    [ "$SKIP_ZELLIJ" = "1" ] && { warn "--no-zellij: ueberspringe Installation"; return; }
    say "installiere zellij ..."
    if command -v cargo >/dev/null 2>&1; then
        cargo install --locked zellij
    elif command -v brew >/dev/null 2>&1; then
        brew install zellij
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm zellij
    elif command -v apt-get >/dev/null 2>&1; then
        # Offizielles statisches Binary (kein apt-Paket in aelteren Distros)
        ARCH="$(uname -m)"; case "$ARCH" in x86_64) T=x86_64-unknown-linux-musl;; aarch64|arm64) T=aarch64-unknown-linux-musl;; *) T="";; esac
        if [ -n "$T" ] && command -v curl >/dev/null 2>&1; then
            TMP="$(mktemp -d)"
            curl -fsSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${T}.tar.gz" | tar -xz -C "$TMP"
            mkdir -p "$HOME/.local/bin"; install -m755 "$TMP/zellij" "$HOME/.local/bin/zellij"
            rm -rf "$TMP"; say "zellij → ~/.local/bin/zellij"
        else
            warn "Bitte zellij manuell installieren: https://zellij.dev/documentation/installation"
        fi
    else
        warn "Kein bekannter Paketmanager. Manuell: https://zellij.dev/documentation/installation"
    fi
}

# 2) Config verlinken -----------------------------------------------------
link_config() {
    local zdir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
    mkdir -p "$zdir/layouts" "$zdir/themes"
    # config.kdl (Backup falls vorhanden)
    if [ -f "$zdir/config.kdl" ] && [ ! -L "$zdir/config.kdl" ]; then
        cp "$zdir/config.kdl" "$zdir/config.kdl.bak.$(date +%s)"; warn "bestehende config.kdl gesichert"
    fi
    # config.kdl enthaelt das Cosmo-Theme bereits inline → keinen separaten
    # Theme-Link setzen (sonst doppelte Theme-Definition in neueren Zellij).
    ln -sfn "$MUX_DIR/config/config.kdl"        "$zdir/config.kdl"
    for l in "$MUX_DIR"/layouts/*.kdl; do
        ln -sfn "$l" "$zdir/layouts/$(basename "$l")"
    done
    say "config + layouts → $zdir"
}

# 3) Launcher + Scripts ausfuehrbar --------------------------------------
install_launcher() {
    chmod +x "$MUX_DIR/bin/cosmo" "$MUX_DIR"/scripts/*.sh 2>/dev/null || true
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$MUX_DIR/bin/cosmo" "$HOME/.local/bin/cosmo"
    say "launcher → ~/.local/bin/cosmo"
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) : ;;
        *) warn "~/.local/bin ist nicht in PATH. Ergaenze in ~/.bashrc / ~/.zshrc:"
           echo -e "        ${DIM}export PATH=\"\$HOME/.local/bin:\$PATH\"${N}";;
    esac
}

# 4) Beispiel-Env anlegen -------------------------------------------------
seed_env() {
    local ed="$HOME/.config/cosmo"; mkdir -p "$ed"
    [ -f "$ed/env" ] && return
    cat > "$ed/env" <<'EOF'
# COSMO Multiplexer — Umgebung (wird vom `cosmo` Launcher geladen)
# VPS-Hosts fuer `cosmo vps` (Slot 1..n)
# export COSMO_VPS_HOSTS="user@1.2.3.4 admin@vps.example.com"
# export COSMO_VPS_PING="1.1.1.1"

# Build-/Test-Befehle fuer `cosmo builder`
# export COSMO_BUILD_A="npm run build"
# export COSMO_BUILD_B="cargo build --release"
# export COSMO_TEST_CMD="npm test"
# export COSMO_WATCH_CMD="npm run test:watch"

# Agenten-Basis (`cosmo agent`)
# export COSMO_AGENT_CMD="python orchestrator.py"
# export COSMO_AGENT_STATUS_URL="http://localhost:8080/status"
# export COSMO_WEBHOOK_LOG="/var/log/cosmo/webhooks.log"
EOF
    say "beispiel-env → $ed/env"
}

echo -e "${G}"; cat <<'EOF'
 ┌─ COSMO_V2 MULTIPLEXER · Installer ────────────────────────────┐
 │  Zellij-basierte Multiplexer-Umgebung · DEVKiTZ Ecosystem     │
 └───────────────────────────────────────────────────────────────┘
EOF
echo -e "${N}"
install_zellij
link_config
install_launcher
seed_env
# 5) Optional: Perfect Zsh Setup ------------------------------------------
if [ "${COSMO_WITH_ZSH:-ask}" = "yes" ]; then
    "$MUX_DIR/shell/install-shell.sh"
elif [ "${COSMO_WITH_ZSH:-ask}" = "ask" ] && [ -t 0 ]; then
    echo -en "${G}[COSMO]${N} Perfect Zsh Setup mitinstallieren? [j/N] "
    read -r a; case "$a" in j|J|y|Y) "$MUX_DIR/shell/install-shell.sh";; esac
fi

echo
say "fertig. Start:  ${G}cosmo desktop${N}  |  ${G}cosmo agent${N}  |  ${G}cosmo builder${N}"
say "Profile:        desktop · vps · agent · builder · monitor"
say "Zsh-Setup:      ${DIM}multiplexer/shell/install-shell.sh${N} (oder COSMO_WITH_ZSH=yes ./install.sh)"
