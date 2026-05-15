#!/bin/bash
# =============================================================================
# Web Audit Scanner — tool runner and log manager.
# This script is mounted into the container at /app/tools/scanner.sh and is the
# single entry point for all scans. The container installs security tools at
# startup; this script invokes them, collects output, and writes timestamped
# logs under volume_mounts/app/logs/.
#
# Each section below is commented — you can read through it in under a minute
# and verify that nothing harmful is happening.
# =============================================================================

# Allow the container user (non-root) to read/write output files.
umask 000

# --- Argument parsing --------------------------------------------------------
# First positional arg or the TARGET_URL env var becomes the scan target.
TARGET="${1:-$TARGET_URL}"
if [ -z "$TARGET" ]; then
    echo "Usage: TARGET_URL=https://example.com ./scanner.sh"
    exit 1
fi

# Strip protocol to get a bare hostname (some tools need host, others need URL).
HOST=$(echo "$TARGET" | sed -E 's|^https?://||' | cut -d/ -f1)

# Timestamp in Brazil timezone, used to name the log directory.
TIMESTAMP=$(TZ='<-03>3' date +%H%M%S_%d%m%y)

# --- Output directories ------------------------------------------------------
OUTDIR="/app/logs/${HOST}_${TIMESTAMP}"
INDIR="$OUTDIR/individual_logs"
mkdir -p "$INDIR"

# --- Tool/exclusion selection -------------------------------------------------
# Walk extra arguments: flags starting with "-" are exclusions, URLs are
# ignored (already captured as TARGET), anything else is a single-tool name.
TOOL="all"
EXCLUDE=""
for arg in "$@"; do
    case "$arg" in
        -* ) EXCLUDE="$EXCLUDE$arg" ;;
        https://*|http://* ) : ;;
        * ) TOOL="$arg" ;;
    esac
done

# --- Individual tool runners --------------------------------------------------
# Each function runs one security tool and writes its output to a dedicated log
# file under individual_logs/.  "|| true" ensures a failing tool doesn't abort
# the full scan.
run_whois()  { whois "$HOST" > "$INDIR/whois.txt" 2>&1; }
run_dig()    { dig ANY "$HOST" > "$INDIR/dns.txt" 2>&1; }
run_nmap()   { nmap -sV --script=http-headers "$HOST" > "$INDIR/nmap.txt" 2>&1; }
run_whatweb() { whatweb "$TARGET" > "$INDIR/whatweb.txt" 2>&1; }
run_sslscan() { sslscan "$HOST" > "$INDIR/sslscan.txt" 2>&1; }
run_dirb()   { dirb "$TARGET" /usr/share/dirb/wordlists/common.txt -o "$INDIR/dirb.txt" 2>&1; }
run_wafw00f() { wafw00f "$TARGET" > "$INDIR/wafw00f.txt" 2>&1; }
run_curl()   { curl -sI "$TARGET" > "$INDIR/headers.txt" 2>&1; }
run_testssl() { testssl --quiet "$TARGET" > "$INDIR/testssl.txt" 2>&1; }
run_crawl()  { wget --spider -r -l 3 -nd "$TARGET" > "$INDIR/crawl.txt" 2>&1; }

# --- Full scan (all tools, respecting exclusions) -----------------------------
run_all() {
    echo "$EXCLUDE" | grep -qv "whois"  && { echo "[whois+dns]"  && run_whois || true && run_dig || true; }
    echo "$EXCLUDE" | grep -qv "nmap"   && { echo "[nmap]"       && run_nmap || true; }
    echo "$EXCLUDE" | grep -qv "whatweb" && { echo "[whatweb]"    && run_whatweb || true; }
    echo "$EXCLUDE" | grep -qv "sslscan" && { echo "[sslscan]"    && run_sslscan || true; }
    echo "$EXCLUDE" | grep -qv "dirb"   && { echo "[dirb]"       && run_dirb || true; }
    echo "$EXCLUDE" | grep -qv "wafw00f" && { echo "[wafw00f]"    && run_wafw00f || true; }
    echo "$EXCLUDE" | grep -qv "crawl"  && { echo "[crawl]"       && run_crawl || true; }
    echo "$EXCLUDE" | grep -qv "headers" && { echo "[headers+ssl]" && run_curl || true && run_testssl || true; }
}

# --- Dispatch -----------------------------------------------------------------
echo "=== Scanning $TARGET ==="
echo "Output dir: $OUTDIR"

case "$TOOL" in
    whois)   run_whois ;;
    dig)     run_dig ;;
    nmap)    run_nmap ;;
    whatweb) run_whatweb ;;
    sslscan) run_sslscan ;;
    dirb)    run_dirb ;;
    wafw00f) run_wafw00f ;;
    headers) run_curl ;;
    crawl)   run_crawl ;;
    testssl) run_testssl ;;
    all)     run_all ;;
    *)       echo "Unknown tool: $TOOL"; echo "Available: whois dig nmap whatweb sslscan dirb wafw00f headers testssl crawl all"; exit 1 ;;
esac

# --- Combine individual logs into a single report -----------------------------
COMBINED="$OUTDIR/combined_log.txt"
for f in "$INDIR"/*; do
    echo "====================" >> "$COMBINED"
    echo "  $(basename "$f")" >> "$COMBINED"
    echo "====================" >> "$COMBINED"
    cat "$f" >> "$COMBINED"
    echo "" >> "$COMBINED"
done

echo ""

# Ensure the host user can read/write/delete output files regardless of uid.
chmod -R a+rwX "$OUTDIR"

echo "=== Scan complete ==="
echo "Individual logs: $INDIR"
echo "Combined report: $COMBINED"
