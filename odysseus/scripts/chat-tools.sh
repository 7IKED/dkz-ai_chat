#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // CHAT-WERKZEUGE                                ║
# ║  Das Modell im Terminal bekommt Werkzeuge: Repos lesen, Status     ║
# ║  abfragen, Cloud durchsuchen, Skills importieren, sprechen.        ║
# ╚══════════════════════════════════════════════════════════════════╝
#  chat-tools.sh                     Chat mit Werkzeugen (REPL)
#  chat-tools.sh repl [agent]        dito, Antworten gehen an <agent>
#  chat-tools.sh list                Werkzeuge zeigen
#  chat-tools.sh schema [ollama|openai|anthropic]   Tool-Definitionen als JSON
#  chat-tools.sh call <name> <json>  Werkzeug direkt aufrufen (zum Testen)
#  chat-tools.sh ask "frage"         Einzelfrage, Werkzeuge aktiv
#
#  ── GRENZEN ───────────────────────────────────────────────────────
#  Lesende Werkzeuge laufen ohne Rueckfrage. Werkzeuge, die etwas
#  veraendern oder Code aus dem Netz holen, sind standardmaessig AUS
#  (OAT_TOOLS_ALLOW_WRITE=0) und fragen auch eingeschaltet nach.
#  Kein Werkzeug fuehrt beliebige Shell-Befehle aus.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$DIR/.env" ] && { set -a; . "$DIR/.env"; set +a; }

if [ -f "$DIR/design/dist/oat-tokens.sh" ]; then
    . "$DIR/design/dist/oat-tokens.sh"
    G="$OAT_FG_PRIMARY"; A="$OAT_FG_ACCENT"; DIM="$OAT_FG_MUTED"
    GREY="$OAT_FG_GREY"; R="$OAT_STATE_ERROR"; Y="$OAT_STATE_WARN"
    W="$OAT_FG_NEUTRAL"; N="$OAT_RESET"
else
    G=$'\033[38;5;46m'; A=$'\033[38;5;82m'; DIM=$'\033[38;5;28m'
    GREY=$'\033[38;5;244m'; R=$'\033[38;5;196m'; Y=$'\033[38;5;214m'
    W=$'\033[38;5;255m'; N=$'\033[0m'
fi

OLLAMA="${OLLAMA_URL:-http://127.0.0.1:11434}"
MODEL="${NANOCHAT_MODEL:-llama3.2}"
ALLOW_WRITE="${OAT_TOOLS_ALLOW_WRITE:-0}"
MAX_ROUNDS="${OAT_TOOLS_MAX_ROUNDS:-6}"
A2A_DIR="$DIR/data/a2a"; mkdir -p "$A2A_DIR"

jq_() { python3 -c 'import json,sys;d=json.load(sys.stdin);
import functools
def get(o,p):
    for k in p.split("."):
        if isinstance(o,list):
            try: o=o[int(k)]
            except Exception: return None
        elif isinstance(o,dict): o=o.get(k)
        else: return None
    return o
v=get(d,sys.argv[1])
print("" if v is None else (v if isinstance(v,str) else json.dumps(v,ensure_ascii=False)))' "$1"; }

json_str() { python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))'; }

# ══════════════════════════════════════════════════════════════════
#  WERKZEUG-REGISTRIERUNG
#  Ein Werkzeug =  Name · Schreibrecht(0/1) · Beschreibung · Parameter
#  Parameter im Kurzformat:  name:typ:pflicht:beschreibung  (| getrennt)
# ══════════════════════════════════════════════════════════════════
tools_def() {
cat <<'TOOLS'
system_status|0|Status aller Dienste im geschlossenen System (online/offline, Ports).|
git_repos|0|Alle Repositories aus Gitea auflisten (Name, Branch, offene Issues, Groesse).|
git_log|0|Die letzten Commits des lokalen Repos.|limit:integer:0:Wie viele Commits (Standard 10, max 50)
git_activity|0|Commit-Aktivitaet der letzten 30 Tage als Zahlen pro Tag.|
git_issues|0|Offene Issues und Pull-Requests eines Gitea-Repos.|repo:string:1:Repository als owner/name
cloud_list|0|Dateien und Ordner in OpenCloud auflisten.|path:string:0:Pfad relativ zum eigenen Bereich, leer = Wurzel
skills_list|0|Welche Skills sind installiert.|
skills_registry|0|Verfuegbare Skill-Packs in der Registry durchsuchen.|query:string:0:Suchbegriff, leer = alle
vault_list|0|Welche Eintraege liegen im Vault (nur Namen, niemals Werte).|
say|0|Text ueber die Voicebox vorlesen lassen.|text:string:1:Der zu sprechende Text
a2a_send|1|Nachricht in die Inbox eines anderen Agenten legen.|agent:string:1:Name des Agenten|message:string:1:Die Nachricht
skills_import|1|Ein Skill-Pack aus der Registry oder von einer URL importieren.|source:string:1:Pack-Name oder Repo-URL
TOOLS
}

