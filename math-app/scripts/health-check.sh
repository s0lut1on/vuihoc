#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="${BASE_URL:-https://sekklings.com}"
TIMEOUT=30
ALL_OK=true

check() {
  local name=$1
  local path=$2
  local exp=${3:-200}
  local url="${BASE_URL}${path}"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" || echo 000)
  if [ "$code" = "$exp" ]; then
    echo -e "${GREEN}✅${NC} $name ($url)"
  else
    echo -e "${RED}❌${NC} $name ($url) — expected $exp, got $code"
    ALL_OK=false
  fi
}

echo "Health-checking services at $BASE_URL ..."

check "Traefik (root)"       "/"         200
check "Auth health"          "/api/auth/health"    200
check "User health"          "/api/users/health"   200
check "Content health"       "/api/content/health" 200
check "Progress health"      "/api/progress/health" 200
check "Notification health"  "/api/notifications/health" 200
check "Media health"         "/api/media/health"   200
check "QuestionBank health"  "/api/questions/health" 200

check "Content curriculum (auth required)"  "/api/content/curriculum" 401
check "Auth guest GET"         "/api/auth/guest"     200
check "Auth me"              "/api/auth/me"        200

if [ "$ALL_OK" = true ]; then
  echo -e "\n${GREEN}All health checks passed.${NC}"
  exit 0
else
  echo -e "\n${RED}Some health checks failed.${NC}"
  exit 1
fi
