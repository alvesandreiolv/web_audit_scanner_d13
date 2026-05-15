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
docker exec web_audit_scanner_debian_w1s9 sh /app/tools/scanner.sh https://yoursite.com crawl   # spider/crawl all linked pages
```

## What each tool does

| Tool | What it checks |
|------|----------------|
| `whois` | Domain ownership, registrar, creation/expiry dates |
| `dig` | DNS records (A, MX, TXT, NS, etc.) |
| `nmap` | Open ports, service versions, OS fingerprinting |
| `whatweb` | Web tech stack (server, framework, CMS, CDN) |
| `sslscan` | Supported cipher suites, TLS versions, certificate info |
| `dirb` | Hidden directories and files via wordlist brute force |
| `wafw00f` | Detects if a Web Application Firewall is in front |
| `headers` | Raw HTTP response headers (server, cookies, security policies) |
| `testssl` | SSL/TLS vulnerabilities (Heartbleed, POODLE, etc.) |
| `crawl` | Follows links to discover all pages on the site |

## Logs

Each scan creates a timestamped log directory under `volume_mounts/app/logs/`. Logs are git-ignored — they stay local and are never pushed to the repo.

```
volume_mounts/
└── app/
    └── logs/
        └── <host>_<HHMMSS>_<DDMMYY>/
            ├── combined_log.txt          # all results concatenated into one file
            └── individual_logs/
                ├── crawl.txt             # crawled page URLs and responses
                ├── dirb.txt              # directory brute-force results
                ├── dns.txt               # DNS records (A, MX, TXT, NS, etc.)
                ├── headers.txt           # HTTP response headers
                ├── nmap.txt              # port scan and service versions
                ├── sslscan.txt           # SSL/TLS cipher and certificate analysis
                ├── testssl.txt           # SSL/TLS vulnerability check
                ├── wafw00f.txt           # WAF detection results
                ├── whatweb.txt           # tech stack fingerprinting
                └── whois.txt             # domain registration info
```