tool_names() { tools_def | cut -d'|' -f1; }
tool_write()  { tools_def | awk -F'|' -v n="$1" '$1==n{print $2}'; }
tool_desc()   { tools_def | awk -F'|' -v n="$1" '$1==n{print $3}'; }

# ── JSON-Schema erzeugen ─────────────────────────────────────────────
schema() {
    local style="${1:-ollama}"
    tools_def | ALLOW_WRITE="$ALLOW_WRITE" STYLE="$style" python3 -c '
import json,sys,os
style=os.environ["STYLE"]; allow=os.environ["ALLOW_WRITE"]=="1"
out=[]
for line in sys.stdin:
    line=line.rstrip("\n")
    if not line.strip(): continue
    parts=line.split("|")
    name, write, desc = parts[0], parts[1]=="1", parts[2]
    if write and not allow: continue
    props={}; req=[]
    for p in parts[3:]:
        if not p.strip(): continue
        f=p.split(":")
        if len(f)<4: continue
        pname,ptype,preq,pdesc=f[0],f[1],f[2],":".join(f[3:])
        props[pname]={"type":ptype,"description":pdesc}
        if preq=="1": req.append(pname)
    params={"type":"object","properties":props,"required":req}
    if style=="anthropic":
        out.append({"name":name,"description":desc,"input_schema":params})
    else:  # ollama == openai-Format
        out.append({"type":"function","function":{"name":name,"description":desc,"parameters":params}})
print(json.dumps(out,ensure_ascii=False,indent=2))
'
}

# ══════════════════════════════════════════════════════════════════
#  WERKZEUG-AUSFUEHRUNG
#  Eingabe: Name + JSON-Argumente. Ausgabe: Text fuer das Modell.
#  Kein Argument geht je durch eine Shell.
# ══════════════════════════════════════════════════════════════════
arg() {  # arg <json> <name> [default]
    python3 -c '
import json,sys
try: d=json.loads(sys.argv[1] or "{}")
except Exception: d={}
v=d.get(sys.argv[2], sys.argv[3] if len(sys.argv)>3 else "")
print(v if isinstance(v,str) else json.dumps(v))' "$1" "$2" "${3:-}"
}

