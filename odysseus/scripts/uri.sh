#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // URI-HANDLER   oat://…                         ║
# ║  Ein Link aus Gitea, Chat oder Cloud oeffnet die richtige Stelle   ║
# ║  IM TERMINAL — statt im Browser.                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#  uri.sh <oat://…>          URI ausfuehren
#  uri.sh install            als Systemhandler registrieren
#  uri.sh uninstall          wieder entfernen
#  uri.sh list               alle unterstuetzten URIs zeigen
#  uri.sh test <oat://…>     nur anzeigen, was passieren wuerde (--dry-run)
#
#  ── SICHERHEIT ────────────────────────────────────────────────────
#  Ein URI-Handler ist eine Tuer von aussen: jede Webseite kann
#  oat://… aufrufen. Deshalb gilt hier:
#    · feste Whitelist von Aktionen — nichts anderes wird ausgefuehrt
#    · KEINE Aktion, die beliebige Befehle ausfuehrt (kein oat://run/…)
#    · Argumente werden validiert (Zeichensatz), nie an eine Shell
#      weitergereicht, immer als Array an das Zielprogramm
#    · schreibende/gefaehrliche Ziele fragen nach (OAT_URI_CONFIRM=0 aus)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="oat"

if [ -f "$DIR/design/dist/oat-tokens.sh" ]; then
    . "$DIR/design/dist/oat-tokens.sh"
    G="$OAT_FG_PRIMARY"; A="$OAT_FG_ACCENT"; DIM="$OAT_FG_MUTED"
    GREY="$OAT_FG_GREY"; R="$OAT_STATE_ERROR"; Y="$OAT_STATE_WARN"; N="$OAT_RESET"
else
    G=$'\033[38;5;46m'; A=$'\033[38;5;82m'; DIM=$'\033[38;5;28m'
    GREY=$'\033[38;5;244m'; R=$'\033[38;5;196m'; Y=$'\033[38;5;214m'; N=$'\033[0m'
fi

DRY=0
die() { printf "${R}[URI] %s${N}\n" "$*" >&2; exit 1; }
say() { printf "${G}[URI]${N} %s\n" "$*"; }

# ── URL-Dekodierung (%XX und +) ──────────────────────────────────────
urldecode() { python3 -c 'import sys,urllib.parse;sys.stdout.write(urllib.parse.unquote_plus(sys.argv[1]))' "$1"; }

