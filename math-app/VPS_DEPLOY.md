# VPS Deployment Guide

A step-by-step guide to deploy the math learning app to a VPS and connect your domain.

There are **two deployment paths**:

- **Dedicated VPS** (Steps 1–5 below) — Traefik handles all traffic on ports 80/443. Best for a fresh or dedicated server.
- **Existing reverse proxy** (see **Option A** at the bottom) — use when Nginx/Apache/Caddy/another Traefik already occupies port 80/443. Your existing proxy routes to the math-app containers on loopback ports.

Choose **Option A** if you already have another website or reverse proxy running.

## Prerequisites

- A VPS with Ubuntu 22.04/24.04 (2 vCPU, 4GB RAM minimum)
- A registered domain (e.g. `sumfun.app`)
- SSH access to your VPS

---

## Step 1: VPS Setup

### 1.1 Create VPS

Recommended providers: **Hetzner**, **DigitalOcean**, **Linode**, or **AWS Lightsail**.

Minimum specs: 2 vCPU, 4GB RAM, 40GB SSD.

### 1.2 Initial Server Setup

```bash
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Install essentials
apt install -y curl git ufw fail2ban

# Create deploy user (don't run Docker as root)
adduser deploy
usermod -aG sudo deploy

# Copy SSH key to deploy user
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
```

### 1.3 Install Docker & Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add deploy user to docker group
usermod -aG docker deploy

# Install Docker Compose plugin
apt install -y docker-compose-plugin

# Verify
docker --version
docker compose version
```

### 1.4 Configure Firewall

```bash
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp

# HTTP / HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw enable
```

---

## Step 2: Domain Configuration

### 2.1 Point Domain to VPS

In your domain registrar (or DNS provider), create these **A records**:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | `@` | YOUR_VPS_IP | 300 |
| A | `www` | YOUR_VPS_IP | 300 |
| A | `api` | YOUR_VPS_IP | 300 |

Wait 5-10 minutes for DNS propagation. Verify:

```bash
dig +short yourdomain.com
```

### 2.2 Should You Use Cloudflare?

**Yes, highly recommended.** Cloudflare provides:

- **Free SSL/TLS** (flexible or full)
- **DDoS protection**
- **CDN caching** (faster global load times)
- **DNS management** with fast propagation

To use Cloudflare:

1. Sign up at [cloudflare.com](https://cloudflare.com)
2. Add your domain
3. Change nameservers at your registrar to Cloudflare's
4. In Cloudflare DNS, add the A records above (pointing to your VPS IP)
5. Set SSL/TLS mode to **"Full (strict)"** once you have certificates on the VPS

> ⚠️ **Important**: If using Cloudflare with "Full (strict)" mode, you MUST have valid SSL certificates on your VPS (Traefik will handle this automatically with Let's Encrypt).

---

## Step 3: Prepare Production Configuration

### 3.1 Create Production Environment File

On your **local machine**, create a production `.env.prod`:

```bash
# .env.prod - NEVER commit this file
cat > .env.prod << 'EOF'
# === REQUIRED: Strong JWT Secret ===
# Generate: openssl rand -base64 32
JWT_SECRET=REPLACE_THIS_WITH_A_STRONG_256_BIT_KEY

# === Google OAuth ===
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com

# === MinIO (S3-compatible storage) ===
MINIO_ACCESS_KEY=strong_random_access_key
MINIO_SECRET_KEY=strong_random_secret_key

