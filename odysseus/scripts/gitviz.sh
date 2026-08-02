#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // GITVIZ — Repos sichtbar machen                ║
# ║  Gitea-API + lokales Git, gezeichnet im Matrix-Look.               ║
# ╚══════════════════════════════════════════════════════════════════╝
#  gitviz.sh                    Uebersicht: Gitea-Repos + lokales Repo
#  gitviz.sh repos              alle Repos aus Gitea (Sterne, Issues, Groesse)
#  gitviz.sh graph  [pfad]      Commit-Graph (lokal, eingefaerbt)
#  gitviz.sh activity [repo]    Commits pro Tag als Sparkline (30 Tage)
#  gitviz.sh authors  [repo]    Autoren als Balken
#  gitviz.sh branches [repo]    Branches mit ahead/behind zu HEAD
#  gitviz.sh issues  <repo>     offene Issues + PRs aus Gitea
#  gitviz.sh watch              Dauerpanel (fuer das Layout)
#
#  <repo> = owner/name (Gitea)   ·   [pfad] = lokales Arbeitsverzeichnis
#  Token: $GITEA_TOKEN oder Vault-Eintrag api/gitea (ohne Token nur
#  oeffentliche Repos).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Farben aus dem Cloud Design System (dist/), sonst Fallback.
if [ -f "$DIR/design/dist/oat-tokens.sh" ]; then
    . "$DIR/design/dist/oat-tokens.sh"
    G="$OAT_FG_PRIMARY"; A="$OAT_FG_ACCENT"; DIM="$OAT_FG_MUTED"
    GREY="$OAT_FG_GREY"; R="$OAT_STATE_ERROR"; Y="$OAT_STATE_WARN"
    W="$OAT_FG_NEUTRAL"; N="$OAT_RESET"
else
    G=$'\033[38;5;46m';  A=$'\033[38;5;82m';  DIM=$'\033[38;5;28m'
    GREY=$'\033[38;5;244m'; R=$'\033[38;5;196m'; Y=$'\033[38;5;214m'
    W=$'\033[38;5;255m'; N=$'\033[0m'
fi

API="http://127.0.0.1:${GITEA_PORT:-3300}/api/v1"
SPARK=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
BLOCK=█

have() { command -v "$1" >/dev/null 2>&1; }
py()   { python3 "$@"; }

token() {
    [ -n "${GITEA_TOKEN:-}" ] && { printf '%s' "$GITEA_TOKEN"; return; }
    # still aus dem Vault ziehen, falls dort hinterlegt
    [ -x "$DIR/scripts/vault.sh" ] && "$DIR/scripts/vault.sh" get api/gitea 2>/dev/null || true
}

api() {  # api <pfad>  → JSON auf stdout, leer bei Fehler
    local t; t="$(token)"
    if [ -n "$t" ]; then
        curl -fsS --max-time 5 -H "Authorization: token $t" "$API/$1" 2>/dev/null
    else
        curl -fsS --max-time 5 "$API/$1" 2>/dev/null
    fi
}

gitea_up() { curl -fsS --max-time 2 "$API/version" >/dev/null 2>&1; }

rule()  { printf "${DIM}%s${N}\n" "────────────────────────────────────────────────────────────"; }
head2() { printf "\n${G}╔═ %s ${N}${DIM}%s${N}\n" "$1" "$(printf '═%.0s' $(seq 1 $((50 - ${#1} > 0 ? 50 - ${#1} : 1))))"; }

# ── Balken zeichnen ──────────────────────────────────────────────────
bar() {  # bar <wert> <max> <breite>
    local v="$1" max="$2" w="${3:-24}" n
    [ "$max" -le 0 ] 2>/dev/null && max=1
    n=$(( v * w / max )); [ "$n" -lt 1 ] && [ "$v" -gt 0 ] && n=1
    local i out=""
    for ((i=0;i<n;i++)); do out+="$BLOCK"; done
    for ((i=n;i<w;i++)); do out+="·"; done
    printf '%s' "$out"
}

