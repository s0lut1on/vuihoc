# VPS Redeploy — Manual Recovery

If `git push` succeeds but `https://sekklings.com` keeps serving an old
bundle, the GitHub Actions deploy workflow didn't run (or a build job
failed). Trigger a manual redeploy by SSHing into the VPS.

## When to use this

- `git log` on VPS doesn't match `main` on GitHub
- VPS is missing features you just pushed
- The footer `🐸 HocVui <sha>` on the home screen doesn't match the
  latest commit on `github.com/s0lut1on/vuihoc/commits/main`

## Steps

```bash
# 1. SSH into VPS
ssh USER@sekklings.com

# 2. Pull latest
cd ~/math-app/math-app
git pull origin main

# 3. Login to GHCR (only needed once per session)
echo "$GHCR_PAT" | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# 4. Pull the new flutter-web image (build was done by GH Actions)
SHA=$(git rev-parse --short HEAD)
IMAGE_TAG=$SHA docker compose -f docker-compose.ghcr.yml pull flutter-web

# 5. Recreate just the flutter-web container (faster than full stack restart)
IMAGE_TAG=$SHA docker compose -f docker-compose.ghcr.yml \
  up -d --no-deps --force-recreate flutter-web

# 6. Verify
sleep 10
curl -sI https://sekklings.com/main.dart.js | head -5
./scripts/health-check.sh
```

## If pull fails with "manifest unknown"

The `flutter-web:$SHA` image wasn't built. Check GitHub Actions:
`github.com/s0lut1on/vuihoc/actions` → look for the `Deploy to VPS`
workflow on the latest commit. One of these jobs likely failed:
- `build-flutter` (Docker build of Flutter web)
- `build-backend` (Rust services)
- `build-language` (Python FastAPI service)

If `build-language` is failing, check that
`math-app/backend/language/Dockerfile` exists and `requirements.txt` is
up to date. If `build-flutter` is failing, check the Dockerfile ARG
ordering — `APP_VERSION` must be declared before it's referenced.

## Cache-busting

The Dockerfile already appends a build-timestamp query string to
`flutter_bootstrap.js` and `main.dart.js` (`?v=${BUILD_TS}`), which
defeats Cloudflare's 1-year static-asset cache. If you still see old
content, hard-refresh the browser (Cmd-Shift-R) or check that the
container actually restarted with `docker ps` (look at the `CREATED`
column).
