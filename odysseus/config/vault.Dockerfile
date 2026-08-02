# ODYSSEUS // VAULT — KeePassXC-CLI Container (GPL, frei)
# Haelt die .kdbx-Datenbank fuer Agenten-Zugangsdaten & API-Keys.
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        keepassxc \
    && rm -rf /var/lib/apt/lists/*
VOLUME /vault
WORKDIR /vault
