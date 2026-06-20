#!/usr/bin/env bash
# Force-flush Flutter's service worker + browser caches.
# Two ways to do this without touching the running app:
#
# A) nginx: send Cache-Control: no-cache for all .js/.html files
#    so the SW stops being useful and clients always revalidate
# B) index.html: inject a meta tag that unregisters the SW on next load
#
# This script does BOTH (A + B) at once. Idempotent.

set -euo pipefail

VPS_HOST="${VPS_HOST:-root@194.233.94.167}"
INSTALL_DIR="${INSTALL_DIR:-/root/math-app/math-app}"

# Sanity check
ssh "$VPS_HOST" "bash -s" <<REMOTE_EOF
set -e
echo "=== A. Patch nginx to send no-cache for JS/HTML ==="
NGINX_CONF=/etc/nginx/conf.d/default.conf
if [[ -f "\$NGINX_CONF" ]]; then
  # Add no-cache headers for .js and .html inside the location block
  if ! grep -q "no-cache.*js" "\$NGINX_CONF"; then
    cp "\$NGINX_CONF" "\$NGINX_CONF.busted.\$(date +%s)"
    sed -i '/location \/ {/,/^}/ s|location / {|location / {\n        add_header Cache-Control "no-cache, no-store, must-revalidate" always;\n        add_header Pragma "no-cache";\n        add_header Expires "0";|' "\$NGINX_CONF"
    nginx -t && nginx -s reload
    echo "  -> nginx reloaded"
  else
    echo "  -> already patched"
  fi
else
  echo "  -> nginx conf not at \$NGINX_CONF (docker setup, skip)"
fi

echo ""
echo "=== B. Inject SW-unregister meta into index.html ==="
INDEX=$INSTALL_DIR/build/web/index.html
if [[ -f "\$INDEX" ]]; then
  if ! grep -q "serviceWorker.unregister" "\$INDEX"; then
    cp "\$INDEX" "\$INDEX.busted.\$(date +%s)"
    # Inject after the opening <head>
    sed -i '0,/<\/head>/s||</head>|<script>navigator.serviceWorker.getRegistrations().then(r=>r.forEach(x=>x.unregister()));<\/script>\n</head>|' "\$INDEX"
    echo "  -> index.html patched"
  else
    echo "  -> already patched"
  fi
else
  echo "  -> \$INDEX not found"
fi

echo ""
echo "=== C. Verify ==="
curl -sI https://sekklings.com/main.dart.js | head -5
echo ""
echo "If Cache-Control header shows no-cache, your browser will revalidate on next load."
REMOTE_EOF
