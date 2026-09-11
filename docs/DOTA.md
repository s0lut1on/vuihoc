# Infrastructure Changes — 2026-07-21

## Problem
`dota.sekklings.com` was returning **404** from Cloudflare Tunnel while other domains (`sekklings.com`, `www.sekklings.com`, `router.sekklings.com`) worked fine.

## Root Cause
Cloudflare Tunnel's cloud-managed ingress config was not routing `dota.sekklings.com` correctly. The local `config.yml` changes were being ignored. Attempts to fix the tunnel directly failed because the tunnel is cloud-managed and local config overrides do not take effect.

## Solution
Routed `dota.sekklings.com` through the **same proven path** as `sekklings.com`:

```
User → Cloudflare Tunnel → Traefik:443 → nginx proxy → dota-dashboard:5000
```

### Files Created

1. **`/root/dota-proxy/docker-compose.yml`**
   - Docker container: `dota-proxy` (nginx:1.27-alpine)
   - Network: `math-app_default` (external, shared with Traefik)
   - Traefik labels:
     - `Host(\`dota.sekklings.com\`)`
     - `entrypoints=websecure`
     - `tls.certresolver=letsencrypt`
     - `priority=50`

2. **`/root/dota-proxy/nginx.conf`**
   - Listens on port 80
   - Proxies to `http://172.18.0.1:5000` (host machine where dota-dashboard runs)
   - Preserves Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto headers

### Files Modified

3. **`/etc/cloudflared/config.yml`**
   - Changed `dota.sekklings.com` service from `http://127.0.0.1:5000` → `https://localhost:443`
   - Added `originRequest: {noTLSVerify: true}` (Traefik uses self-signed cert for internal connections)

4. **Cloudflared restart**
   - Restarted `cloudflared.service` to pick up new config

### Files Cleaned Up

5. **`/etc/nginx/sites-enabled/dota.conf`** and **`/etc/nginx/sites-available/dota.conf`**
   - Removed leftover nginx config from earlier debugging attempt
6. **`/etc/systemd/system/traefik-watchdog.service`**
   - Already existed from prior session; no changes made

## Verification

| Domain | Status | Route |
|---|---|---|
| `sekklings.com` | 200 | Cloudflare Tunnel → Traefik:443 → marketing site |
| `www.sekklings.com` | 200 | Cloudflare Tunnel → Traefik:443 → marketing site |
| `dota.sekklings.com` | 200 | Cloudflare Tunnel → Traefik:443 → nginx proxy → dota-dashboard:5000 |
| `router.sekklings.com` | 200 | Cloudflare Tunnel → Caddy:8443 (unchanged) |

## Impact
- **No existing services affected.**
- All domains continue to work.
- `dota.sekklings.com` now shares the same SSL termination and routing layer as `sekklings.com`, which simplifies management.