# ── Sparkline aus Zahlenliste (stdin, eine Zahl je Zeile) ────────────
sparkline() {
    py -c '
import sys
vals=[int(x) for x in sys.stdin.read().split() if x.strip().isdigit()]
if not vals: print(""); sys.exit()
chars="▁▂▃▄▅▆▇█"; hi=max(vals) or 1
print("".join(chars[min(7, v*7//hi)] if v else "·" for v in vals))
'
}

# ── lokales Repo bestimmen ───────────────────────────────────────────
repo_path() {
    local p="${1:-$PWD}"
    git -C "$p" rev-parse --show-toplevel 2>/dev/null && return
    git -C "$DIR" rev-parse --show-toplevel 2>/dev/null && return
    return 1
}

# ── 1) REPOS aus Gitea ───────────────────────────────────────────────
cmd_repos() {
    head2 "GITEA REPOS"
    if ! gitea_up; then
        printf "  ${R}○ Gitea nicht erreichbar${N} ${GREY}%s${N}\n" "$API"
        printf "  ${GREY}  Stack starten: odysseus up${N}\n"
        return 1
    fi
    local json; json="$(api 'repos/search?limit=50&sort=updated')"
    [ -z "$json" ] && { printf "  ${Y}Keine Antwort (Token noetig fuer private Repos?)${N}\n"; return 1; }
    printf "$json" | py -c '
import json,sys
d=json.load(sys.stdin)
rows=d.get("data",[])
if not rows: print("  (keine Repos)"); sys.exit()
G="\033[38;5;46m"; DIM="\033[38;5;28m"; GY="\033[38;5;244m"; W="\033[38;5;255m"; N="\033[0m"; Y="\033[38;5;214m"
print(f"  {DIM}{'REPO':<34}{'BRANCH':<12}{'ISSUES':>7}{'STARS':>7}{'GROESSE':>10}{N}")
for r in rows:
    name=r.get("full_name","?")[:33]
    br=(r.get("default_branch") or "-")[:11]
    iss=r.get("open_issues_count",0); st=r.get("stars_count",0)
    kb=r.get("size",0)
    size=f"{kb/1024:.1f} MB" if kb>=1024 else f"{kb} KB"
    flag=Y+" ●"+N if r.get("private") else "  "
    ic=(Y if iss else GY)
    print(f"  {G}{name:<34}{N}{DIM}{br:<12}{N}{ic}{iss:>7}{N}{GY}{st:>7}{N}{W}{size:>10}{N}{flag}")
print(f"\n  {DIM}{len(rows)} Repos{N}")
'
}

# ── 2) COMMIT-GRAPH (lokal) ──────────────────────────────────────────
cmd_graph() {
    local p; p="$(repo_path "${1:-}")" || { printf "  ${R}Kein Git-Repo${N}\n"; return 1; }
    head2 "COMMIT-GRAPH  $(basename "$p")"
    git -C "$p" log --graph --all --date-order -30 \
        --pretty=format:"%h%x09%d%x09%an%x09%ar%x09%s" 2>/dev/null | \
    py -c '
import sys,re
G="\033[38;5;46m"; A="\033[38;5;82m"; DIM="\033[38;5;28m"; GY="\033[38;5;244m"
W="\033[38;5;255m"; Y="\033[38;5;214m"; N="\033[0m"
for line in sys.stdin:
    line=line.rstrip("\n")
    if "\t" not in line:
        print(DIM+line+N); continue
    rail, rest = line.split("\t",1) if line.count("\t")>=1 else (line,"")
    # Der Graph-Teil steht vor dem ersten Feld — Rails einfaerben
    m=re.match(r"^([\s|\\/*_-]*)(.*)$", rail)
    rails, sha = m.group(1), m.group(2)
    parts=(sha+"\t"+rest).split("\t")
    while len(parts)<5: parts.append("")
    sha,refs,author,when,subj = parts[:5]
    rails=rails.replace("*", G+"●"+DIM)
    refs=refs.strip()
    reftxt=" "+Y+refs+N if refs else ""
    print(f"{DIM}{rails}{N}{A}{sha:<8}{N}{W}{subj[:52]:<52}{N}{reftxt} {GY}{author[:14]} · {when}{N}")
'
    local n; n="$(git -C "$p" rev-list --count HEAD 2>/dev/null || echo 0)"
    printf "\n  ${DIM}%s Commits gesamt · %s${N}\n" "$n" "$(git -C "$p" rev-parse --abbrev-ref HEAD 2>/dev/null)"
}

# ── 3) AKTIVITAET als Sparkline ──────────────────────────────────────
cmd_activity() {
    local p; p="$(repo_path "${1:-}")" || { printf "  ${R}Kein Git-Repo${N}\n"; return 1; }
    head2 "AKTIVITAET  $(basename "$p")"
    local days=30
    local counts; counts="$(git -C "$p" log --since="$days days ago" --date=short --pretty=%ad 2>/dev/null | sort | uniq -c)"
    local line; line="$(
        py -c '
import sys,subprocess,datetime,collections
days=int(sys.argv[1]); path=sys.argv[2]
out=subprocess.run(["git","-C",path,"log",f"--since={days} days ago","--date=short","--pretty=%ad"],
                   capture_output=True,text=True).stdout.split()
c=collections.Counter(out)
today=datetime.date.today()
print(" ".join(str(c.get(str(today-datetime.timedelta(days=days-1-i)),0)) for i in range(days)))
' "$days" "$p"
    )"
    local spark; spark="$(printf '%s\n' $line | sparkline)"
    local total=0 v
    for v in $line; do total=$((total+v)); done
    printf "  ${G}%s${N}\n" "$spark"
    printf "  ${DIM}%-*s%s${N}\n" $((days-9)) "vor $days Tagen" "heute"
    printf "\n  ${W}%s${N} ${DIM}Commits in %s Tagen${N}   ${W}%s${N} ${DIM}pro Tag im Schnitt${N}\n" \
        "$total" "$days" "$(py -c "print(f'{$total/$days:.1f}')")"
    # aktivste Tage
    printf "\n  ${DIM}Aktivste Tage:${N}\n"
    printf '%s' "$counts" | sort -rn | head -3 | while read -r cnt day; do
        printf "    ${A}%-12s${N} ${G}%s${N} ${GREY}%s${N}\n" "$day" "$(bar "$cnt" 20 18)" "$cnt"
    done
}

# ── 4) AUTOREN ───────────────────────────────────────────────────────
cmd_authors() {
    local p; p="$(repo_path "${1:-}")" || { printf "  ${R}Kein Git-Repo${N}\n"; return 1; }
    head2 "AUTOREN  $(basename "$p")"
    local data; data="$(git -C "$p" shortlog -sn --all --no-merges 2>/dev/null | head -10)"
    [ -z "$data" ] && { printf "  ${GREY}(keine Commits)${N}\n"; return; }
    local max; max="$(printf '%s' "$data" | head -1 | awk '{print $1}')"
    printf '%s\n' "$data" | while read -r cnt name; do
        printf "  ${W}%-22s${N} ${G}%s${N} ${GREY}%s${N}\n" "${name:0:22}" "$(bar "$cnt" "$max" 26)" "$cnt"
    done
    printf "\n  ${DIM}Dateien: %s · Zeilen: %s${N}\n" \
        "$(git -C "$p" ls-files 2>/dev/null | wc -l | tr -d ' ')" \
        "$(git -C "$p" ls-files 2>/dev/null | xargs -r wc -l 2>/dev/null | tail -1 | awk '{print $1}')"
}

# ── 5) BRANCHES ──────────────────────────────────────────────────────
cmd_branches() {
    local p; p="$(repo_path "${1:-}")" || { printf "  ${R}Kein Git-Repo${N}\n"; return 1; }
    head2 "BRANCHES  $(basename "$p")"
    local cur; cur="$(git -C "$p" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    git -C "$p" for-each-ref --sort=-committerdate refs/heads refs/remotes \
        --format='%(refname:short)|%(committerdate:relative)|%(authorname)|%(objectname:short)' 2>/dev/null | head -14 | \
    while IFS='|' read -r ref when who sha; do
        local mark="  " col="$W"
        [ "$ref" = "$cur" ] && { mark="${G}▶ ${N}"; col="$G"; }
        local ab=""
        if [ "$ref" != "$cur" ]; then
            local counts; counts="$(git -C "$p" rev-list --left-right --count "$cur...$ref" 2>/dev/null)"
            if [ -n "$counts" ]; then
                local behind ahead; behind="$(printf '%s' "$counts" | awk '{print $1}')"; ahead="$(printf '%s' "$counts" | awk '{print $2}')"
                [ "$ahead" != "0" ] && ab+="${A}+$ahead${N}"
                [ "$behind" != "0" ] && ab+="${R}-$behind${N}"
            fi
        fi
        printf "  %b${col}%-34s${N} ${DIM}%-10s${N} ${GREY}%-14s${N} %b\n" "$mark" "${ref:0:34}" "$sha" "${who:0:14}" "$ab"
    done
    printf "\n  ${DIM}+n = Commits, die dieser Branch vor %s hat · -n = die ihm fehlen${N}\n" "$cur"
}

# ── 6) ISSUES/PRs aus Gitea ──────────────────────────────────────────
cmd_issues() {
    local repo="${1:-}"
    [ -z "$repo" ] && { printf "  ${R}Repo fehlt:${N} gitviz.sh issues owner/name\n"; return 1; }
    head2 "ISSUES  $repo"
    gitea_up || { printf "  ${R}○ Gitea nicht erreichbar${N}\n"; return 1; }
    api "repos/$repo/issues?state=open&limit=20" | py -c '
import json,sys
try: rows=json.load(sys.stdin)
except Exception: rows=[]
G="\033[38;5;46m"; A="\033[38;5;82m"; DIM="\033[38;5;28m"; GY="\033[38;5;244m"
W="\033[38;5;255m"; Y="\033[38;5;214m"; N="\033[0m"
if not rows: print(f"  {DIM}(keine offenen Issues){N}"); sys.exit()
for r in rows:
    kind = f"{A}PR {N}" if r.get("pull_request") else f"{Y}ISS{N}"
    lbl = " ".join(f"{DIM}[{l['name']}]{N}" for l in (r.get("labels") or [])[:3])
    print(f"  {kind} {G}#{r.get('number'):<5}{N}{W}{r.get('title','')[:46]:<46}{N} {lbl} {GY}{(r.get('user') or {}).get('login','')}{N}")
print(f"\n  {DIM}{len(rows)} offen{N}")
'
}

# ── 7) UEBERSICHT ────────────────────────────────────────────────────
cmd_overview() {
    printf "${G}╔══════════════════════════════════════════════════════════╗${N}\n"
    printf "${G}║  OPEN AI TERMINAL // GITVIZ                              ║${N}\n"
    printf "${G}╚══════════════════════════════════════════════════════════╝${N}\n"
    if gitea_up; then
        local v; v="$(api version | py -c 'import json,sys;print(json.load(sys.stdin).get("version","?"))' 2>/dev/null || echo '?')"
        printf "  ${G}● GITEA ONLINE${N}  ${DIM}%s · v%s${N}\n" "$API" "$v"
        cmd_repos
    else
        printf "  ${R}○ GITEA OFFLINE${N} ${DIM}%s${N}\n" "$API"
        printf "  ${GREY}  → odysseus up${N}\n"
    fi
    local p
    if p="$(repo_path 2>/dev/null)"; then
        cmd_activity "$p"
        cmd_branches "$p"
    fi
    printf "\n${DIM}  gitviz graph · activity · authors · branches · repos · issues <owner/name>${N}\n"
}

case "${1:-overview}" in
    repos)     cmd_repos;;
    graph)     shift; cmd_graph "${1:-}";;
    activity)  shift; cmd_activity "${1:-}";;
    authors)   shift; cmd_authors "${1:-}";;
    branches)  shift; cmd_branches "${1:-}";;
    issues)    shift; cmd_issues "${1:-}";;
    watch)     while true; do clear; cmd_overview; sleep 30; done;;
    overview)  cmd_overview;;
    -h|--help|help) sed -n '6,19p' "$0";;
    *)         cmd_graph "$1";;
esac