# ── Validierung: nur harmlose Zeichen in Argumenten ──────────────────
# Erlaubt: Buchstaben, Ziffern, . _ - / @ + Leerzeichen und Umlaute.
# Verboten: alles, was in einer Shell etwas bedeutet ($ ` ; | & > < \ ' " newline)
valid_arg() {
    case "$1" in
        *[\$\`\;\|\&\>\<\\\'\"]*) return 1;;
        *$'\n'*|*$'\r'*)          return 1;;
        ../*|*/../*|*/..|..)      return 1;;   # kein Hochhangeln im Pfad
        -*)                       return 1;;   # nichts, was als Option gelesen wird
        *)                        return 0;;
    esac
}

# ── Ausfuehren (nie ueber eine Shell — immer Argument-Array) ─────────
run() {
    if [ "$DRY" = "1" ]; then
        printf "  ${DIM}wuerde ausfuehren:${N} ${A}%s${N}\n" "$*"
        return 0
    fi
    "$@"
}

confirm() {  # confirm "<was>"  → 0 wenn ok
    [ "${OAT_URI_CONFIRM:-1}" = "0" ] && return 0
    [ "$DRY" = "1" ] && return 0
    printf "${Y}[URI] %s${N}\n" "$1"
    printf "      Ausfuehren? [j/N] "
    local a; read -r a </dev/tty 2>/dev/null || return 1
    case "$a" in j|J|y|Y) return 0;; *) printf "${DIM}      abgebrochen${N}\n"; return 1;; esac
}

# ── Die Whitelist ────────────────────────────────────────────────────
# Format:  aktion | argumentmuster | beschreibung
list_uris() {
    printf "${G}╔═ OPEN AI TERMINAL // URI-SCHEMA  %s://  ══════════${N}\n" "$SCHEME"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://repo/<owner>/<name>"      "Repo in GITVIZ oeffnen"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://repo/<owner>/<name>/issues" "offene Issues des Repos"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://commit/<sha>"             "Commit im lokalen Repo zeigen"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://gitviz/<ansicht>"         "graph|activity|authors|branches"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://cloud/<pfad>"             "Ordner in OpenCloud (Terminal-Browser)"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://fotos"                    "Immich"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://chat/<agent>"             "Chat mit Werkzeugen"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://a2a/<agent>?msg=<text>"   "Nachricht in die A2A-Inbox"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://inbox/<agent>"            "A2A-Inbox verfolgen"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://say?text=<text>"          "Voicebox vorlesen lassen"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://skills/<pack>"            "Skill-Pack importieren ${Y}(fragt nach)${N}"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://vault/<eintrag>"          "Vault-Eintrag ${Y}(fragt nach)${N}"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://status"                   "Systemstatus"
    printf "  ${A}%-34s${N} %s\n" "$SCHEME://terminal"                 "das Matrix-Terminal starten"
    printf "\n${DIM}  Nicht vorgesehen und nicht implementiert: beliebige Befehle.${N}\n"
    printf "${DIM}  Es gibt kein %s://run/… — ein URI-Handler ist von aussen erreichbar.${N}\n" "$SCHEME"
}

# ── URI zerlegen ─────────────────────────────────────────────────────
handle() {
    local uri="$1"
    case "$uri" in
        "$SCHEME"://*) ;;
        odysseus://*)  uri="$SCHEME://${uri#odysseus://}";;   # Altlast
        *) die "Kein $SCHEME://-URI: $uri";;
    esac

    local rest="${uri#"$SCHEME"://}"
    local path="${rest%%\?*}"
    local query=""
    [ "$rest" != "$path" ] && query="${rest#*\?}"
    path="${path%/}"

    local action="${path%%/*}"
    local arg=""
    [ "$path" != "$action" ] && arg="${path#*/}"
    arg="$(urldecode "$arg")"

    # Query-Parameter holen (nur die, die wir kennen)
    qp() {
        local key="$1" kv
        local IFS='&'
        for kv in $query; do
            [ "${kv%%=*}" = "$key" ] && { urldecode "${kv#*=}"; return; }
        done
    }

    if [ -n "$arg" ] && ! valid_arg "$arg"; then
        die "Argument enthaelt unerlaubte Zeichen: $arg"
    fi

    local ODY="$DIR/bin/odysseus"
    [ -x "$ODY" ] || ODY="bash $DIR/bin/odysseus"

    case "$action" in
        repo)
            # owner/name  oder  owner/name/issues
            case "$arg" in
                */*/issues) run "$DIR/scripts/gitviz.sh" issues "${arg%/issues}";;
                */*)        run "$DIR/scripts/gitviz.sh" issues "$arg" ;;
                "")         die "Repo fehlt: $SCHEME://repo/owner/name";;
                *)          die "Repo muss owner/name sein: $arg";;
            esac
            ;;
        commit)
            [ -n "$arg" ] || die "SHA fehlt"
            case "$arg" in *[!0-9a-fA-F]*) die "Kein gueltiger Commit-SHA: $arg";; esac
            run git -C "$DIR" show --stat --color=always "$arg"
            ;;
        gitviz)
            case "${arg:-overview}" in
                graph|activity|authors|branches|repos|overview) run "$DIR/scripts/gitviz.sh" "${arg:-overview}";;
                *) die "Unbekannte Ansicht: $arg (graph|activity|authors|branches|repos)";;
            esac
            ;;
        cloud)
            local base="http://127.0.0.1:${OPENCLOUD_PORT:-9200}"
            [ -n "$arg" ] && base="$base/files/spaces/personal/home/$arg"
            run "$DIR/scripts/browser.sh" "$base"
            ;;
        fotos|immich) run "$DIR/scripts/browser.sh" fotos;;
        gitea)        run "$DIR/scripts/browser.sh" gitea;;
        chat)
            if [ -n "$arg" ]; then run "$DIR/scripts/chat-tools.sh" repl "$arg"
            else                   run "$DIR/scripts/chat-tools.sh" repl; fi
            ;;
        a2a)
            [ -n "$arg" ] || die "Agent fehlt"
            local msg; msg="$(qp msg)"
            [ -n "$msg" ] || die "msg=… fehlt"
            valid_arg "$msg" || die "Nachricht enthaelt unerlaubte Zeichen"
            run "$DIR/scripts/nanochat.sh" a2a "$arg" "$msg"
            ;;
        inbox)
            [ -n "$arg" ] || die "Agent fehlt"
            run "$DIR/scripts/nanochat.sh" inbox "$arg"
            ;;
        say)
            local text; text="$(qp text)"; [ -n "$text" ] || text="$arg"
            [ -n "$text" ] || die "text=… fehlt"
            valid_arg "$text" || die "Text enthaelt unerlaubte Zeichen"
            run "$DIR/scripts/voice.sh" "$text"
            ;;
        skills)
            [ -n "$arg" ] || die "Pack/URL fehlt"
            confirm "Skill-Pack importieren: $arg (laedt Code aus dem Netz)" || exit 0
            case "$arg" in
                http://*|https://*) run "$DIR/scripts/skill-import.sh" "$arg";;
                *)                  run "$DIR/scripts/skill-import.sh" --pack "$arg";;
            esac
            ;;
        vault)
            [ -n "$arg" ] || die "Eintrag fehlt"
            confirm "Vault-Eintrag anzeigen: $arg" || exit 0
            run "$DIR/scripts/vault.sh" get "$arg"
            ;;
        status)   run "$DIR/scripts/odysseus-ctl.sh" status;;
        terminal) run $ODY terminal;;
        ""|list)  list_uris;;
        *)        die "Unbekannte Aktion '$action' — $SCHEME://list zeigt alle";;
    esac
}

# ── Registrierung im Betriebssystem ──────────────────────────────────
install_linux() {
    local apps="$HOME/.local/share/applications"
    local desktop="$apps/oat-uri.desktop"
    local term="" t
    for t in x-terminal-emulator alacritty kitty wezterm foot gnome-terminal konsole xterm; do
        command -v "$t" >/dev/null 2>&1 && { term="$t"; break; }
    done
    mkdir -p "$apps"

    # Wrapper, der im Terminal oeffnet und offen bleibt
    local wrap="$HOME/.local/bin/oat-uri"
    mkdir -p "$HOME/.local/bin"
    cat > "$wrap" <<EOF
#!/usr/bin/env bash
# erzeugt von: odysseus uri install
exec "$DIR/scripts/uri.sh" "\$1"
EOF
    chmod +x "$wrap"

    local execline
    case "$term" in
        gnome-terminal) execline="gnome-terminal -- bash -lc '$wrap \"%u\"; exec bash'";;
        konsole)        execline="konsole -e bash -lc '$wrap \"%u\"; exec bash'";;
        ""|xterm)       execline="xterm -e bash -lc '$wrap \"%u\"; exec bash'";;
        *)              execline="$term -e bash -lc '$wrap \"%u\"; exec bash'";;
    esac

    cat > "$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=OPEN AI TERMINAL
Comment=oat:// im Terminal oeffnen
Exec=$execline
Icon=utilities-terminal
Terminal=false
NoDisplay=true
MimeType=x-scheme-handler/$SCHEME;
Categories=Development;System;
EOF

    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$apps" 2>/dev/null
    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime default oat-uri.desktop "x-scheme-handler/$SCHEME" 2>/dev/null \
            && say "als Standard fuer $SCHEME:// gesetzt"
    fi
    say "Linux: $desktop"
    say "Terminal: ${term:-xterm}"
    printf "${DIM}  Test:  xdg-open '$SCHEME://status'${N}\n"
}

install_windows_reg() {
    local reg="$DIR/oat-uri.reg"
    cat > "$reg" <<EOF
Windows Registry Editor Version 5.00

; OPEN AI TERMINAL — URI-Handler  ${SCHEME}://
; Erzeugt von: odysseus uri install
; Anwenden: Doppelklick (fragt nach Bestaetigung)
; Voraussetzung: WSL mit installiertem System unter ~/DEVKiTZ/odysseus

[HKEY_CURRENT_USER\\Software\\Classes\\${SCHEME}]
@="URL:OPEN AI TERMINAL"
"URL Protocol"=""

[HKEY_CURRENT_USER\\Software\\Classes\\${SCHEME}\\DefaultIcon]
@="%SystemRoot%\\\\System32\\\\wsl.exe,0"

[HKEY_CURRENT_USER\\Software\\Classes\\${SCHEME}\\shell]

[HKEY_CURRENT_USER\\Software\\Classes\\${SCHEME}\\shell\\open]

[HKEY_CURRENT_USER\\Software\\Classes\\${SCHEME}\\shell\\open\\command]
@="wt.exe wsl.exe -- bash -lic \\"~/DEVKiTZ/odysseus/scripts/uri.sh '%1'; exec bash\\""
EOF
    say "Windows: $reg erzeugt"
    printf "${DIM}  Auf dem Windows-Rechner doppelklicken (bzw. 'reg import oat-uri.reg').\n"
    printf "  Ohne Windows Terminal (wt.exe): den Befehl im .reg auf 'wsl.exe' kuerzen.${N}\n"
}

do_install() {
    case "$(uname -s)" in
        Linux*)  install_linux; install_windows_reg;;
        Darwin*) printf "${Y}[URI] macOS: Scheme-Handler brauchen ein .app-Bundle.${N}\n"
                 printf "${DIM}  Kuerzester Weg: Automator → 'Programm' → Shell-Skript\n"
                 printf "    \"$DIR/scripts/uri.sh\" \"\$1\"\n"
                 printf "  sichern, dann in Info.plist CFBundleURLSchemes = $SCHEME eintragen.${N}\n";;
        *)       install_windows_reg;;
    esac
}

do_uninstall() {
    local d="$HOME/.local/share/applications/oat-uri.desktop"
    [ -f "$d" ] && { rm -f "$d"; say "entfernt: $d"; }
    [ -f "$HOME/.local/bin/oat-uri" ] && { rm -f "$HOME/.local/bin/oat-uri"; say "entfernt: ~/.local/bin/oat-uri"; }
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" 2>/dev/null
    [ -f "$DIR/oat-uri.reg" ] && { rm -f "$DIR/oat-uri.reg"; say "entfernt: oat-uri.reg"; }
    say "fertig — Windows-Registry ggf. von Hand bereinigen (HKCU\\Software\\Classes\\$SCHEME)"
}

case "${1:-list}" in
    install)   do_install;;
    uninstall) do_uninstall;;
    list|--list) list_uris;;
    test)      DRY=1; shift; handle "${1:?URI fehlt}";;
    -h|--help|help) sed -n '6,11p' "$0";;
    *)         handle "$1";;
esac
