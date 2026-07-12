#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  COSMO_V2 // PERFECT ZSH SETUP — Installer                          ║
# ║  zsh + fzf + zoxide + eza + bat + ripgrep, verlinkt ~/.zshrc       ║
# ╚══════════════════════════════════════════════════════════════════╝
#  Nutzung:  ./install-shell.sh            (Tools + Config + chsh-Hinweis)
#            ./install-shell.sh --no-pkg   (nur ~/.zshrc verlinken)
set -euo pipefail
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; Y='\033[38;5;214m'; N='\033[0m'
say(){ echo -e "${G}[COSMO]${N} $*"; }
warn(){ echo -e "${Y}[COSMO]${N} $*"; }

# 1) Pakete ---------------------------------------------------------------
if [ "${1:-}" != "--no-pkg" ]; then
    PKGS="zsh fzf zoxide eza bat ripgrep git"
    SUDO=""; [ "$(id -u)" != "0" ] && command -v sudo >/dev/null && SUDO="sudo"
    if command -v apt-get >/dev/null 2>&1; then
        say "installiere Pakete (apt): $PKGS"
        $SUDO apt-get update -qq || true
        # eza gibt es erst ab Ubuntu 24.04/Debian 13 — Fehler tolerieren
        $SUDO apt-get install -y -qq $PKGS 2>/dev/null \
            || $SUDO apt-get install -y -qq zsh fzf zoxide bat ripgrep git
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --noconfirm --needed zsh fzf zoxide eza bat ripgrep git
    elif command -v brew >/dev/null 2>&1; then
        brew install zsh fzf zoxide eza bat ripgrep
    else
        warn "kein Paketmanager erkannt — installiere zsh/fzf/zoxide/eza manuell."
    fi
    # Optionale Extras (Prompt/History) — nur wenn cargo da ist und User will
    if command -v starship >/dev/null 2>&1; then say "starship vorhanden ✔"
    else warn "starship fehlt → Cosmo-Fallback-Prompt aktiv (optional: cargo install starship)"; fi
    if command -v atuin >/dev/null 2>&1; then say "atuin vorhanden ✔"
    else warn "atuin fehlt → fzf uebernimmt Ctrl+R (optional: cargo install atuin)"; fi
fi

# 2) ~/.zshrc verlinken ---------------------------------------------------
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
    warn "bestehende ~/.zshrc gesichert (→ ~/.zshrc.bak.*)"
fi
ln -sfn "$SHELL_DIR/zshrc" "$HOME/.zshrc"
say "~/.zshrc → $SHELL_DIR/zshrc"

# 3) Login-Shell ----------------------------------------------------------
ZSH_BIN="$(command -v zsh || true)"
if [ -n "$ZSH_BIN" ] && [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    if chsh -s "$ZSH_BIN" 2>/dev/null; then
        say "Login-Shell → zsh (neu einloggen zum Aktivieren)"
    else
        warn "chsh nicht moeglich — manuell: chsh -s $ZSH_BIN"
    fi
fi

say "fertig. Teste mit:  zsh   (zinit laedt Plugins beim ersten Start)"
