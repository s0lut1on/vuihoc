# Math Learning App

A math learning platform for Vietnamese kids ages 5-7, built with **Flutter** (frontend) and **Rust microservices** (backend).

## Quick Start

The application code lives in [`math-app/`](math-app/):

```bash
cd math-app
make setup    # Install dependencies
make deploy   # Full CI pipeline (format, lint, test, build, e2e)
```

See [`math-app/README.md`](docs/math-app/README.md) for detailed setup, architecture, and API docs.

## Manual Deploy to VPS

GitHub Actions is the default deploy path, but if the workflow fails
silently (VPS keeps serving an old bundle even though pushes land on
`main`) use these scripts instead. Both bypass GHCR and build everything
locally on the VPS from source.

### One-shot: paste from your laptop

The simplest path — runs `git push` + SSHes into the VPS + builds +
restarts, all in one go. Defaults to `s0lut1on@sekklings.com`.

```bash
cd math
VPS_HOST=s0lut1on@sekklings.com \
  bash math-app/scripts/deploy-vps-one-shot.sh
```

Override `VPS_HOST` if your VPS is elsewhere. The script auto-detects
your local commit SHA and passes it as `APP_VERSION` so the Flutter
home screen footer (`🐸 HocVui <sha>`) reflects the deployed build.

### Faster deploy (push prebuilt bundle, no Docker build on VPS)

For hotfixes when you don't want to rebuild the Flutter container on
the VPS (saves 5-10 min), use the rsync-based script. It builds
`build/web` locally and rsyncs it directly into the running nginx
container.

```bash
GOOGLE_CLIENT_ID=<your-google-oauth-web-client-id> \
VPS_HOST=s0lut1on@sekklings.com \
VPS_SSH_KEY=~/.ssh/id_ed25519_vps \
  bash math-app/scripts/deploy.sh
```

Flags: `--service NAME` (rebuild only one backend service),
`--skip-frontend` (backend only), `--skip-backend` (frontend only),
`--no-cache` (force rebuild from scratch).

### Setting up a brand-new VPS

For a fresh VPS that has nothing installed, run the bootstrap script
once to install Docker, clone the repo, generate `.env` with random
passwords, and schedule a daily auto-deploy cron.

**The repo is private**, so you need to set up SSH key auth FIRST
(GitHub won't clone a private repo over HTTPS without a Personal
Access Token):

```bash
# On your laptop (one-time):
ssh-keygen -t ed25519 -f ~/.ssh/math_app_deploy -C "vps-deploy"
ssh-copy-id -i ~/.ssh/math_app_deploy.pub root@YOUR_NEW_VPS

# SSH into VPS:
ssh root@YOUR_NEW_VPS

# Now run the bootstrap (default REPO_URL is git@github.com:...):
bash scripts/vps-bootstrap.sh
# Or pull from a raw URL after pushing your SSH key to the VPS:
#   curl -sSL https://raw.githubusercontent.com/s0lut1on/vuihoc/main/math-app/scripts/vps-bootstrap.sh | bash

# Then start the stack:
cd /root/math-app/math-app
bash scripts/deploy-local.sh

# Enable firewall once the stack is up:
ufw enable
```

