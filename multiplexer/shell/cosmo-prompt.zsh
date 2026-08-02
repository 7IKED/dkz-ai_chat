# COSMO_V2 // Fallback-Prompt (reines Zsh, kein Starship noetig)
# Matrix-Look:  ┌─[user@host] ~/pfad (git-branch)
#               └─▶
# Gruen bei Erfolg, rot markierter Pfeil nach Fehler-Exit-Code.

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{28}(%f%F{46}%b%f%F{28})%f'
setopt PROMPT_SUBST

# 46 = matrix-green (#00FF41) · 28 = matrix-dim (#008F11) · 196 = rot
PROMPT='%F{28}┌─[%f%F{46}%n%f%F{28}@%f%F{46}%m%f%F{28}]%f %F{46}%~%f${vcs_info_msg_0_}
%F{28}└─%f%(?.%F{46}▶%f.%F{196}▶%f) '
RPROMPT='%F{28}%*%f'
