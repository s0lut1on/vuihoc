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
Access Token, and won't accept a key that doesn't exist on the VPS):

The simplest one-liner flow uses `setup-deploy-key.sh` from your
laptop — it generates the key, pushes it to the VPS, and tests the
result:

```bash
# On your LAPTOP (one-time, takes ~1 minute):
VPS_HOST=root@YOUR_NEW_VPS \
  bash math-app/scripts/setup-deploy-key.sh
# The script will print the pubkey — paste it into
#   https://github.com/settings/keys  (account-level)
#   OR https://github.com/s0lut1on/vuihoc/settings/keys/new  (repo-only)
# Then press ENTER in the script to continue.

# SSH into VPS, run bootstrap, build stack:
ssh root@YOUR_NEW_VPS
bash scripts/vps-bootstrap.sh
cd /root/math-app/math-app && bash scripts/deploy-local.sh
ufw enable
```

If you'd rather do each step manually:

```bash
# On your LAPTOP (one-time):
ssh-keygen -t ed25519 -f ~/.ssh/math_app_deploy -C "vps-deploy"

# Add the PUBKEY to GitHub so it's authorized to read the private repo.
# Easiest: copy pubkey and paste at https://github.com/settings/keys
cat ~/.ssh/math_app_deploy.pub

# Push the PRIVATE key to the VPS so git on the VPS can use it
# (ssh-copy-id only adds to authorized_keys, not the git-side keychain):
scp ~/.ssh/math_app_deploy root@YOUR_NEW_VPS:/root/.ssh/math_app_deploy

# ssh into VPS, lock down perms, and test the key:
ssh root@YOUR_NEW_VPS
chmod 700 ~/.ssh
chmod 600 ~/.ssh/math_app_deploy
ssh -T git@github.com    # should print "Hi <USER>! You've been authenticated."

# Run the bootstrap (default REPO_URL is git@github.com:...):
bash scripts/vps-bootstrap.sh

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

**Common error**: `git@github.com: Permission denied (publickey)` —
usually means step 3 (private key on VPS) was skipped. The pubkey
gets you INTO the VPS via `ssh-copy-id`, but git on the VPS needs the
**private** key at `/root/.ssh/`. Fix: scp the private key + chmod 600.
Easiest path: just re-run `setup-deploy-key.sh` and it does all 6
steps including the verification.

The script is idempotent — safe to re-run. It generates a fresh `.env`
only on the first run; subsequent runs skip the generation and just
refresh the cron + apt packages.

### Locked out after bootstrap? Run vps-unlock from the console

If `vps-bootstrap.sh` left you unable to SSH back in (most common
cause: fail2ban auto-banned your IP after the git clone's failed SSH
handshake, OR ufw activated with wrong rules), you need to recover
from your VPS provider's web console (Hetzner Cloud Console, DO
Droplet Console, AWS Lightsail Terminal, etc — anywhere you can get a
shell without going through SSH).

```bash
# From the VPS console (NOT over SSH):
curl -sSL https://raw.githubusercontent.com/s0lut1on/vuihoc/main/math-app/scripts/vps-unlock.sh | bash
# or if you have the repo cloned:
cd /root/math-app/math-app && bash scripts/vps-unlock.sh
```

`vps-unlock.sh` will:
1. Disable ufw (if accidentally enabled)
2. Unban all fail2ban IPs
3. Verify sshd is running + listening on port 22
4. Regenerate missing host keys
5. Verify `~/.ssh/authorized_keys` has at least one key (most common
   cause of "permission denied" — ssh-copy-id failed silently)
6. Restore a safe `sshd_config` if yours got corrupted
7. Restart sshd safely

Then retry SSH from your laptop.

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
