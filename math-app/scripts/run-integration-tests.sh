#!/usr/bin/env bash
set -eo pipefail

SERVICE="${1:-content}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$PROJECT_ROOT"

find_free_port() {
  local port=3100
  while ss -tln | grep -q ":$port "; do
    port=$((port + 1))
  done
  echo "$port"
}

PORT=$(find_free_port)
export PORT

HEALTH_URL=""
BINARY_CMD=""
PID=""

case "$SERVICE" in
  content)
    HEALTH_URL="http://localhost:$PORT/api/content/health"
    BINARY_CMD="cargo run -p content"
    ;;
  auth)
    HEALTH_URL="http://localhost:$PORT/api/auth/health"
    BINARY_CMD="cargo run -p auth"
    ;;
  user)
    HEALTH_URL="http://localhost:$PORT/api/users/health"
    BINARY_CMD="cargo run -p user"
    ;;
  progress)
    HEALTH_URL="http://localhost:$PORT/api/progress/health"
    BINARY_CMD="cargo run -p progress"
    ;;
  notification)
    HEALTH_URL="http://localhost:$PORT/api/notifications/health"
    BINARY_CMD="cargo run -p notification"
    ;;
  media)
    HEALTH_URL="http://localhost:$PORT/api/media/health"
    BINARY_CMD="cargo run -p media"
    ;;
  *)
    echo "Unknown service: $SERVICE"
    exit 1
    ;;
esac

cleanup() {
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Starting $SERVICE binary on PORT=$PORT..."
cd "$PROJECT_ROOT/backend"
cargo build -p "$SERVICE"
./target/debug/"$SERVICE" > /tmp/${SERVICE}.log 2>&1 &
PID=$!

MAX_RETRIES=30
echo "Waiting for service health..."
for _ in $(seq 1 $MAX_RETRIES); do
  if curl -sf "$HEALTH_URL" >/dev/null; then
    echo "Service is healthy!"
    break
  fi
  echo -n "."
  sleep 1
done

if ! curl -sf "$HEALTH_URL" >/dev/null; then
  echo "Service failed to start. Logs:"
  cat /tmp/${SERVICE}.log
  exit 1
fi

echo "Running integration tests for $SERVICE..."
cd "$PROJECT_ROOT/backend/$SERVICE"
cargo test -- --ignored

echo "Integration tests complete!"
