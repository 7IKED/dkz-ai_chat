# COSMO_V2 // Aliases — Matrix-Flavor + moderne Ersatz-Tools (mit Fallbacks)

# ls → eza (Icons/Tree), sonst farbiges ls
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
fi

# cat → bat/batcat (Syntax-Highlighting), sonst cat
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never --theme=ansi'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never --theme=ansi'
fi

# grep → ripgrep bevorzugen
command -v rg >/dev/null 2>&1 && alias grep='rg'

alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph -15'

# ── Cosmo Multiplexer Kurzbefehle ───────────────────────────────────
alias cx='cosmo'
alias cxd='cosmo desktop'
alias cxv='cosmo vps'
alias cxa='cosmo agent'
alias cxb='cosmo builder'
alias cxm='cosmo monitor'
alias lanes='"${COSMO_MUX_DIR:-$COSMO_SHELL_DIR/..}"/scripts/testlane.sh --summary'

# Matrix-Gimmick: Regen im Terminal (cmatrix falls installiert)
command -v cmatrix >/dev/null 2>&1 && alias matrix='cmatrix -C green -u 4'
