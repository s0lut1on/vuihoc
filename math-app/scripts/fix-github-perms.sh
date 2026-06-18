#!/usr/bin/env bash
# One-shot fix for "Permission denied (publickey)" — even with the
# private key on the VPS. The 5 fixes are usually all you need.

VPS_HOST="${VPS_HOST:-root@194.233.94.167}"
KEY_PATH="/root/.ssh/math_app_deploy"

ssh "$VPS_HOST" KEY_PATH="$KEY_PATH" bash <<'REMOTE'
set -euo pipefail

echo "=== Before: perms and key state ==="
stat -c '%a %n' /root/.ssh || true
stat -c '%a %n' "$KEY_PATH" || true
stat -c '%s bytes %n' "$KEY_PATH" || true

echo ""
echo "=== Fix 1: lock down perms ==="
chmod 700 /root/.ssh
chmod 600 "$KEY_PATH"
# Just in case a stray .pub got opened up:
[[ -f "$KEY_PATH.pub" ]] && chmod 644 "$KEY_PATH.pub"
echo "After: /root/.ssh = $(stat -c '%a' /root/.ssh), $KEY_PATH = $(stat -c '%a' $KEY_PATH)"

echo ""
echo "=== Fix 2: github.com in known_hosts (silently accept fingerprint) ==="
mkdir -p /root/.ssh
ssh-keyscan -t rsa,ed25519 github.com >> /root/.ssh/known_hosts 2>/dev/null || true
sort -u /root/.ssh/known_hosts -o /root/.ssh/known_hosts
chmod 644 /root/.ssh/known_hosts
echo "Known hosts:"
grep github.com /root/.ssh/known_hosts | awk '{print "  " $1, $2, $3}' || true

echo ""
echo "=== Fix 3: show the pubkey GitHub should have ==="
echo "If your pubkey on https://github.com/settings/keys does NOT match this,"
echo "delete the one on GitHub and paste THIS one:"
echo ""
cat "$KEY_PATH.pub"
echo ""
echo "Fingerprint:"
ssh-keygen -lf "$KEY_PATH"

echo ""
echo "=== Fix 4: verify the key isn't passphrase-protected ==="
head -1 "$KEY_PATH" | grep -q "ENCRYPTED" && echo "PROBLEM: key is encrypted (passphrase-protected)" \
                                    || echo "OK: key is unencrypted"

echo ""
echo "=== Fix 5: Test ==="
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1
REMOTE
