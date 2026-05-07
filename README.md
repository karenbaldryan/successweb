# successweb

Static marketing site for the **Success** iOS app, served at [scss.app](https://scss.app).

The container ships the site behind a small nginx that handles the `/get` redirect, friendly URL aliases, and a health check. Your existing nginx on the host terminates TLS and reverse-proxies to it.

## What's here

- `site/` — static site (`index.html`, `privacy.html`, `terms.html`, CSS, favicon, sitemap)
- `nginx.conf` — redirects + headers + health check
- `Dockerfile` — `nginx:1.27-alpine` serving `site/`
- `docker-compose.yml` — drop-in compose file for the server
- `.github/workflows/build-and-push.yml` — builds multi-arch image and pushes to GHCR

## Routes

| Path | Behavior |
| --- | --- |
| `/` | Landing page |
| `/privacy.html` (or `/privacy`) | Privacy Policy |
| `/terms.html` (or `/terms`) | Terms of Use |
| `/get` | `302` redirect to `https://apps.apple.com/app/id6767120480` |
| `/healthz` | Health check, returns `ok` |

The `/get` URL is what should be embedded in any image shared from the iOS app.

## Local development

```bash
docker build -t successweb .
docker run --rm -p 8080:80 successweb
# open http://localhost:8080
```

## Deployment on the server

1. If the GHCR package is private, log in once on the server: `echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin`.
2. Run:

```bash
docker compose pull
docker compose up -d
```

The container listens on `:80` inside the container and is published on host port `8080` by default. Point your existing nginx at it — minimal example:

```nginx
server {
    listen 443 ssl http2;
    server_name scss.app;

    # ssl_certificate / ssl_certificate_key handled by your existing setup

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name scss.app;
    return 301 https://$host$request_uri;
}
```

## CI / CD

The GitHub Actions workflow (`.github/workflows/build-and-push.yml`) builds a multi-arch image (`linux/amd64`, `linux/arm64`) and pushes it to GitHub Container Registry on every push to `main` and on every tag matching `v*.*.*`. It tags `latest` for the default branch, plus semver and short-SHA tags. No extra secrets are required — it uses the built-in `GITHUB_TOKEN`.

To pull the image on your server, ensure the package's visibility is set appropriately under `Packages` in your GitHub repo settings.
