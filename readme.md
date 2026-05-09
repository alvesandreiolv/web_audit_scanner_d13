# Web Audit Scanner

Debian container packed with security tools to scan websites you own.

## Setup

```bash
docker compose up -d
```

## Usage

```bash
# Full scan
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com

# Single tool
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com <tool>
```

## Available tools

```bash
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com all      # run everything (default)
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com -nmap    # run everything except nmap
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com whois    # domain registration info
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com dig      # DNS records
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com nmap     # port scan + service versions
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com whatweb  # identify tech stack
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com sslscan  # SSL/TLS analysis
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com dirb     # directory enumeration
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com wafw00f  # detect WAF
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com headers  # HTTP response headers
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com testssl  # SSL/TLS vulnerability check
```

## Logs

Results in `volume_mounts/app/logs/<host>_<timestamp>/`:
- `individual_logs/` — per-tool output
- `combined_log.txt` — all results in one file
