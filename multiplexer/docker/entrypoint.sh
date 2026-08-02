#!/usr/bin/env bash
# COSMO_V2 Multiplexer — Docker Entrypoint
# Startet ein Profil, oder faellt auf eine Shell zurueck.
set -uo pipefail
PROFILE="${1:-desktop}"

case "$PROFILE" in
    desktop|vps|agent|builder|monitor)
        exec cosmo "$PROFILE"
        ;;
    shell|bash)
        exec bash
        ;;
    *)
        # Beliebiger Befehl im Container
        exec "$@"
        ;;
esac
