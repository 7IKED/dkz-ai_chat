# ╔══════════════════════════════════════════════════════════════════╗
# ║  COSMO_V2 // MULTIPLEXER  ·  Docker Image                           ║
# ║  Zellij + Tools + Cosmo Config, sofort startklar.                  ║
# ╚══════════════════════════════════════════════════════════════════╝
FROM debian:stable-slim

ARG ZELLIJ_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive \
    COSMO_MUX_DIR=/opt/cosmo \
    TERM=xterm-256color \
    EDITOR=nano

# Basis-Tools + Multiplexer-Umfeld (Monitor/Netz/SSH/Git) + Zsh-Setup-Tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl tar bash git openssh-client \
        htop procps iproute2 nano less watch \
        zsh fzf zoxide bat ripgrep \
    && (apt-get install -y --no-install-recommends eza || true) \
    && rm -rf /var/lib/apt/lists/*

# Zellij statisches Binary holen (arch-aware)
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  target=x86_64-unknown-linux-musl ;; \
      aarch64) target=aarch64-unknown-linux-musl ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    url="https://github.com/zellij-org/zellij/releases/${ZELLIJ_VERSION}/download/zellij-${target}.tar.gz"; \
    if [ "$ZELLIJ_VERSION" = "latest" ]; then \
      url="https://github.com/zellij-org/zellij/releases/latest/download/zellij-${target}.tar.gz"; fi; \
    curl -fsSL "$url" | tar -xz -C /usr/local/bin; \
    chmod +x /usr/local/bin/zellij; zellij --version

# Cosmo Multiplexer einspielen
COPY . /opt/cosmo
RUN set -eux; \
    mkdir -p /root/.config/zellij/layouts; \
    ln -sf /opt/cosmo/config/config.kdl /root/.config/zellij/config.kdl; \
    for l in /opt/cosmo/layouts/*.kdl; do ln -sf "$l" "/root/.config/zellij/layouts/$(basename "$l")"; done; \
    chmod +x /opt/cosmo/bin/cosmo /opt/cosmo/scripts/*.sh /opt/cosmo/shell/install-shell.sh /opt/cosmo/docker/entrypoint.sh; \
    ln -sf /opt/cosmo/bin/cosmo /usr/local/bin/cosmo; \
    # Perfect Zsh Setup aktivieren (Pakete sind schon installiert)
    ln -sf /opt/cosmo/shell/zshrc /root/.zshrc

# Zellij startet Panes mit $SHELL → Zsh als Standard im Container
ENV SHELL=/usr/bin/zsh

WORKDIR /work
ENTRYPOINT ["/opt/cosmo/docker/entrypoint.sh"]
# Standard-Profil (override: docker run ... cosmo-image agent)
CMD ["desktop"]