# === Optional: Anthropic (AI question generation) ===
ANTHROPIC_API_KEY=sk-ant-api03-...
EOF
```

### 3.2 Update docker-compose.yml for Production

Replace `docker-compose.yml` Traefik and routing configuration for production:

```yaml
services:
  traefik:
    image: traefik:latest
    ports:
      - "80:80"
      - "443:443"
      # - "8083:8080"  # Dashboard (disable in production or protect it)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt
    command:
      - "--api.insecure=false"              # Disable dashboard
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=your-email@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      # Redirect HTTP to HTTPS
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
    restart: unless-stopped

  flutter-web:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID}
    labels:
      - "traefik.enable=true"
      # Main domain
      - "traefik.http.routers.flutter-web.rule=Host(`yourdomain.com`) || Host(`www.yourdomain.com`)"
      - "traefik.http.routers.flutter-web.entrypoints=websecure"
      - "traefik.http.routers.flutter-web.tls.certresolver=letsencrypt"
      - "traefik.http.routers.flutter-web.tls=true"
      # COOP header for Google Sign-In
      - "traefik.http.middlewares.flutter-coop.headers.customResponseHeaders.Cross-Origin-Opener-Policy=unsafe-none"
      - "traefik.http.routers.flutter-web.middlewares=flutter-coop"
    restart: unless-stopped

  auth-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: auth
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://auth_user:auth_pass@auth-db:5432/auth_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.auth.rule=Host(`yourdomain.com`) && PathPrefix(`/api/auth`)"
      - "traefik.http.routers.auth.entrypoints=websecure"
      - "traefik.http.routers.auth.tls.certresolver=letsencrypt"
    restart: unless-stopped

  content-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: content
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://content_user:content_pass@content-db:5432/content_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.content.rule=Host(`yourdomain.com`) && PathPrefix(`/api/content`)"
      - "traefik.http.routers.content.entrypoints=websecure"
      - "traefik.http.routers.content.tls.certresolver=letsencrypt"
    restart: unless-stopped

  progress-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: progress
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://progress_user:progress_pass@progress-db:5432/progress_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.progress.rule=Host(`yourdomain.com`) && PathPrefix(`/api/progress`)"
      - "traefik.http.routers.progress.entrypoints=websecure"
      - "traefik.http.routers.progress.tls.certresolver=letsencrypt"
    restart: unless-stopped

  user-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: user
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://user_user:user_pass@user-db:5432/user_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.user.rule=Host(`yourdomain.com`) && PathPrefix(`/api/users`)"
      - "traefik.http.routers.user.entrypoints=websecure"
      - "traefik.http.routers.user.tls.certresolver=letsencrypt"
    restart: unless-stopped

  notification-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: notification
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://postgres:postgres@notification-db:5432/notification_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.notification.rule=Host(`yourdomain.com`) && PathPrefix(`/api/notifications`)"
      - "traefik.http.routers.notification.entrypoints=websecure"
      - "traefik.http.routers.notification.tls.certresolver=letsencrypt"
    restart: unless-stopped

  media-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: media
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://postgres:postgres@media-db:5432/media_db
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.media.rule=Host(`yourdomain.com`) && PathPrefix(`/api/media`)"
      - "traefik.http.routers.media.entrypoints=websecure"
      - "traefik.http.routers.media.tls.certresolver=letsencrypt"
    restart: unless-stopped

  question-bank-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: question_bank
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://qb_user:qb_pass@qb-db:5432/qb_db
      - REDIS_URL=redis://redis:6379
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - JWT_SECRET=${JWT_SECRET}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.question-bank.rule=Host(`yourdomain.com`) && PathPrefix(`/api/questions`)"
      - "traefik.http.routers.question-bank.entrypoints=websecure"
      - "traefik.http.routers.question-bank.tls.certresolver=letsencrypt"
    restart: unless-stopped

  # Databases (same as dev, but with persistent volumes)
  auth-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: auth_user
      POSTGRES_PASSWORD: auth_pass
    volumes:
      - auth_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  user-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: user_db
      POSTGRES_USER: user_user
      POSTGRES_PASSWORD: user_pass
    volumes:
      - user_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  content-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: content_db
      POSTGRES_USER: content_user
      POSTGRES_PASSWORD: content_pass
    volumes:
      - content_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  progress-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: progress_db
      POSTGRES_USER: progress_user
      POSTGRES_PASSWORD: progress_pass
    volumes:
      - progress_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  notification-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: notification_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - notification_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  media-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: media_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - media_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  qb-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: qb_db
      POSTGRES_USER: qb_user
      POSTGRES_PASSWORD: qb_pass
    volumes:
      - qb_db_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  minio:
    image: minio/minio:latest
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    ports:
      - "9002:9000"
      - "9003:9001"
    restart: unless-stopped

volumes:
  auth_db_data:
  user_db_data:
  content_db_data:
  progress_db_data:
  notification_db_data:
  media_db_data:
  qb_db_data:
  minio_data:
```

> Replace `yourdomain.com` and `your-email@example.com` with your actual values.

---

## Step 4: Deploy to VPS

### 4.1 Copy Code to VPS

Option A: Git clone (recommended)

```bash
# On VPS as deploy user
ssh deploy@YOUR_VPS_IP

cd ~
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git math-app
cd math-app/math-app
```

Option B: SCP / rsync from local

```bash
# On local machine
rsync -avz --exclude='node_modules' --exclude='target' \
  --exclude='.git' --exclude='flutter_sdk' \
  ./math-app deploy@YOUR_VPS_IP:~/
```

### 4.2 Configure Environment

```bash
# On VPS
cd ~/math-app/math-app

