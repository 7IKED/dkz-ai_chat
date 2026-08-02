#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  OPEN AI TERMINAL // CLOUD DESIGN SYSTEM — BUILD                   ║
# ║  tokens.json  →  CSS-Bundle · Shell-Farben · Zellij-Theme          ║
# ║  Ein Token-Satz, drei Ziele. Kein npm, keine Abhaengigkeiten.      ║
# ╚══════════════════════════════════════════════════════════════════╝
#  build.sh          alles bauen nach dist/
#  build.sh --check  nur pruefen (CI): JSON valide, Tokens vollstaendig
set -euo pipefail
DESIGN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$DESIGN/dist"
G='\033[38;5;46m'; DIM='\033[38;5;28m'; R='\033[38;5;196m'; Y='\033[38;5;214m'; N='\033[0m'
say()  { echo -e "${G}[DESIGN]${N} $*"; }
warn() { echo -e "${Y}[DESIGN]${N} $*"; }
die()  { echo -e "${R}[DESIGN] $*${N}" >&2; exit 1; }

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

command -v python3 >/dev/null 2>&1 || die "python3 fehlt (nur fuer JSON-Parsing noetig)"

# ── 1) tokens.json validieren ────────────────────────────────────────
say "pruefe tokens.json ..."
python3 - "$DESIGN/tokens.json" <<'PY' || die "tokens.json ist ungueltig"
import json, sys
d = json.load(open(sys.argv[1]))
need = ["color", "typography", "space", "radius", "shadow", "motion", "layout"]
missing = [k for k in need if k not in d]
if missing:
    print("fehlende Gruppen: " + ", ".join(missing)); sys.exit(1)
n = 0
def walk(o):
    global n
    if isinstance(o, dict):
        if "value" in o and isinstance(o["value"], str): n += 1
        else:
            for v in o.values(): walk(v)
walk(d)
print(f"  {n} Tokens, {len(d['color'])} Farbgruppen — ok")
PY

# ── 2) CSS-Variablen gegen tokens.json abgleichen ────────────────────
say "gleiche css/tokens.css mit tokens.json ab ..."
python3 - "$DESIGN/tokens.json" "$DESIGN/css/tokens.css" <<'PY' || die "Farbwerte weichen ab"
import json, re, sys
tok = json.load(open(sys.argv[1]))
css = open(sys.argv[2]).read()
declared = dict(re.findall(r'(--oat-[\w-]+)\s*:\s*([^;]+);', css))
hexes = {v.strip().lower() for v in declared.values() if v.strip().startswith('#')}
missing = []
for group in tok["color"].values():
    for name, spec in group.items():
        val = spec["value"].lower()
        if val.startswith('#') and val not in hexes:
            missing.append(f"{name}={val}")
if missing:
    print("  in css/tokens.css nicht gefunden: " + ", ".join(missing)); sys.exit(1)
print(f"  {len(declared)} CSS-Variablen, alle Farbwerte aus tokens.json vorhanden — ok")
PY

if [ "$CHECK_ONLY" = "1" ]; then say "Check bestanden."; exit 0; fi

mkdir -p "$DIST"

# ── 3) CSS-Bundle ────────────────────────────────────────────────────
say "baue dist/oat-cloud.css ..."
{
  echo "/* OPEN AI TERMINAL // Cloud Design System — gebaut von design/build.sh."
  echo "   NICHT von Hand aendern: css/tokens.css · css/base.css · css/components.css */"
  for f in tokens base components; do
    echo; echo "/* ═══ $f.css ═══════════════════════════════════════════ */"
    cat "$DESIGN/css/$f.css"
  done
} > "$DIST/oat-cloud.css"

# ── 4) Shell-Farben (ANSI 256) ───────────────────────────────────────
say "baue dist/oat-tokens.sh ..."
python3 - "$DESIGN/tokens.json" > "$DIST/oat-tokens.sh" <<'PY'
import json, sys
tok = json.load(open(sys.argv[1]))
print("#!/usr/bin/env bash")
print("# OPEN AI TERMINAL — Terminalfarben aus design/tokens.json (gebaut).")
print("# Einbinden:  . \"$ODYSSEUS_DIR/design/dist/oat-tokens.sh\"")
print("OAT_RESET=$'\\033[0m'")
for gname, group in tok["color"].items():
    print(f"# -- {gname}")
    for name, spec in group.items():
        ansi = spec.get("ansi")
        var = f"OAT_{gname.upper()}_{name.upper().replace('-','_')}"
        if ansi is not None:
            print(f"{var}=$'\\033[38;5;{ansi}m'")
        print(f"{var}_HEX='{spec['value']}'")
PY
chmod +x "$DIST/oat-tokens.sh"

# ── 5) Zellij-Theme ──────────────────────────────────────────────────
say "baue dist/oat-matrix.kdl (Zellij-Theme) ..."
python3 - "$DESIGN/tokens.json" > "$DIST/oat-matrix.kdl" <<'PY'
import json, sys
t = json.load(open(sys.argv[1]))["color"]
fg, bg, st, bd = t["fg"], t["bg"], t["state"], t["border"]
v = lambda g, k: g[k]["value"]
print("// OPEN AI TERMINAL — Zellij-Theme, gebaut aus design/tokens.json.")
print("// Einbinden: themes { ... } in config/config.kdl  oder  ~/.config/zellij/themes/")
print("themes {")
print("    oat-matrix {")
for key, val in [
    ("fg",       v(fg, "primary")),
    ("bg",       v(bg, "surface")),
    ("black",    v(bg, "base")),
    ("red",      v(st, "error")),
    ("green",    v(fg, "primary")),
    ("yellow",   v(st, "warn")),
    ("blue",     v(fg, "muted")),
    ("magenta",  v(fg, "accent")),
    ("cyan",     v(st, "info")),
    ("white",    v(fg, "neutral")),
    ("orange",   v(st, "warn")),
]:
    print(f'        {key} "{val}"')
print("    }")
print("}")
PY

# ── 6) Bericht ───────────────────────────────────────────────────────
echo
say "fertig — dist/:"
for f in "$DIST"/*; do
    printf "${DIM}  %-22s %6s Bytes${N}\n" "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')"
done
echo -e "${DIM}  Web:      <link rel=\"stylesheet\" href=\"dist/oat-cloud.css\">"
echo -e "  Shell:    . design/dist/oat-tokens.sh"
echo -e "  Zellij:   dist/oat-matrix.kdl → ~/.config/zellij/themes/${N}"
