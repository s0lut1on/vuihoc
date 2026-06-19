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

# ─── SSH helper ──────────────────────────────────────────────────────
# Uses ssh-agent by default; if VPS_SSH_KEY is set, force that key only.
ssh_run() {
  local -a opts=(-o ConnectTimeout=10 -o BatchMode=yes -o ServerAliveInterval=30)
  if [[ -n "$VPS_SSH_KEY" ]]; then
    opts=(-i "$VPS_SSH_KEY" -o IdentitiesOnly=yes "${opts[@]}")
  fi
  ssh "${opts[@]}" "$VPS_HOST" "$@"
}

ssh_run_tty() {
  local -a opts=(-o ConnectTimeout=10 -o ServerAliveInterval=30)
  if [[ -n "$VPS_SSH_KEY" ]]; then
    opts=(-i "$VPS_SSH_KEY" -o IdentitiesOnly=yes "${opts[@]}")
  fi
  ssh "${opts[@]}" -t "$VPS_HOST" "$@"
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
  if [[ -n "$VPS_SSH_KEY" ]]; then
    log "SSH: forced key $VPS_SSH_KEY"
  elif [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then
    log "SSH: ssh-agent ($(ssh-add -l | wc -l) keys loaded)"
  else
    warn "SSH: no agent and no VPS_SSH_KEY — auth will probably fail"
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
    die "SSH auth failed for $VPS_HOST. Check ssh-agent (ssh-add -l) or VPS_SSH_KEY."
  fi
  ok "SSH to $VPS_HOST works"
}

# ─── Subcommand: sync ───────────────────────────────────────────────
# rsync source + Flutter build to VPS. Excludes .git, build/, target/.
cmd_sync() {
  preflight

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
  rsync -a --delete "${excludes[@]}" \
    -e "ssh $([[ -n "$VPS_SSH_KEY" ]] && echo "-i $VPS_SSH_KEY -o IdentitiesOnly=yes")" \
    "$APP_DIR/" "$VPS_HOST:$VPS_DIR/" || die "rsync failed"
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

# ─── Help ───────────────────────────────────────────────────────────
cmd_help() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  echo ""
  echo "Subcommands: sync build up status logs shell restart all help"
  echo ""
  echo "Common env vars (set in .env.deploy or inline):"
  echo "  VPS_HOST=$VPS_HOST"
  echo "  VPS_DIR=$VPS_DIR"
  echo "  VPS_SSH_KEY= (empty = use ssh-agent)"
  echo "  SERVICES=auth-service (limit build/restart to one service)"
  echo "  SKIP_FRONTEND=1, SKIP_BACKEND=1, NO_CACHE=1"
  echo "  APP_VERSION=$APP_VERSION"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deploy-vps.sh              # all"
  echo "  ./scripts/deploy-vps.sh sync         # rsync only"
  echo "  ./scripts/deploy-vps.sh build        # build only"
  echo "  SERVICES=auth-service ./scripts/deploy-vps.sh build"
  echo "  ./scripts/deploy-vps.sh status"
  echo "  SERVICES=auth-service ./scripts/deploy-vps.sh logs"
  echo "  ./scripts/deploy-vps.sh shell        # SSH into VPS"
}

# ─── Dispatch ───────────────────────────────────────────────────────
subcmd="${1:-all}"
shift || true

# Allow SERVICES=foo ./deploy-vps.sh logs
if [[ -n "${SERVICES:-}" && $# -gt 0 ]]; then
  set -- "$@"
fi

case "$subcmd" in
  sync)    cmd_sync "$@" ;;
  build)   cmd_build "$@" ;;
  up)      cmd_up "$@" ;;
  status)  cmd_status "$@" ;;
  logs)    cmd_logs "$@" ;;
  shell)   cmd_shell "$@" ;;
  restart) cmd_restart "$@" ;;
  all)     cmd_all "$@" ;;
  help|-h|--help) cmd_help ;;
  *) err "Unknown subcommand: $subcmd"; cmd_help; exit 1 ;;
esac