safe() {  # kein Shell-Metazeichen, kein Hochhangeln
    case "$1" in
        *[\$\`\;\|\&\>\<\\\'\"]*|*$'\n'*) return 1;;
        ../*|*/../*|*/..|..|-*)           return 1;;
        *) return 0;;
    esac
}

call_tool() {
    local name="$1" args="${2:-{\}}"
    local w; w="$(tool_write "$name")"
    [ -z "$w" ] && { echo "FEHLER: unbekanntes Werkzeug '$name'"; return 1; }
    if [ "$w" = "1" ] && [ "$ALLOW_WRITE" != "1" ]; then
        echo "ABGELEHNT: '$name' veraendert etwas. Einschalten mit OAT_TOOLS_ALLOW_WRITE=1."
        return 1
    fi

    case "$name" in
        system_status)  "$DIR/scripts/odysseus-ctl.sh" status 2>&1 | sed 's/\x1b\[[0-9;]*m//g';;
        git_repos)      "$DIR/scripts/gitviz.sh" repos 2>&1 | sed 's/\x1b\[[0-9;]*m//g';;
        git_activity)   "$DIR/scripts/gitviz.sh" activity 2>&1 | sed 's/\x1b\[[0-9;]*m//g';;
        git_log)
            local lim; lim="$(arg "$args" limit 10)"
            case "$lim" in ''|*[!0-9]*) lim=10;; esac
            [ "$lim" -gt 50 ] 2>/dev/null && lim=50
            git -C "$DIR" log -"$lim" --pretty=format:'%h %ad %an: %s' --date=short 2>&1
            ;;
        git_issues)
            local repo; repo="$(arg "$args" repo)"
            safe "$repo" || { echo "FEHLER: ungueltiger Repo-Name"; return 1; }
            [ -n "$repo" ] || { echo "FEHLER: repo fehlt"; return 1; }
            "$DIR/scripts/gitviz.sh" issues "$repo" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
            ;;
        cloud_list)
            local p; p="$(arg "$args" path)"
            [ -n "$p" ] && { safe "$p" || { echo "FEHLER: ungueltiger Pfad"; return 1; }; }
            local base="http://127.0.0.1:${OPENCLOUD_PORT:-9200}"
            local user="${ADMIN_USER:-admin}" pass="${ADMIN_PASS:-}"
            if [ -z "$pass" ]; then echo "FEHLER: ADMIN_PASS nicht gesetzt — OpenCloud-Zugriff nicht moeglich"; return 1; fi
            curl -fsS --max-time 6 -u "$user:$pass" -X PROPFIND \
                 -H "Depth: 1" "$base/remote.php/dav/files/$user/$p" 2>/dev/null \
              | python3 -c '
import sys,re,xml.etree.ElementTree as ET
raw=sys.stdin.read()
if not raw.strip(): print("(keine Antwort — laeuft OpenCloud?)"); sys.exit()
try: root=ET.fromstring(raw)
except Exception: print("(Antwort nicht lesbar)"); sys.exit()
ns={"d":"DAV:"}
rows=[]
for r in root.findall("d:response",ns):
    href=r.findtext("d:href",default="",namespaces=ns)
    size=r.findtext(".//d:getcontentlength",default="",namespaces=ns)
    coll=r.find(".//d:collection",ns) is not None
    name=href.rstrip("/").split("/")[-1]
    if name: rows.append(("DIR " if coll else "FILE")+" "+name+("" if coll else f"  {size} B"))
print("\n".join(rows[1:]) if len(rows)>1 else "(leer)")
' || echo "FEHLER: OpenCloud nicht erreichbar"
            ;;
        skills_list)    "$DIR/scripts/skill-import.sh" --list 2>&1 | sed 's/\x1b\[[0-9;]*m//g';;
        skills_registry)
            local q; q="$(arg "$args" query)"
            if [ -n "$q" ]; then
                safe "$q" || { echo "FEHLER: ungueltige Suche"; return 1; }
                grep -i -- "$q" "$DIR/skills/registry/packs.tsv" 2>/dev/null | cut -f1,3,4 | head -20
            else
                cut -f1,3,4 "$DIR/skills/registry/packs.tsv" 2>/dev/null | head -50
            fi
            ;;
        vault_list)     "$DIR/scripts/vault.sh" list 2>&1 | sed 's/\x1b\[[0-9;]*m//g';;
        say)
            local t; t="$(arg "$args" text)"
            safe "$t" || { echo "FEHLER: Text enthaelt unerlaubte Zeichen"; return 1; }
            [ -n "$t" ] || { echo "FEHLER: text fehlt"; return 1; }
            "$DIR/scripts/voice.sh" "$t" >/dev/null 2>&1 && echo "gesprochen: $t" || echo "Voicebox nicht erreichbar"
            ;;
        a2a_send)
            local ag msg; ag="$(arg "$args" agent)"; msg="$(arg "$args" message)"
            safe "$ag" || { echo "FEHLER: ungueltiger Agentenname"; return 1; }
            [ -n "$ag" ] && [ -n "$msg" ] || { echo "FEHLER: agent und message noetig"; return 1; }
            confirm_tool "Nachricht an '$ag' senden" || { echo "vom Nutzer abgelehnt"; return 1; }
            printf '{"ts":"%s","from":"%s","msg":%s}\n' "$(date -Is)" "${NANOCHAT_FROM:-chat-tools}" \
                "$(printf '%s' "$msg" | json_str)" >> "$A2A_DIR/$ag.jsonl"
            echo "zugestellt an $ag"
            ;;
        skills_import)
            local s; s="$(arg "$args" source)"
            safe "$s" || { echo "FEHLER: ungueltige Quelle"; return 1; }
            confirm_tool "Skill-Pack '$s' importieren (laedt Code aus dem Netz)" || { echo "vom Nutzer abgelehnt"; return 1; }
            case "$s" in
                http://*|https://*) "$DIR/scripts/skill-import.sh" "$s" 2>&1 | tail -20;;
                *)                  "$DIR/scripts/skill-import.sh" --pack "$s" 2>&1 | tail -20;;
            esac
            ;;
        *) echo "FEHLER: '$name' nicht implementiert"; return 1;;
    esac
}

confirm_tool() {
    [ "${OAT_TOOLS_NOCONFIRM:-0}" = "1" ] && return 0
    printf "\n${Y}  ⚠ %s${N}\n  ${DIM}erlauben? [j/N]${N} " "$1"
    local a; read -r a </dev/tty 2>/dev/null || return 1
    case "$a" in j|J|y|Y) return 0;; *) return 1;; esac
}

# ══════════════════════════════════════════════════════════════════
#  CHAT-SCHLEIFE MIT WERKZEUGEN (Ollama /api/chat, tools[])
# ══════════════════════════════════════════════════════════════════
have_ollama() { curl -fsS --max-time 2 "$OLLAMA/api/tags" >/dev/null 2>&1; }

SYSTEM_PROMPT="Du bist der Operator-Assistent im OPEN AI TERMINAL, einem geschlossenen, lokalen System (Gitea, OpenCloud, Immich, nanoChat, Atuin, Voicebox, Vault). Antworte knapp und auf Deutsch. Nutze die bereitgestellten Werkzeuge, wenn eine Frage echte Daten aus dem System braucht — rate nichts. Gib Ergebnisse verdichtet wieder, nicht als Rohausgabe."

# Verlauf als JSON-Datei (Array von Nachrichten)
HIST=""

hist_init() {
    HIST="$(mktemp "${TMPDIR:-/tmp}/oat-chat.XXXXXX.json")"
    printf '%s' "$SYSTEM_PROMPT" | python3 -c '
import json,sys
print(json.dumps([{"role":"system","content":sys.stdin.read()}]))' > "$HIST"
}
# Wichtig: das Python-Programm MUSS ueber -c kommen. Mit `python3 - <<PY`
# waere stdin vom Here-Doc belegt und der durchgereichte Inhalt kaeme nie an.
hist_add() {  # <role> <-> [tool_name]   — Inhalt ueber stdin
    python3 -c '
import json,sys
path, role, tname = sys.argv[1], sys.argv[2], sys.argv[3]
msgs=json.load(open(path))
m={"role":role,"content":sys.stdin.read()}
if role=="tool" and tname: m["tool_name"]=tname
msgs.append(m)
json.dump(msgs, open(path,"w"), ensure_ascii=False)
' "$HIST" "$1" "${3:-}"
}
hist_add_raw() {  # ganze Assistant-Nachricht (inkl. tool_calls) ueber stdin
    python3 -c '
import json,sys
path=sys.argv[1]
raw=sys.stdin.read().strip()
if not raw: sys.exit(0)
msgs=json.load(open(path))
msgs.append(json.loads(raw))
json.dump(msgs, open(path,"w"), ensure_ascii=False)
' "$HIST"
}

chat_once() {  # eine Runde: schickt Verlauf + Werkzeuge, gibt Antwort aus
    local round=0
    while [ "$round" -lt "$MAX_ROUNDS" ]; do
        round=$((round+1))
        local body resp
        body="$(python3 - "$HIST" "$MODEL" <<'PY'
import json,sys,os,subprocess
hist=json.load(open(sys.argv[1]))
tools=json.loads(subprocess.run([os.environ["SELF"],"schema","ollama"],
                                capture_output=True,text=True).stdout or "[]")
print(json.dumps({"model":sys.argv[2],"messages":hist,"tools":tools,"stream":False}))
PY
)"
        resp="$(printf '%s' "$body" | curl -fsS --max-time 120 "$OLLAMA/api/chat" -H 'Content-Type: application/json' -d @- 2>/dev/null)"
        [ -z "$resp" ] && { printf "${R}  (keine Antwort vom Modell)${N}\n"; return 1; }

        # Assistant-Nachricht in den Verlauf
        printf '%s' "$resp" | python3 -c 'import json,sys;print(json.dumps(json.load(sys.stdin).get("message",{}),ensure_ascii=False))' | hist_add_raw

        local calls; calls="$(printf '%s' "$resp" | python3 -c '
import json,sys
m=json.load(sys.stdin).get("message",{})
for c in (m.get("tool_calls") or []):
    f=c.get("function",{})
    print(f.get("name","")+"\t"+json.dumps(f.get("arguments",{}),ensure_ascii=False))
')"

        if [ -z "$calls" ]; then
            printf '%s' "$resp" | python3 -c '
import json,sys
print(json.load(sys.stdin).get("message",{}).get("content","").strip() or "(leer)")'
            return 0
        fi

        # Werkzeuge ausfuehren, Ergebnisse in den Verlauf
        while IFS=$'\t' read -r tname targs; do
            [ -z "$tname" ] && continue
            printf "${DIM}  ⚙ %s${N} ${GREY}%s${N}\n" "$tname" "$(printf '%s' "$targs" | cut -c1-60)"
            local out; out="$(call_tool "$tname" "$targs" 2>&1 | head -c 4000)"
            printf '%s' "$out" | hist_add tool - "$tname"
        done <<< "$calls"
    done
    printf "${Y}  (Werkzeug-Grenze von %s Runden erreicht)${N}\n" "$MAX_ROUNDS"
}

repl() {
    local agent="${1:-}"
    have_ollama || {
        printf "${R}[CHAT] Kein Modell erreichbar (%s)${N}\n" "$OLLAMA"
        printf "${DIM}  → ollama serve   ·   ollama pull %s${N}\n" "$MODEL"
        printf "${DIM}  → oder die Web-UI: http://127.0.0.1:%s${N}\n" "${LIBRECHAT_PORT:-3080}"
        return 1
    }
    hist_init
    trap 'rm -f "$HIST"' EXIT
    local nt; nt="$(schema ollama | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')"
    printf "${G}╔═ OPEN AI TERMINAL // CHAT MIT WERKZEUGEN ═════════${N}\n"
    printf "${DIM}  Modell: %s @ %s${N}\n" "$MODEL" "$OLLAMA"
    printf "${DIM}  Werkzeuge: %s aktiv%s${N}\n" "$nt" "$([ "$ALLOW_WRITE" = 1 ] && echo ' (inkl. schreibende)' || echo ' — schreibende aus')"
    printf "${DIM}  '/tools' listet sie · '/reset' leert den Verlauf · 'exit' beendet${N}\n"
    [ -n "$agent" ] && printf "${DIM}  Antworten gehen zusaetzlich an Agent '%s'${N}\n" "$agent"
    while true; do
        printf "${W}Operator:~$ ${N}"; read -r line || break
        case "$line" in
            exit|quit) break;;
            "")        continue;;
            /tools)    list_tools; continue;;
            /reset)    hist_init; printf "${DIM}  Verlauf geleert${N}\n"; continue;;
        esac
        printf '%s' "$line" | hist_add user -
        printf "${G}oat:${N} "
        local answer; answer="$(chat_once)"
        printf '%s\n' "$answer"
        if [ -n "$agent" ] && [ -n "$answer" ]; then
            printf '{"ts":"%s","from":"chat","msg":%s}\n' "$(date -Is)" \
                "$(printf '%s' "$answer" | json_str)" >> "$A2A_DIR/$agent.jsonl"
        fi
    done
}

list_tools() {
    printf "${G}╔═ WERKZEUGE ═══════════════════════════════════════${N}\n"
    local n w d
    while IFS='|' read -r n w d _; do
        [ -z "$n" ] && continue
        if [ "$w" = "1" ]; then
            if [ "$ALLOW_WRITE" = "1" ]; then printf "  ${Y}✎ %-17s${N} %s\n" "$n" "$d"
            else                              printf "  ${GREY}✎ %-17s %s  (aus)${N}\n" "$n" "$d"; fi
        else
            printf "  ${A}◦ %-17s${N} ${W}%s${N}\n" "$n" "$d"
        fi
    done < <(tools_def)
    printf "\n${DIM}  ◦ liest nur   ✎ veraendert etwas (OAT_TOOLS_ALLOW_WRITE=1)${N}\n"
}

export SELF="$DIR/scripts/chat-tools.sh"

case "${1:-repl}" in
    list|--list)  list_tools;;
    schema)       shift; schema "${1:-ollama}";;
    call)         shift; call_tool "${1:?Werkzeugname fehlt}" "${2:-{\}}";;
    ask)          shift; have_ollama || { printf "${R}Kein Modell erreichbar${N}\n"; exit 1; }
                  hist_init; trap 'rm -f "$HIST"' EXIT
                  printf '%s' "${*:?Frage fehlt}" | hist_add user -; chat_once;;
    repl)         shift; repl "${1:-}";;
    -h|--help|help) sed -n '6,13p' "$0";;
    *)            repl "$1";;
esac
