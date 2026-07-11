#!/usr/bin/env python3
"""
Daily traffic stats: parse Traefik access.log (CLF), split real-users vs bots,
write per-day JSON to /var/log/traefik/stats/YYYY-MM-DD.json.

Bot detection = User-Agent matches a known crawler/scanner list
(see BOT_PATTERNS below). Anything that doesn't match = real-user.

CLF format from Traefik:
  <remote_ip> - - [<time>] "<method> <path> HTTP/1.1" <status> <size> "<referer>" "<ua>"

Run: python3 traffic_stats.py [LOG_FILE]
Default LOG_FILE: /var/log/traefik/access.log
"""
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

# Known bot User-Agent substrings. Conservative — when in doubt, count as real user.
BOT_PATTERNS = [
    "bot", "crawler", "spider", "slurp", "bingpreview",
    "facebookexternalhit", "facebot", "twitterbot", "linkedinbot",
    "embedly", "quora link preview", "skypeuripreview", "telegrambot",
    "whatsapp", "discordbot", "slackbot", "applebot", "duckduckbot",
    "baiduspider", "yandexbot", "sogou", "exabot", "ia_archiver",
    "ahrefsbot", "semrushbot", "mj12bot", "dotbot", "petalbot",
    "curl/", "wget/", "httpie", "python-requests", "python-urllib",
    "go-http-client", "java/", "libwww-perl", "lwp::simple",
    "scrapy", "httpclient", "okhttp", "axios/", "node-fetch",
    "masscan", "zgrab", "nmap", "nikto", "sqlmap", "nuclei",
    "uptimerobot", "pingdom", "statuscake", "site24x7",
    "googlebot", "googleweblight", "adsbot-google",
    "chrome-lighthouse", "lighthouse",
]

# Traefik emits health checks / internal probes too — they have empty UA.
EMPTY_UA_IS_BOT = True

CLF_RE = re.compile(
    r'^(\S+) \S+ \S+ \[([^\]]+)\] "(\S+) (\S+) \S+" (\d+) (\d+|-) "([^"]*)" "([^"]*)"'
)

STATS_DIR = Path("/var/log/traefik/stats")


def parse_clf_line(line):
    m = CLF_RE.match(line.strip())
    if not m:
        return None
    ip, ts, method, path, status, size, referer, ua = m.groups()
    try:
        # 04/Jul/2026:10:35:05 +0200
        dt = datetime.strptime(ts, "%d/%b/%Y:%H:%M:%S %z")
    except ValueError:
        return None
    return {
        "ip": ip,
        "ts": dt,
        "method": method,
        "path": path,
        "status": int(status),
        "size": int(size) if size != "-" else 0,
        "referer": referer,
        "ua": ua,
    }


def is_bot(ua):
    if not ua:
        return EMPTY_UA_IS_BOT
    ua_low = ua.lower()
    return any(p in ua_low for p in BOT_PATTERNS)


def aggregate(records, day):
    """Return a stats dict for the given day."""
    real = [r for r in records if r["ts"].date() == day and not is_bot(r["ua"])]
    bots = [r for r in records if r["ts"].date() == day and is_bot(r["ua"])]

    def bucket(rs):
        unique_ips = {r["ip"] for r in rs}
        paths = defaultdict(int)
        status_codes = defaultdict(int)
        for r in rs:
            paths[r["path"]] += 1
            status_codes[r["status"]] += 1
        return {
            "requests": len(rs),
            "unique_ips": len(unique_ips),
            "top_paths": sorted(paths.items(), key=lambda x: -x[1])[:10],
            "status_codes": dict(sorted(status_codes.items())),
        }

    return {
        "date": day.isoformat(),
        "generated_at": datetime.now().isoformat(),
        "real_users": bucket(real),
        "bots": bucket(bots),
    }


def main():
    log_path = Path(sys.argv[1] if len(sys.argv) > 1 else "/var/log/traefik/access.log")
    if not log_path.exists():
        print(f"no log file at {log_path}", file=sys.stderr)
        return 1

    STATS_DIR.mkdir(parents=True, exist_ok=True)

    records = []
    with open(log_path, "r", errors="replace") as f:
        for line in f:
            r = parse_clf_line(line)
            if r:
                records.append(r)

    if not records:
        print("no records parsed", file=sys.stderr)
        return 0

    # Group by day, write one JSON per day
    days = {r["ts"].date() for r in records}
    written = []
    for day in sorted(days):
        stats = aggregate(records, day)
        out = STATS_DIR / f"{day.isoformat()}.json"
        with open(out, "w") as f:
            json.dump(stats, f, indent=2)
        written.append(out.name)

    # Print one-line summary to stdout (for cron)
    today = max(days)
    today_stats = aggregate(records, today)
    real = today_stats["real_users"]
    bots = today_stats["bots"]
    print(
        f"[traffic] {today.isoformat()} "
        f"real={real['requests']}reqs/{real['unique_ips']}IPs "
        f"bots={bots['requests']}reqs/{bots['unique_ips']}IPs "
        f"-> {','.join(written)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
