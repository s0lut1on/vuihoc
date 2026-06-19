#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# VPS deploy orchestrator — runs from your laptop, drives the VPS over SSH.
#
# Subcommands:
#   sync     rsync source (incl. Flutter build/web) to VPS
#   build    rebuild Docker images on VPS (uses deploy-local.sh SKIP_PULL=1)
#   up       restart containers on VPS (SKIP_PULL=1 SKIP_BUILD=1)
#   status   show running containers + APP_VERSION on VPS
#   logs     tail logs for a service (or all)
#   shell    open SSH shell on VPS
#   restart  recreate all containers (SKIP_PULL=1 SKIP_BUILD=1)
#   all      sync + build + up + health check (default for `make deploy-vps`)
#
# Config: copy .env.deploy.example to .env.deploy and fill in.
# SSH: uses ssh-agent by default. Set VPS_SSH_KEY in .env.deploy to force a
#      specific key (then ssh runs with -o IdentitiesOnly=yes).
#
# All env vars can also be passed inline: VPS_HOST=... ./deploy-vps.sh status
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Load .env.deploy if present (overridden by inline env vars) ──────
for envfile in "${APP_DIR}/.env.deploy" "${APP_DIR}/.env.deploy.local"; do
  if [[ -f "$envfile" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$envfile"
    set +a
  fi
done

# ─── Defaults ────────────────────────────────────────────────────────
VPS_HOST="${VPS_HOST:-deploy@194.233.94.167}"
VPS_DIR="${VPS_DIR:-~/math-app/math-app}"
VPS_SSH_KEY="${VPS_SSH_KEY:-}"
VPS_PASSWORD="${VPS_PASSWORD:-}"
GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-1026978886898-cpqjll5m4b2ds8h7udb2i0j3ogq1u5um.apps.googleusercontent.com}"
FLUTTER_BIN="${FLUTTER_BIN:-/home/s0lut1on/flutter/bin/flutter}"
APP_VERSION="${APP_VERSION:-$(git -C "$APP_DIR" rev-parse --short HEAD 2>/dev/null || echo local-dev)}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
log()  { echo "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn() { echo "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC}  $*"; }
err()  { echo "${RED}[$(date +'%H:%M:%S')] ERROR${NC} $*" >&2; }
ok()   { echo "${GREEN}[$(date +'%H:%M:%S')] OK${NC}    $*"; }
die()  { err "$*"; exit 1; }

# ─── Auth mode selection ─────────────────────────────────────────────
# Priority: VPS_PASSWORD (sshpass) > VPS_SSH_KEY (forced key) > ssh-agent.
# Set VPS_PASSWORD (or pass --ask-pass / VPS_PASSWORD=foo) to skip key setup.
# BatchMode=yes is incompatible with password auth, so we drop it then.
use_password() { [[ -n "$VPS_PASSWORD" ]]; }
ssh_batch() {
  if use_password; then echo "no"; else echo "yes"; fi
}

# ─── SSH helper ──────────────────────────────────────────────────────
# Wraps ssh/sshpass so callers don't have to think about auth mode.
# Usage: ssh_run "remote command" or ssh_run_tty "remote command"
ssh_run() {
  local -a opts=(-o ConnectTimeout=10 -o ServerAliveInterval=30)
  local batch; batch=$(ssh_batch)
  if [[ "$batch" == "yes" ]]; then opts+=(-o BatchMode=yes); fi
  if [[ -n "$VPS_SSH_KEY" ]]; then
    opts+=(-i "$VPS_SSH_KEY" -o IdentitiesOnly=yes)
  fi
  if use_password; then
    SSHPASS="$VPS_PASSWORD" sshpass -e ssh "${opts[@]}" "$VPS_HOST" "$@"
  else
    ssh "${opts[@]}" "$VPS_HOST" "$@"
  fi
}

ssh_run_tty() {
  local -a opts=(-o ConnectTimeout=10 -o ServerAliveInterval=30)
  if [[ -n "$VPS_SSH_KEY" ]]; then
    opts+=(-i "$VPS_SSH_KEY" -o IdentitiesOnly=yes)
  fi
  if use_password; then
    SSHPASS="$VPS_PASSWORD" sshpass -e ssh "${opts[@]}" -t "$VPS_HOST" "$@"
  else
    ssh "${opts[@]}" -t "$VPS_HOST" "$@"
  fi
}

# rsync helper that respects auth mode
rsync_run() {
  local -a ssh_args=(-o ConnectTimeout=10 -o ServerAliveInterval=30)
  if [[ -n "$VPS_SSH_KEY" ]]; then
    ssh_args+=(-i "$VPS_SSH_KEY" -o IdentitiesOnly=yes)
  fi
  if use_password; then
    SSHPASS="$VPS_PASSWORD" sshpass -e rsync -a --delete \
      -e "ssh ${ssh_args[*]}" "$@"
  else
    rsync -a --delete -e "ssh ${ssh_args[*]}" "$@"
  fi
}

# ─── Pre-flight ──────────────────────────────────────────────────────
preflight() {
  command -v ssh >/dev/null  || die "ssh not in PATH"
  command -v rsync >/dev/null || die "rsync not in PATH (apt install rsync)"

  if [[ -n "$VPS_SSH_KEY" && ! -f "$VPS_SSH_KEY" ]]; then
    die "VPS_SSH_KEY=$VPS_SSH_KEY but file does not exist"
  fi

  log "VPS_HOST=$VPS_HOST"
  log "VPS_DIR=$VPS_DIR  (resolved to: $(ssh_run "echo ${VPS_DIR/#\~/\$HOME}" 2>/dev/null || echo '?') )"
  log "APP_VERSION=$APP_VERSION"
  if use_password; then
    log "SSH: password auth (sshpass)"
  elif [[ -n "$VPS_SSH_KEY" ]]; then
    log "SSH: forced key $VPS_SSH_KEY"
  elif [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then
    log "SSH: ssh-agent ($(ssh-add -l | wc -l) keys loaded)"
  else
    warn "SSH: no agent, no VPS_SSH_KEY, no VPS_PASSWORD — auth will probably fail"
  fi

  # Test SSH + port 22 separately for clearer error messages
  local vps_host_only="${VPS_HOST#*@}"
  if ! nc -z -w 5 "$vps_host_only" 22 2>/dev/null; then
    die "VPS port 22 unreachable on $vps_host_only. fail2ban or firewall?
  Recover via VPS web console:
    fail2ban-client set sshd unbanip <your-ip>
  OR wait for fail2ban timeout."
  fi

  if ! ssh_run "true" 2>/dev/null; then
    if use_password; then
      die "SSH password auth failed for $VPS_HOST. Check VPS_PASSWORD is correct and
  that the VPS allows password auth (PasswordAuthentication yes in sshd_config)."
    else
      die "SSH auth failed for $VPS_HOST. Check ssh-agent (ssh-add -l), VPS_SSH_KEY,
  or set VPS_PASSWORD=... (or pass --ask-pass) to use password auth instead."
    fi
  fi
  ok "SSH to $VPS_HOST works"
}

# ─── Subcommand: sync ───────────────────────────────────────────────
# rsync source + Flutter build to VPS. Excludes .git, build/, target/.
cmd_sync() {
  preflight

  # Ensure target dir exists on VPS (idempotent). Tilde expands on the
  # remote shell, so VPS_DIR='~/foo/bar' becomes /home/<user>/foo/bar.
  log "Ensuring remote dir exists: $VPS_DIR"
  ssh_run "mkdir -p $VPS_DIR && echo ok" >/dev/null \
    || die "Could not create $VPS_DIR on VPS. Check VPS_PASSWORD / permissions."

  # Build Flutter web locally on laptop (fast, ~30-60s)
  if [[ ! "${SKIP_FRONTEND:-0}" = "1" && -x "$FLUTTER_BIN" ]]; then
    log "Building Flutter web locally with $FLUTTER_BIN"
    (cd "$APP_DIR/frontend" && \
      "$FLUTTER_BIN" build web --release \
        --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
        --no-tree-shake-icons) || die "Flutter build failed"
    ok "Flutter build/web/ ready"
  elif [[ "${SKIP_FRONTEND:-0}" = "1" ]]; then
    log "Skipping Flutter build (SKIP_FRONTEND=1)"
  else
    warn "Flutter binary not found at $FLUTTER_BIN — skipping frontend build"
  fi

  log "rsync source → $VPS_HOST:$VPS_DIR"
  local -a excludes=(
    --exclude='.git' --exclude='.git/'
    --exclude='frontend/build/' --exclude='frontend/build'
    --exclude='frontend/.dart_tool/' --exclude='frontend/.dart_tool'
    --exclude='backend/target/' --exclude='backend/target'
    --exclude='frontend/flutter_sdk/' --exclude='frontend/flutter_sdk'
    --exclude='node_modules/' --exclude='node_modules'
    --exclude='.env.deploy' --exclude='.env.deploy.local'
    --exclude='**/*.log'
  )
  rsync_run "${excludes[@]}" "$APP_DIR/" "$VPS_HOST:$VPS_DIR/" \
    || die "rsync failed"
  ok "Source synced to VPS"
}

# ─── Subcommand: build ──────────────────────────────────────────────
# Run deploy-local.sh on VPS with SKIP_PULL=1 (we already synced)
cmd_build() {
  preflight
  log "Building Docker images on VPS (services: ${SERVICES:-all})"
  local build_args="SKIP_PULL=1 APP_VERSION=$APP_VERSION"
  if [[ "${NO_CACHE:-0}" = "1" ]]; then
    build_args+=" FORCE_NO_CACHE=1"
  fi
  if [[ -n "${SERVICES:-}" ]]; then
    build_args+=" SERVICES=\"$SERVICES\""
  fi
  ssh_run "cd $VPS_DIR && $build_args bash scripts/deploy-local.sh" \
    || die "VPS build failed"
  ok "VPS build complete"
}

# ─── Subcommand: up ─────────────────────────────────────────────────
# Restart containers on VPS
cmd_up() {
  preflight
  log "Restarting containers on VPS"
  ssh_run "cd $VPS_DIR && SKIP_PULL=1 SKIP_BUILD=1 APP_VERSION=$APP_VERSION bash scripts/deploy-local.sh" \
    || die "VPS up failed"
  ok "Containers restarted"
}

# ─── Subcommand: status ─────────────────────────────────────────────
cmd_status() {
  preflight
  log "VPS state:"
  ssh_run "cd $VPS_DIR && \
    echo '── containers ──' && \
    docker compose -f $COMPOSE_FILE ps && \
    echo '' && \
    echo '── last 20 lines of auth-service ──' && \
    docker compose -f $COMPOSE_FILE logs --tail=20 auth-service 2>/dev/null || true"
}

# ─── Subcommand: logs ───────────────────────────────────────────────
cmd_logs() {
  preflight
  local svc="${SERVICES:-}"
  if [[ -n "$svc" ]]; then
    log "Tailing logs for $svc (Ctrl-C to stop)"
    ssh_run_tty "cd $VPS_DIR && docker compose -f $COMPOSE_FILE logs -f --tail=100 $svc"
  else
    log "Tailing logs for ALL services (Ctrl-C to stop)"
    ssh_run_tty "cd $VPS_DIR && docker compose -f $COMPOSE_FILE logs -f --tail=100"
  fi
}

# ─── Subcommand: shell ──────────────────────────────────────────────
cmd_shell() {
  preflight
  log "Opening SSH shell on $VPS_HOST (type 'exit' to return)"
  ssh_run_tty "cd $VPS_DIR && bash"
}

# ─── Subcommand: restart ────────────────────────────────────────────
cmd_restart() {
  preflight
  local svc="${SERVICES:-}"
  if [[ -n "$svc" ]]; then
    log "Restarting $svc on VPS"
    ssh_run "cd $VPS_DIR && docker compose -f $COMPOSE_FILE restart $svc" \
      || die "restart $svc failed"
    ok "$svc restarted"
  else
    log "Recreating all containers on VPS"
    ssh_run "cd $VPS_DIR && docker compose -f $COMPOSE_FILE up -d --force-recreate" \
      || die "restart failed"
    ok "All containers recreated"
  fi
}

# ─── Subcommand: all (default) ──────────────────────────────────────
cmd_all() {
  cmd_sync
  cmd_build
  cmd_up
  ok "Full deploy complete — APP_VERSION=$APP_VERSION"
  cmd_status
}

# ─── Subcommand: install ───────────────────────────────────────────
# Install Docker + system libs on a fresh VPS. No clone, no .env.
# This is what the rsync-based deploy-vps-askpass needs to work —
# it uploads source from your laptop each time, so no git clone on VPS.
cmd_install() {
  log "Installing system libs on fresh VPS: $VPS_HOST"
  log "(Docker, git, ufw, fail2ban, openssh-server, rsync, …)"

  if [[ -t 0 ]]; then
    read -r -p "Continue? This will run apt installs on $VPS_HOST [y/N] " ans
    [[ "$ans" =~ ^[Yy] ]] || die "aborted"
  fi

  ssh_run "set -euo pipefail; \
    export DEBIAN_FRONTEND=noninteractive; \
    echo '── 1/2 Installing Docker + plugins ──'; \
    if ! command -v docker >/dev/null 2>&1; then \
      curl -fsSL https://get.docker.com | sh; \
      systemctl enable --now docker; \
    else \
      echo 'docker already installed'; \
    fi; \
    echo '── 2/2 Installing system packages ──'; \
    apt-get update -qq; \
    apt-get install -y -qq git openssh-server ufw fail2ban ca-certificates curl rsync 2>&1 | tail -3; \
    echo ''; \
    echo '✅ Install complete'; \
    echo '   Next: make deploy-vps-askpass  (rsyncs source + builds + runs)' \
    " || die "install failed"

  ok "Install done. Now run: make deploy-vps-askpass"
}

# ─── Subcommand: bootstrap ──────────────────────────────────────────
# Full one-shot setup for a fresh VPS:
#   1. Install Docker + system libs (calls cmd_install)
#   2. Clone the repo to $VPS_DIR
#   3. Generate .env from .env.example with random passwords
# Use this if you DON'T plan to use the rsync-based deploy and
# instead want a traditional git-pull-based deploy on the VPS.
# Requires GitHub credentials (deploy key on VPS or PAT in VPS_REPO_URL).
cmd_bootstrap() {
  cmd_install
  log "Continuing bootstrap: cloning repo + generating .env"

  local repo_url="${VPS_REPO_URL:-git@github.com:s0lut1on/vuihoc.git}"
  log "Repo: $repo_url (override with VPS_REPO_URL=https://<PAT>@...)"

  ssh_run "set -euo pipefail; \
    echo '── Cloning repo to $VPS_DIR ──'; \
    mkdir -p \\$(dirname $VPS_DIR); \
    if [[ -d $VPS_DIR/.git ]]; then \
      echo 'repo already cloned'; \
    else \
      if [[ -d $VPS_DIR ]] && [[ -n \"\$(ls -A $VPS_DIR 2>/dev/null)\" ]]; then \
        remote_bak=\"$VPS_DIR.bak.\$(date +%s)\"; \
        echo \"dir exists but has no .git — moving to \$remote_bak\"; \
        mv $VPS_DIR \"\$remote_bak\"; \
      fi; \
      git clone $repo_url $VPS_DIR; \
    fi; \
      git clone $repo_url $VPS_DIR; \
    fi; \
    echo '── Generating .env from .env.example ──'; \
    cd $VPS_DIR; \
    if [[ -f .env ]]; then \
      echo '.env already exists — not overwriting'; \
    else \
      cp .env.example .env && chmod 600 .env; \
      sed -i \"s|change-this-to-a-random-256-bit-key-in-production|\$(openssl rand -hex 32)|g\" .env; \
      for var in AUTH_DB_PASS USER_DB_PASS CONTENT_DB_PASS PROGRESS_DB_PASS NOTIFICATION_DB_PASS MEDIA_DB_PASS QUESTION_BANK_DB_PASS LANGUAGE_DB_PASS; do \
        sed -i \"s|^\\\${var}=.*|\${var}=\$(openssl rand -hex 16)|g\" .env; \
      done; \
      echo '.env generated with random passwords'; \
    fi; \
    echo ''; \
    echo '✅ Bootstrap complete'; \
    echo '   Next: cd $VPS_DIR && bash scripts/deploy-local.sh' \
    " || die "bootstrap failed (probably need GitHub SSH key or PAT for private repo clone)"

  ok "Bootstrap done. Now run: make deploy-vps-askpass (or use scripts/deploy-local.sh on VPS)"
}

# ─── Help ───────────────────────────────────────────────────────────
cmd_help() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  echo ""
  echo "Subcommands: sync build up status logs shell restart install bootstrap all help"
  echo ""
  echo "Common env vars (set in .env.deploy or inline):"
  echo "  VPS_HOST=$VPS_HOST"
  echo "  VPS_DIR=$VPS_DIR"
  echo "  VPS_SSH_KEY= (empty = use ssh-agent)"
  echo "  VPS_PASSWORD= (set to use password auth via sshpass — no key needed)"
  echo "  SERVICES=auth-service (limit build/restart to one service)"
  echo "  SKIP_FRONTEND=1, SKIP_BACKEND=1, NO_CACHE=1"
  echo "  APP_VERSION=$APP_VERSION"
  echo "  VPS_REPO_URL= (for bootstrap, default: git@github.com:s0lut1on/vuihoc.git)"
  echo ""
  echo "Auth modes (priority order):"
  echo "  1. VPS_PASSWORD=...     password via sshpass (no key required)"
  echo "  2. VPS_SSH_KEY=/path    force a specific key (skip ssh-agent)"
  echo "  3. (default)            ssh-agent"
  echo ""
  echo "Flags: --ask-pass prompts for password (then uses sshpass, doesn't store it)"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deploy-vps.sh              # all (uses ssh-agent)"
  echo "  ./scripts/deploy-vps.sh install      # install Docker + libs on fresh VPS (no clone)"
  echo "  ./scripts/deploy-vps.sh bootstrap    # install + clone repo + gen .env (full setup)"
  echo "  ./scripts/deploy-vps.sh sync         # rsync only"
  echo "  ./scripts/deploy-vps.sh build        # build only"
  echo "  SERVICES=auth-service ./scripts/deploy-vps.sh build"
  echo "  ./scripts/deploy-vps.sh status"
  echo "  SERVICES=auth-service ./scripts/deploy-vps.sh logs"
  echo "  ./scripts/deploy-vps.sh shell        # SSH into VPS"
  echo ""
  echo "No-key password auth (no SSH key setup required):"
  echo "  VPS_PASSWORD='your-vps-password' ./scripts/deploy-vps.sh status"
  echo "  ./scripts/deploy-vps.sh --ask-pass status"
  echo "  echo 'your-vps-password' > ~/.math-app-vps-pass"
  echo "  VPS_PASSWORD=\$(cat ~/.math-app-vps-pass) ./scripts/deploy-vps.sh status"
}

# ─── Dispatch ───────────────────────────────────────────────────────
# Pre-scan for --ask-pass / --password=PASS (so it works as the very first arg)
new_args=()
for arg in "$@"; do
  case "$arg" in
    --ask-pass)
      if [[ -z "$VPS_PASSWORD" ]]; then
        if [[ -t 0 ]]; then
          read -r -s -p "VPS password for $VPS_HOST: " VPS_PASSWORD
          echo
        else
          die "--ask-pass requires a TTY (interactive terminal). Set VPS_PASSWORD=... instead."
        fi
      fi
      ;;
    --password=*)
      VPS_PASSWORD="${arg#--password=}"
      ;;
    *) new_args+=("$arg") ;;
  esac
done
set -- "${new_args[@]}"

subcmd="${1:-all}"
shift || true

# Allow SERVICES=foo ./deploy-vps.sh logs
if [[ -n "${SERVICES:-}" && $# -gt 0 ]]; then
  set -- "$@"
fi

case "$subcmd" in
  sync)      cmd_sync "$@" ;;
  build)     cmd_build "$@" ;;
  up)        cmd_up "$@" ;;
  status)    cmd_status "$@" ;;
  logs)      cmd_logs "$@" ;;
  shell)     cmd_shell "$@" ;;
  restart)   cmd_restart "$@" ;;
  install)   cmd_install "$@" ;;
  bootstrap) cmd_bootstrap "$@" ;;
  all)       cmd_all "$@" ;;
  help|-h|--help) cmd_help ;;
  *) err "Unknown subcommand: $subcmd"; cmd_help; exit 1 ;;
esac
