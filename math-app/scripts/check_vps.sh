#!/usr/bin/env bash
set -euo pipefail

OUTPUT_FILE="vps_check_results.md"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname)
WHOAMI=$(whoami)

# --- Header ---
cat > "$OUTPUT_FILE" << EOF
# VPS Health Check Report

- **Generated:** $DATE
- **Hostname:** $HOST
- **User:** $WHOAMI

---

## 1. System Info

EOF

# --- System Info ---
{
    echo '```'
    echo '--- OS ---'
    cat /etc/os-release 2>/dev/null | head -5 || echo 'OS info unavailable'
    echo ''
    echo '--- Kernel ---'
    uname -r
    echo ''
    echo '--- Uptime ---'
    uptime
    echo '```'
} >> "$OUTPUT_FILE"

# --- Docker ---
cat >> "$OUTPUT_FILE" << EOF

---

## 2. Docker Status

EOF

{
    echo '```'
    echo '--- Docker version ---'
    docker --version 2>/dev/null || echo 'docker: NOT FOUND'
    echo ''
    echo '--- Docker Compose ---'
    docker compose version 2>/dev/null || echo 'docker compose: NOT FOUND'
    echo ''
    echo '--- Docker service ---'
    systemctl is-active docker 2>/dev/null || echo 'docker service: NOT ACTIVE'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Ports ---
cat >> "$OUTPUT_FILE" << EOF

---

## 3. Port Usage (80 / 443 / 8082)

EOF

{
    echo '```'
    ss -tlnp 2>/dev/null | grep -E ':80|:443|:8082' || echo 'No matching ports found'
    echo ''
    echo '--- All listening ports of interest ---'
    ss -tlnp 2>/dev/null | grep -E ':80|:443|:8082|:300[0-9]|900[0-9]' || echo 'None found'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Web Servers ---
cat >> "$OUTPUT_FILE" << EOF

---

## 4. Existing Reverse Proxies / Web Servers

EOF

detect_web_servers() {
    local found=0
    echo '```sh'
    echo '--- Nginx ---'
    if systemctl status nginx --no-pager &>/dev/null; then
        nginx -v 2>&1 | head -1
        echo "Status: $(systemctl is-active nginx)"
        echo "Config file: /etc/nginx/nginx.conf"
        found=1
    else
        echo 'nginx: NOT INSTALLED or NOT RUNNING'
    fi
    echo ''
    echo '--- Apache ---'
    if systemctl status apache2 --no-pager &>/dev/null; then
        apache2 -v 2>&1 | head -1
        echo "Status: $(systemctl is-active apache2)"
        found=1
    else
        echo 'apache2: NOT INSTALLED or NOT RUNNING'
    fi
    echo ''
    echo '--- Caddy ---'
    if systemctl status caddy --no-pager &>/dev/null; then
        caddy version 2>/dev/null || echo 'caddy: version unknown'
        echo "Status: $(systemctl is-active caddy)"
        found=1
    else
        echo 'caddy: NOT INSTALLED or NOT RUNNING'
    fi
    echo ''
    echo '--- Traefik (standalone) ---'
    if pgrep -f traefik &>/dev/null; then
        echo 'traefik: RUNNING (PID found)'
        found=1
    else
        echo 'traefik: NOT RUNNING'
    fi
    echo '```'
    echo ''
    if [ "$found" -eq 1 ]; then
        echo '**Result: Existing reverse proxy detected → Use Option A deployment**'
    else
        echo '**Result: No existing reverse proxy → Use dedicated VPS deployment**'
    fi
}
detect_web_servers >> "$OUTPUT_FILE"

# --- Resources ---
cat >> "$OUTPUT_FILE" << EOF

---

## 5. System Resources

EOF

{
    echo '```'
    echo '--- CPU ---'
    nproc || echo 'nproc unavailable'
    echo ''
    echo '--- RAM ---'
    free -h
    echo ''
    echo '--- Disk Space ---'
    df -h
    echo ''
    echo '--- Docker disk usage ---'
    docker system df 2>/dev/null || echo 'docker system df unavailable'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Firewall ---
cat >> "$OUTPUT_FILE" << EOF

---

## 6. Firewall Status

EOF

{
    echo '```'
    ufw status 2>/dev/null || echo 'ufw: not installed or inactive'
    echo ''
    echo '--- iptables (brief) ---'
    iptables -L -n 2>/dev/null | head -20 || echo 'iptables: not available'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Security ---
cat >> "$OUTPUT_FILE" << EOF

---

## 7. Security Checks

EOF

{
    echo '```'
    echo '--- fail2ban ---'
    systemctl is-active fail2ban 2>/dev/null || echo 'fail2ban: NOT ACTIVE'
    echo ''
    echo '--- SSH password auth (likely disabled = good) ---'
    grep -E '^PasswordAuthentication|^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null || echo 'sshd_config: not readable or values not set'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Running Docker Containers (if any) ---
cat >> "$OUTPUT_FILE" << EOF

---

## 8. Running Docker Containers

EOF

{
    echo '```'
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo 'No running containers / docker unavailable'
    echo '```'
} >> "$OUTPUT_FILE"

# --- Footer ---
cat >> "$OUTPUT_FILE" << EOF

---

## Summary

| Check | Status |
|-------|--------|
| Docker installed | See Section 2 |
| Port 80 occupied | See Section 3 |
| Port 443 occupied | See Section 3 |
| RAM ≥ 4GB | See Section 5 |
| Disk ≥ 40GB free | See Section 5 |
| Reverse proxy running | See Section 4 |
| Firewall active | See Section 6 |
| fail2ban active | See Section 7 |

EOF

echo "Done. Report saved to: $(pwd)/$OUTPUT_FILE"
echo "Copy this file to your local machine with:"
echo "  scp $WHOAMI@YOUR_VPS_IP:$(pwd)/$OUTPUT_FILE ."