# Create production env file
nano .env
```

Paste your production values:

```env
JWT_SECRET=your-very-strong-secret-here-min-32-chars
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
MINIO_ACCESS_KEY=strong_random_key
MINIO_SECRET_KEY=strong_random_secret
ANTHROPIC_API_KEY=sk-ant-api03-...
```

### 4.3 Build and Start

```bash
# Start all services
docker compose -f docker-compose.yml up --build -d

# Wait for DBs to be ready (30-60 seconds)
sleep 30

# Check health
curl -s https://yourdomain.com/api/auth/health
curl -s https://yourdomain.com/api/content/health
```

### 4.4 Verify SSL Certificate

Traefik automatically requests Let's Encrypt certificates. Check:

```bash
# Check certificate
curl -vI https://yourdomain.com 2>&1 | grep "subject:"

# Should show: subject: CN=yourdomain.com
```

If certificates aren't working, check Traefik logs:

```bash
docker logs math-app-traefik-1
```

---

## Step 5: Post-Deployment Tasks

### 5.1 Update Google OAuth Allowed Origins

In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. Edit your OAuth 2.0 Web Client ID
2. Add to **Authorized JavaScript origins**:
   - `https://yourdomain.com`
   - `https://www.yourdomain.com`
3. Add to **Authorized redirect URIs**:
   - `https://yourdomain.com`

### 5.2 Set Up Automatic Backups (Optional)

```bash
# Backup script for PostgreSQL databases
cat > /home/deploy/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/deploy/backups"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)

docker exec math-app-auth-db-1 pg_dump -U auth_user auth_db > $BACKUP_DIR/auth_$DATE.sql
docker exec math-app-user-db-1 pg_dump -U user_user user_db > $BACKUP_DIR/user_$DATE.sql
docker exec math-app-progress-db-1 pg_dump -U progress_user progress_db > $BACKUP_DIR/progress_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
EOF

chmod +x /home/deploy/backup.sh

# Add to crontab (daily at 3 AM)
crontab -l | { cat; echo "0 3 * * * /home/deploy/backup.sh >> /home/deploy/backup.log 2>&1"; } | crontab -
```

### 5.3 Enable Auto-Restart

Docker Compose services already have `restart: unless-stopped`. For full resilience:

```bash
# Enable Docker service auto-start on boot
sudo systemctl enable docker
```

---

## Step 6: Update & Redeploy Workflow

When you push code changes:

```bash
# On VPS
ssh deploy@YOUR_VPS_IP
cd ~/math-app/math-app

# Pull latest code
git pull origin main

# Rebuild and restart
docker compose down
docker compose up --build -d

# Verify
curl -s https://yourdomain.com/api/auth/health
```

Or create a deploy script:

```bash
cat > /home/deploy/deploy.sh << 'EOF'
#!/bin/bash
cd ~/math-app/math-app
git pull origin main
docker compose down
docker compose up --build -d
echo "Deployed at $(date)"
EOF

chmod +x /home/deploy/deploy.sh
```

---

## Cloudflare + VPS Architecture (Recommended)

```
User → Cloudflare (DNS + SSL + CDN) → VPS (Traefik + Docker)
```

**Why this setup:**

| Layer | Benefit |
|-------|---------|
| Cloudflare | Hides your VPS IP, DDoS protection, CDN caching, free SSL |
| Traefik | Automatic Let's Encrypt certs, reverse proxy, HTTP→HTTPS redirect |
| Docker | Container isolation, easy updates, reproducible builds |

**Cloudflare settings:**

1. **SSL/TLS** → Overview → Set to **"Full (strict)"**
2. **SSL/TLS** → Edge Certificates → Enable **"Always Use HTTPS"**
3. **Speed** → Optimization → Enable **Auto Minify** (JS, CSS, HTML)
4. **Caching** → Configuration → Set **Browser Cache TTL** to 4 hours for static assets
5. **DNS** → Records: ensure A records point to VPS IP with **DNS-only** (grey cloud) or **Proxied** (orange cloud). Use **Proxied** for Cloudflare benefits.

---

## Troubleshooting

### Issue: `curl: (6) Could not resolve host`

- DNS hasn't propagated yet. Wait 5-30 minutes.
- Check with `dig yourdomain.com` from local machine.

### Issue: SSL certificate not working

```bash
# Check Traefik logs
docker logs math-app-traefik-1 | grep -i "certificate\|acme\|error"

# Ensure port 443 is open
sudo ufw status

# Verify A record points to VPS
dig +short yourdomain.com
```

### Issue: Services returning 401

- Ensure `JWT_SECRET` is set identically across all services in `.env`
- Ensure `JWT_SECRET` is passed to all containers in `docker-compose.yml`