The bootstrap script defaults to `REPO_URL=git@github.com:s0lut1on/vuihoc.git`
(SSH — assumes the deploying user's key is in `/root/.ssh/`). Override
with `REPO_URL=https://<PAT>@github.com/...` for HTTPS if you'd rather
embed a Personal Access Token.

The script is idempotent — safe to re-run. It generates a fresh `.env`
only on the first run; subsequent runs skip the generation and just
refresh the cron + apt packages.

### Or: run on the VPS directly

```bash
ssh USER@HOST
cd /root/math-app/math-app   # (or wherever you cloned it — override with VPS_DIR=/your/path)
git pull
./scripts/deploy-local.sh
```

`deploy-local.sh` supports skip flags for faster iteration:

| Env var | Effect |
|---|---|
| `SKIP_PULL=1` | skip `git pull` (you've already done it) |
| `SKIP_BUILD=1` | skip `docker compose build` (only restart containers) |
| `SKIP_HEALTH_CHECK=1` | skip post-deploy health probe |
| `APP_VERSION=<sha>` | override version stamp (default: `git rev-parse --short HEAD`) |
| `VPS_DIR=<path>` | override remote project dir (default: `/root/math-app/math-app`) |

### Make target

If you prefer Make:

```bash
export VPS_HOST=s0lut1on@sekklings.com
export VPS_SSH_KEY=~/.ssh/id_ed25519_vps
make deploy-vps
```

This `scp`s the script to the VPS and SSH-executes it.

### Verifying a successful deploy

Open `https://<your-domain>`, sign in, scroll to the bottom of the
home screen — the footer should read:

    🐸 HocVui <7-char-git-sha>

Compare against `git log --oneline | head -1` locally to confirm the
deployed bundle matches `main`. If the footer shows an older SHA,
hard-refresh the browser (`Cmd-Shift-R`) to clear the Cloudflare edge
cache.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| Footer says `HocVui dev` | Local dev build — `APP_VERSION` wasn't passed |
| Footer shows old SHA after `make deploy-vps` | Cloudflare cache — hard refresh browser |
| GitHub Actions workflow doesn't run on push | Workflow trigger broken — use the manual scripts above |
| VPS out of disk | `docker system prune -af` then re-run |


After deploy, `scripts/health-check.sh` runs automatically against all
backend services.

## Project Layout

```
.
├── math-app/           # Main application (Flutter + Rust)
│   ├── frontend/       # Flutter app (screens, widgets, tests)
│   ├── backend/        # Rust microservices (auth, content, progress, …)
│   ├── e2e/            # Playwright E2E tests
│   ├── Makefile        # Dev commands
│   └── README.md       # Detailed docs
│
├── design-exports/     # Exported design assets
├── web-design.pen      # Pencil design file (web UI)
├── web-design-preview.html
├── docs/
│   ├── persona-journeys.md # User persona research
│   ├── plan.md             # Development plan (Vietnamese)
│   ├── wireframes.md       # Wireframe documentation
│   └── question_bank_rust_guide.md  # Rust question-bank implementation guide
```

## Key Features

- **Persona-based Onboarding** — 4 learning personas adapt tone and encouragement
- **1,700+ Lessons** across Numbers, Geometry, Measurement, Logic
- **Dynamic Progression** — Lessons unlock sequentially; retry on wrong answers
- **Bilingual** — Vietnamese + English with toggle on every screen
- **Adaptive Questions** — Parametric generation + Bayesian Knowledge Tracing (BKT)
- **Time-Telling Visuals** — `ClockFace` CustomPaint widget renders analog clocks for `clock\|h\|m` exercises
- **Parent Dashboard** — PIN-gated progress overview
- **Google Sign-In + Guest Login** — Multiple auth methods with reactive token state and route guards
- **Profile Widget** — Avatar dropdown with settings/logout in desktop nav
- **Free / Premium Tiers** — Flag-based subscription: free users limited to **50 lessons per day**; premium unlimited. Admin flips `subscription_tier` in DB
- **Token Validation on Resume** — `silentSignIn()` validates cached JWT on app startup; clears stale tokens automatically
- **Build Version Footer** — home screen shows `🐸 HocVui <git-sha>` so you can verify which build is actually deployed

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart), Riverpod, GoRouter, Hive |
| Backend | Axum (Rust), SQLx, utoipa (OpenAPI) |
| Databases | PostgreSQL (per service), Redis |
| Storage | MinIO |
| Proxy | Traefik |
| Testing | Flutter tests (146), Rust tests (159), Playwright E2E (15+) |

## License

MIT
