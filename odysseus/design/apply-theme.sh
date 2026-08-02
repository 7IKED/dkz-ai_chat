#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // THEME ANWENDEN                                ║
# ║  Traegt das Cloud Design System in die laufenden Web-UIs ein.      ║
# ╚══════════════════════════════════════════════════════════════════╝
#  apply-theme.sh            alle erreichbaren Dienste themen
#  apply-theme.sh gitea      nur einen Dienst (gitea|opencloud|nextcloud|librechat)
#  apply-theme.sh --status   zeigen, was gethemt ist
#
#  Grundsatz: NUR CSS-Variablen der jeweiligen UI setzen (themes/inject.css),
#  keine Selektor-Hacks — damit Updates der Fremdprojekte nichts zerreissen.
set -uo pipefail
DESIGN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$(cd "$DESIGN/.." && pwd)"
CSS="$DESIGN/themes/inject.css"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; Y='\033[38;5;214m'; N='\033[0m'
ok()   { echo -e "  ${G}✔${N} $*"; }
skip() { echo -e "  ${DIM}– $*${N}"; }
fail() { echo -e "  ${R}✖${N} $*"; }

DC() { docker compose -f "$DIR/docker-compose.yml" "$@"; }
running() { DC ps --status running --format '{{.Service}}' 2>/dev/null | grep -qx "$1"; }
cid() { DC ps -q "$1" 2>/dev/null; }

# inject.css mit aufgeloestem @import ausliefern (Fremd-UIs laden keine
# relativen Imports aus fremden Pfaden).
bundle() {
    local out="$1"
    { sed '/@import/d' "$DESIGN/css/tokens.css"
      echo
      sed '/@import/d' "$CSS"
    } > "$out"
}

theme_gitea() {
    running gitea || { skip "gitea laeuft nicht"; return; }
    local tmp; tmp="$(mktemp)"; bundle "$tmp"
    local c; c="$(cid gitea)"
    docker exec "$c" mkdir -p /data/gitea/public/assets/css 2>/dev/null
    if docker cp "$tmp" "$c:/data/gitea/public/assets/css/theme-oat-matrix.css" 2>/dev/null; then
        ok "gitea — theme-oat-matrix.css eingespielt"
        echo -e "    ${DIM}aktivieren: Profil → Einstellungen → Design → 'oat-matrix'"
        echo -e "    systemweit: GITEA__ui__DEFAULT_THEME=oat-matrix in .env, dann 'odysseus up'${N}"
    else
        fail "gitea — docker cp fehlgeschlagen"
    fi
    rm -f "$tmp"
}

theme_opencloud() {
    running opencloud || { skip "opencloud laeuft nicht"; return; }
    # theme.json + Assets sind per Bind-Mount aus design/themes/ eingebunden
    # (siehe docker-compose.yml). Hier nur pruefen und neu laden.
    local c; c="$(cid opencloud)"
    if docker exec "$c" test -f /var/lib/opencloud/web/assets/themes/opencloud/theme.json 2>/dev/null; then
        ok "opencloud — theme.json gemountet"
        DC restart opencloud >/dev/null 2>&1 && ok "opencloud — neu geladen" || fail "opencloud — Neustart fehlgeschlagen"
    else
        fail "opencloud — theme.json nicht im Container (Mount pruefen: docker compose config opencloud)"
    fi
}

theme_nextcloud() {
    running nextcloud || { skip "nextcloud laeuft nicht (optionales Profil 'nextcloud')"; return; }
    local c; c="$(cid nextcloud)"
    local occ="php occ"
    docker exec -u www-data "$c" $occ theming:config color "#00FF41"    >/dev/null 2>&1 && ok "nextcloud — Primaerfarbe" || fail "nextcloud — occ theming:config"
    docker exec -u www-data "$c" $occ theming:config name "OPEN AI TERMINAL" >/dev/null 2>&1 || true
    docker exec -u www-data "$c" $occ theming:config slogan "Geschlossenes System" >/dev/null 2>&1 || true
    docker exec -u www-data "$c" $occ config:system:set enforce_theme --value dark >/dev/null 2>&1 && ok "nextcloud — Dark erzwungen" || true
    echo -e "    ${DIM}Volles Matrix-CSS braucht die App 'Custom CSS':"
    echo -e "    occ app:install theming_customcss  →  design/themes/inject.css einfuegen${N}"
}

theme_librechat() {
    running librechat || { skip "librechat laeuft nicht"; return; }
    echo -e "  ${DIM}– librechat — LibreChat baut sein CSS beim Image-Build; ein"
    echo -e "    Laufzeit-Override ist ohne eigenes Image nicht vorgesehen."
    echo -e "    Weg: Reverse-Proxy mit sub_filter, oder Fork mit inject.css.${N}"
}

status() {
    echo -e "${G}╔═ THEME-STATUS ════════════════════════════════════${N}"
    local c
    if running gitea; then
        c="$(cid gitea)"
        docker exec "$c" test -f /data/gitea/public/assets/css/theme-oat-matrix.css 2>/dev/null \
            && ok "gitea      theme-oat-matrix.css vorhanden" || skip "gitea      nicht gethemt"
    else skip "gitea      offline"; fi
    if running opencloud; then
        c="$(cid opencloud)"
        docker exec "$c" test -f /var/lib/opencloud/web/assets/themes/opencloud/theme.json 2>/dev/null \
            && ok "opencloud  theme.json gemountet" || skip "opencloud  nicht gethemt"
    else skip "opencloud  offline"; fi
    running nextcloud && ok "nextcloud  laeuft (occ-Status: occ theming:config)" || skip "nextcloud  offline"
}

[ -f "$CSS" ] || { echo -e "${R}[THEME] themes/inject.css fehlt${N}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${R}[THEME] docker fehlt${N}"; exit 127; }

case "${1:-all}" in
    --status|status) status;;
    gitea)     theme_gitea;;
    opencloud) theme_opencloud;;
    nextcloud) theme_nextcloud;;
    librechat) theme_librechat;;
    all)
        echo -e "${G}╔═ OPEN AI TERMINAL // THEME ANWENDEN ══════════════${N}"
        theme_gitea; theme_opencloud; theme_nextcloud; theme_librechat
        echo -e "${DIM}  Eigene Seiten: <link rel=\"stylesheet\" href=\"design/dist/oat-cloud.css\">${N}"
        ;;
    *) sed -n '5,9p' "$0";;
esac