### Issue: Google Sign-In not working on production

- Verify `GOOGLE_CLIENT_ID` in `.env` matches Google Console
- Add `https://yourdomain.com` to Authorized JavaScript Origins
- Check COOP header is `unsafe-none` (already configured in Traefik labels)

---

## Security Checklist

- [ ] `.env` file is in `.gitignore` and NOT committed
- [ ] `JWT_SECRET` is strong (32+ random characters)
- [ ] Firewall blocks all ports except 22, 80, 443
- [ ] SSH key authentication only (no password login)
- [ ] `fail2ban` installed and running
- [ ] Cloudflare proxied (orange cloud) to hide VPS IP
- [ ] MinIO console (`:9003`) not exposed publicly, or protected with strong credentials
- [ ] Traefik dashboard disabled or IP-restricted in production

---

## Cost Estimate

| Provider | VPS (2vCPU/4GB) | Domain | Cloudflare | Monthly Total |
|----------|----------------|--------|------------|---------------|
| Hetzner | ~€5 | ~$10-15/year | Free | ~$6/month |
| DigitalOcean | $24 | ~$10-15/year | Free | ~$25/month |
| AWS Lightsail | $12 | ~$10-15/year | Free | ~$13/month |

---

## Next Steps After Deployment

1. **Smoke test**: Visit `https://yourdomain.com` — login screen should appear
2. **Auth test**: Click "Guest Login" → should proceed to welcome screen
3. **API test**: `curl https://yourdomain.com/api/content/curriculum`
4. **SSL verify**: Check padlock icon in browser
5. **E2E test**: Update `BASE` in `e2e/tests/*.spec.ts` to `https://yourdomain.com` and run `make e2e-test`

---

## Files to Update Before First Deploy

| File | Changes |
|------|---------|
| `docker-compose.yml` | Replace `localhost` with your domain, add TLS/SSL labels |
| `.env` (on VPS) | Set strong `JWT_SECRET`, production `GOOGLE_CLIENT_ID` |
| `frontend/web/index.html` | Update any hardcoded `localhost:8082` references |
| `frontend/lib/core/constants.dart` | Update `baseUrl` from `localhost:8082` to `yourdomain.com` |

> ⚠️ **Critical**: Never commit real `.env` with secrets to Git. Use `.env.example` for templates.

---

## Option A: Deploying Alongside an Existing Reverse Proxy

If your VPS already runs Nginx, Apache, Caddy, or another service on ports 80/443, **do not use** `docker-compose.prod.yml` (it includes its own Traefik that will conflict). Use this alternative instead.

### Architecture

```
User → Nginx (existing, SSL termination) → Docker containers (loopback ports only)
```

### Files for Option A

| File | Purpose |
|------|---------|
| `docker-compose.prod.existing-proxy.yml` | No Traefik; all services bind to `127.0.0.1:PORT` |
| `nginx-sample-existing-proxy.conf` | Nginx upstream + location blocks for all services |

### Step A1: Start the app containers

On your VPS:

```bash
cd ~/math-app/math-app

# Start containers (no Traefik — existing proxy handles routing)
docker compose -f docker-compose.prod.existing-proxy.yml up --build -d
```

Containers bind **only to loopback** (`127.0.0.1`), not to public interfaces:

| Service | Port (host loopback) |
|---------|----------------------|
| Flutter web (`/`) | `8082` |
| Auth (`/api/auth`) | `3001` |
| Users (`/api/users`) | `3002` |
| Content (`/api/content`) | `3003` |
| Progress (`/api/progress`) | `3004` |
| Notifications (`/api/notifications`) | `3005` |
| Media (`/api/media`) | `3006` |
| Question Bank (`/api/questions`) | `3007` |

### Step A2: Configure your existing Nginx

Edit `nginx-sample-existing-proxy.conf`:
1. Replace `yourdomain.com` with your actual domain
2. Update `ssl_certificate` and `ssl_certificate_key` paths to your existing cert locations
3. Place the file in `/etc/nginx/sites-available/math-app`
4. Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/math-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Why this works

- **`127.0.0.1:8082:80`** — The container's port 80 is only reachable from the host itself. No external access.
- **Nginx handles SSL** — If you already use Let’s Encrypt or Cloudflare, you don't need a second certificate manager.
- **No port conflicts** — Nothing in this compose binds to `0.0.0.0:80` or `:443`.

### If you use Apache or Caddy

The same pattern applies: point your existing proxy to the loopback ports listed above. The compose file stays the same; only the frontend proxy config differs.

---

**Done!** Your math learning app should now be live at `https://yourdomain.com`.
