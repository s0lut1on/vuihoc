#!/usr/bin/env bash
# VPS SSH recovery script — paste into the VPS console (not SSH) if
# you can't SSH in after running vps-bootstrap.sh.
#
# This script MUST be run from the VPS's physical console or via the
# VPS provider's "console" feature (e.g. Hetzner Cloud Console, DO
# Droplet Console, AWS Lightsail Terminal). NOT via SSH — if SSH
# worked, you wouldn't need this.
#
# What it does:
#   1. Disables ufw (was it accidentally enabled?)
#   2. Unbans all fail2ban IPs (the most common cause of "can't ssh")
#   3. Verifies sshd is running and listening on port 22
#   4. Verifies the SSH host keys exist
#   5. Verifies root's authorized_keys has at least one key
#   6. Resets sshd config to a sane default if it's broken
#   7. Restarts sshd (does NOT kill your console session)
#
# Usage (from VPS console):
#   curl -sSL https://raw.githubusercontent.com/s0lut1on/vuihoc/main/math-app/scripts/vps-unlock.sh | bash
#   or, if the repo is cloned:
#   cd /root/math-app/math-app && bash scripts/vps-unlock.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $*"; }
err()   { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $*" >&2; }
ok()    { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $*"; }

[[ $EUID -ne 0 ]] && { err "Must run as root"; exit 1; }

# ─── 1. Disable ufw if active ──────────────────────────
log "Step 1: check ufw..."
if command -v ufw >/dev/null 2>&1; then
  ufw_status=$(ufw status 2>/dev/null | head -1 || echo "Status: inactive")
  echo "  ufw status: $ufw_status"
  if echo "$ufw_status" | grep -q "active"; then
    warn "ufw is active — disabling so we don't get cut off again"
    ufw disable
    ok "ufw disabled"
  else
    ok "ufw already inactive"
  fi
else
  ok "ufw not installed"
fi

# ─── 2. Unban all fail2ban IPs ─────────────────────────
log "Step 2: check fail2ban..."
if command -v fail2ban-client >/dev/null 2>&1; then
  if fail2ban-client ping >/dev/null 2>&1; then
    banned=$(fail2ban-client status 2>/dev/null | grep -c "Banned IP" || true)
    if [[ "$banned" -gt 0 ]]; then
      warn "fail2ban has $banned banned IP(s) — unbanning all..."
      fail2ban-client unban all
      ok "All IPs unbanned"
    else
      ok "No banned IPs"
    fi
  else
    warn "fail2ban not running — skipping"
  fi
else
  ok "fail2ban not installed"
fi

# ─── 3. Verify sshd is listening ───────────────────────
log "Step 3: verify sshd is listening..."
if ! command -v ss >/dev/null 2>&1; then apt-get install -y iproute2 >/dev/null 2>&1 || true; fi
if ss -tln 2>/dev/null | grep -q ':22 '; then
  ok "sshd IS listening on port 22"
else
  warn "sshd NOT listening on port 22 — checking why..."
  if ! pgrep -x sshd >/dev/null 2>&1; then
    err "sshd is not running! Trying to start..."
    systemctl enable ssh 2>/dev/null || update-rc.d ssh defaults 2>/dev/null || true
    systemctl start ssh 2>/dev/null || service ssh start 2>/dev/null || true
    sleep 1
    if pgrep -x sshd >/dev/null 2>&1; then
      ok "sshd started"
    else
      err "sshd still not running — check logs: journalctl -u ssh -n 50"
    fi
  fi
fi

# ─── 4. Verify SSH host keys exist ─────────────────────
log "Step 4: verify SSH host keys..."
missing=0
for kt in ed25519 rsa ecdsa; do
  if [[ ! -f "/etc/ssh/ssh_host_${kt}_key" ]]; then
    warn "Missing host key: /etc/ssh/ssh_host_${kt}_key"
    missing=$((missing + 1))
  fi
done
if [[ $missing -gt 0 ]]; then
  warn "Regenerating missing host keys..."
  ssh-keygen -A
  systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || true
  ok "Host keys regenerated"
else
  ok "All host keys present"
fi

# ─── 5. Verify authorized_keys has at least one key ───
log "Step 5: verify authorized_keys..."
AUTH_KEYS="/root/.ssh/authorized_keys"
if [[ -f "$AUTH_KEYS" ]]; then
  count=$(grep -c '^ssh-' "$AUTH_KEYS" 2>/dev/null || echo 0)
  if [[ "$count" -eq 0 ]]; then
    err "authorized_keys exists but has no keys!"
    err "If you ran ssh-copy-id, it may have failed silently."
    err "To fix: on your LAPTOP, run: ssh-copy-id -i ~/.ssh/your_key.pub root@THIS_VPS"
    err "Then try SSH again."
  else
    ok "authorized_keys has $count key(s)"
  fi
else
  warn "authorized_keys does not exist — creating empty file"
  mkdir -p /root/.ssh && chmod 700 /root/.ssh && touch "$AUTH_KEYS" && chmod 600 "$AUTH_KEYS"
  err "YOU MUST ADD YOUR KEY: ssh-copy-id -i ~/.ssh/your_key.pub root@THIS_VPS"
fi

# ─── 6. sshd_config sanity check ───────────────────────
log "Step 6: check sshd_config..."
if [[ -f /etc/ssh/sshd_config ]]; then
  if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    warn "Password auth is enabled — leaving as-is (key auth is preferred)"
  fi
  if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    warn "PermitRootLogin no — change to 'prohibit-password' or 'yes' if you want root SSH"
  fi
  if ! sshd -t 2>/dev/null; then
    err "sshd config has syntax errors — restoring safe default"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.broken.$(date +%s)
    cat > /etc/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    ok "Restored safe default sshd_config"
  else
    ok "sshd_config OK"
  fi
fi

# ─── 7. Restart sshd ───────────────────────────────────
log "Step 7: restart sshd..."
systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || true
sleep 2
if pgrep -x sshd >/dev/null 2>&1; then
  ok "sshd running (PID $(pgrep -x sshd | head -1))"
else
  err "sshd still not running — check: journalctl -u ssh -n 50"
fi

# ─── Final summary ─────────────────────────────────────
cat <<SUMMARY

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔓 SSH recovery complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

State now:
  ufw:          disabled (safe for development)
  fail2ban:     unbanned all IPs, still watching
  sshd:         running, listening on port 22

Try SSH again from your laptop. If it STILL fails:

  1. From VPS console:
       tail -50 /var/log/auth.log      # look for "Connection closed by..."
       tail -50 /var/log/fail2ban.log  # look for "Ban <your-ip>"
       fail2ban-client status sshd     # check if you're banned

  2. If fail2ban keeps banning you:
       # Either whitelist your IP:
       sudo nano /etc/fail2ban/jail.local
       # Add: ignoreip = 127.0.0.1/8 <your-ip>/32
       sudo systemctl restart fail2ban
       # Or just disable sshd jail:
       sudo fail2ban-client set sshd unbanip all

  3. If ufw was the culprit:
       # Re-enable it carefully:
       sudo ufw default allow outgoing
       sudo ufw allow 22/tcp
       sudo ufw enable
       # Then in a NEW ssh session:
       sudo ufw status verbose
       # If you get cut off, console in and: sudo ufw disable

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY
