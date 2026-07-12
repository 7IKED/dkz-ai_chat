#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ODYSSEUS // SKILL-IMPORT  —  Repo/YouTube-Link → Skills+Workflows ║
# ╚══════════════════════════════════════════════════════════════════╝
#  EIN Link, alles uebernommen:
#    skill-import.sh <git-url>            Repo klonen, alle SKILL.md
#                                         verlinken, FLOWS.md erzeugen
#    skill-import.sh <youtube-url>        Video → Skill-Geruest + Notiz
#    skill-import.sh --pack <name>        aus der Registry (registry/packs.tsv)
#    skill-import.sh --all-registry       alle Registry-Packs
#    skill-import.sh --list               installierte Skills zeigen
#    skill-import.sh --link <dir>         lokales Verzeichnis einbinden
#
#  Ziel-Skills:  ${CLAUDE_SKILLS:-~/.claude/skills}   (Symlinks, kollisionssicher)
#  Pack-Cache:   odysseus/skills/packs/<pack>/
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKS="$DIR/skills/packs"
REG="$DIR/skills/registry/packs.tsv"
DEST="${CLAUDE_SKILLS:-$HOME/.claude/skills}"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; Y='\033[38;5;214m'; N='\033[0m'
say(){ echo -e "${G}[SKILL]${N} $*"; }
warn(){ echo -e "${Y}[SKILL]${N} $*"; }
mkdir -p "$PACKS" "$DEST"

# Skill-Namen aus SKILL.md-Frontmatter (name: ...) oder Ordnername
skill_name() {
    local md="$1" n
    n="$(sed -n 's/^name:[[:space:]]*//p' "$md" 2>/dev/null | head -1 | tr -d '"'"'"'' )"
    [ -z "$n" ] && n="$(basename "$(dirname "$md")")"
    echo "$n" | tr 'A-Z ' 'a-z-'
}

# Alle SKILL.md eines Verzeichnisses verlinken (kollisionssicher mit Pack-Prefix)
link_skills() {
    local root="$1" pack="$2" count=0 md name target
    while IFS= read -r md; do
        name="$(skill_name "$md")"
        target="$DEST/$name"
        # Kollision → Pack-Prefix
        if [ -e "$target" ] && [ "$(readlink "$target" 2>/dev/null)" != "$(dirname "$md")" ]; then
            target="$DEST/${pack}-${name}"
        fi
        ln -sfn "$(dirname "$md")" "$target" && count=$((count+1))
    done < <(find "$root" -name SKILL.md -not -path '*/.git/*' 2>/dev/null)
    say "verlinkt: $count Skills aus '$pack' → $DEST"
    echo "$count"
}

# FLOWS.md erzeugen: pro Skill eine Kurz-Workflow-Zeile (ask-matt-Stil)
gen_flows() {
    local root="$1" pack="$2"
    local out="$root/FLOWS.md"
    {
        echo "# 🌊 FLOWS — $pack"
        echo
        echo "> Auto-generiert von odysseus skill-import. Wenige Schritte je Skill."
        echo
        while IFS= read -r md; do
            local name desc dir
            dir="$(dirname "$md")"
            name="$(skill_name "$md")"
            desc="$(sed -n 's/^description:[[:space:]]*//p' "$md" 2>/dev/null | head -1 | tr -d '"'"'"'' | cut -c1-120)"
            [ -z "$desc" ] && desc="$(grep -m1 -v '^-\|^#\|^---\|^name:\|^description:' "$md" 2>/dev/null | cut -c1-120)"
            echo "## /$name"
            echo "${desc:-（keine Beschreibung）}"
            echo
            echo '```'
            echo "1) /$name aufrufen"
            echo "2) Kontext geben (Repo/Datei/Ziel)"
            echo "3) Ergebnis pruefen → uebernehmen"
            echo '```'
            echo
        done < <(find "$root" -name SKILL.md -not -path '*/.git/*' 2>/dev/null | sort)
    } > "$out"
    say "FLOWS → ${out#$DIR/}"
}

import_repo() {
    local url="$1" pack
    pack="$(basename "$url" .git | tr 'A-Z' 'a-z')"
    local dst="$PACKS/$pack"
    if [ -d "$dst/.git" ]; then say "aktualisiere $pack"; git -C "$dst" pull --ff-only -q 2>/dev/null || true
    else say "klone $pack ..."; git clone --depth 1 "$url" "$dst" 2>&1 | tail -1; fi
    [ -d "$dst" ] || { echo -e "${R}[SKILL] Klon fehlgeschlagen: $url${N}"; return 1; }
    link_skills "$dst" "$pack" >/dev/null
    gen_flows "$dst" "$pack"
}

import_youtube() {
    local url="$1" id name dst
    id="$(echo "$url" | sed -n 's/.*[?&]v=\([A-Za-z0-9_-]*\).*/\1/p;s/.*youtu\.be\/\([A-Za-z0-9_-]*\).*/\1/p' | head -1)"
    [ -z "$id" ] && { echo -e "${R}[SKILL] keine YouTube-ID in $url${N}"; return 1; }
    name="yt-$id"; dst="$PACKS/$name/$name"
    mkdir -p "$dst"
    cat > "$dst/SKILL.md" <<EOF
---
name: $name
description: Aus YouTube-Video $id abgeleiteter Skill — Transkript/Notizen ergaenzen.
---
# $name

Quelle: $url

## TODO (vom Operator/Agent zu fuellen)
- [ ] Transkript/Kernaussagen eintragen
- [ ] Schritte als Workflow formulieren
- [ ] Befehle/Snippets ergaenzen

> Tipp: 'odysseus chat ask "Fasse das Video $url in Arbeitsschritten zusammen"'
EOF
    link_skills "$PACKS/$name" "$name" >/dev/null
    gen_flows "$PACKS/$name" "$name"
    say "YouTube-Skill-Geruest → $name (bitte inhaltlich fuellen)"
}

case "${1:-help}" in
    --list)  ls -1 "$DEST" 2>/dev/null | sed 's/^/  /'; echo -e "${DIM}  ($(ls -1 "$DEST" 2>/dev/null | wc -l) Skills in $DEST)${N}";;
    --link)  d="${2:?Verzeichnis fehlt}"; link_skills "$d" "$(basename "$d")" >/dev/null; gen_flows "$d" "$(basename "$d")";;
    --pack)
        p="${2:?Pack-Name fehlt}"
        url="$(awk -F'\t' -v p="$p" '$1==p{print $2}' "$REG" 2>/dev/null)"
        [ -z "$url" ] && { echo -e "${R}[SKILL] Pack '$p' nicht in Registry${N}"; exit 1; }
        import_repo "$url";;
    --all-registry)
        [ -f "$REG" ] || { echo -e "${R}[SKILL] Registry fehlt: $REG${N}"; exit 1; }
        while IFS=$'\t' read -r name url _; do
            [ "${name#\#}" != "$name" ] && continue; [ -z "$url" ] && continue
            import_repo "$url" || warn "uebersprungen: $name"
        done < "$REG"
        say "Registry-Import fertig.";;
    http*|git@*)
        case "$1" in *youtube.com*|*youtu.be*) import_youtube "$1";; *) import_repo "$1";; esac;;
    help|*) sed -n '5,20p' "$0";;
esac
