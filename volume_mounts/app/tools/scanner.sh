#!/bin/bash
umask 000
TARGET="${1:-$TARGET_URL}"
if [ -z "$TARGET" ]; then
    echo "Usage: TARGET_URL=https://example.com ./scanner.sh"
    exit 1
fi

# Strip protocol for hostname-based tools
HOST=$(echo "$TARGET" | sed -E 's|^https?://||' | cut -d/ -f1)
TZ=America/Sao_Paulo TIMESTAMP=$(date +%H%M%S_%d%m%y)
OUTDIR="/app/logs/${HOST}_${TIMESTAMP}"
INDIR="$OUTDIR/individual_logs"
mkdir -p "$INDIR"

TOOL="${2:-all}"

run_whois() { whois "$HOST" > "$INDIR/whois.txt" 2>&1; }
run_dig()   { dig ANY "$HOST" > "$INDIR/dns.txt" 2>&1; }
run_nmap()  { nmap -sV --script=http-headers "$HOST" > "$INDIR/nmap.txt" 2>&1; }
run_whatweb() { whatweb "$TARGET" > "$INDIR/whatweb.txt" 2>&1; }
run_sslscan() { sslscan "$HOST" > "$INDIR/sslscan.txt" 2>&1; }
run_dirb()  { dirb "$TARGET" /usr/share/dirb/wordlists/common.txt -o "$INDIR/dirb.txt" 2>&1; }
run_wafw00f() { wafw00f "$TARGET" > "$INDIR/wafw00f.txt" 2>&1; }
run_curl()  { curl -sI "$TARGET" > "$INDIR/headers.txt" 2>&1; }
run_testssl() { testssl --quiet "$TARGET" > "$INDIR/testssl.txt" 2>&1; }

run_all() {
    echo "[whois+dns]"  && run_whois || true && run_dig || true
    echo "[nmap]"       && run_nmap || true
    echo "[whatweb]"    && run_whatweb || true
    echo "[sslscan]"    && run_sslscan || true
    echo "[dirb]"       && run_dirb || true
    echo "[wafw00f]"    && run_wafw00f || true
    echo "[headers+ssl]" && run_curl || true && run_testssl || true
}

echo "=== Scanning $TARGET ==="
echo "Output dir: $OUTDIR"

case "$TOOL" in
    whois)  run_whois ;;
    dig)    run_dig ;;
    nmap)   run_nmap ;;
    whatweb) run_whatweb ;;
    sslscan) run_sslscan ;;
    dirb)   run_dirb ;;
    wafw00f) run_wafw00f ;;
    headers) run_curl ;;
    testssl) run_testssl ;;
    all)    run_all ;;
    *)      echo "Unknown tool: $TOOL"; echo "Available: whois dig nmap whatweb sslscan dirb wafw00f headers testssl all"; exit 1 ;;
esac

COMBINED="$OUTDIR/combined_log.txt"
for f in "$INDIR"/*; do
    echo "====================" >> "$COMBINED"
    echo "  $(basename "$f")" >> "$COMBINED"
    echo "====================" >> "$COMBINED"
    cat "$f" >> "$COMBINED"
    echo "" >> "$COMBINED"
done

echo ""
chmod -R a+rwX "$OUTDIR"

echo "=== Scan complete ==="
echo "Individual logs: $INDIR"
echo "Combined report: $COMBINED"
