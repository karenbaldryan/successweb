FROM caddy:2-alpine

LABEL org.opencontainers.image.title="successweb" \
      org.opencontainers.image.description="Marketing site for the Success iOS app (scss.app)" \
      org.opencontainers.image.source="https://github.com/karenbaldryan/successweb" \
      org.opencontainers.image.licenses="MIT"

COPY Caddyfile /etc/caddy/Caddyfile
COPY site/ /srv/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/healthz || exit 1
