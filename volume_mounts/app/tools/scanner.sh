#!/bin/bash
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

echo "=== Scanning $TARGET ==="
echo "Output dir: $OUTDIR"

echo "[1/9] whois + dns lookup..."
whois "$HOST" > "$INDIR/whois.txt" 2>&1 || true
dig ANY "$HOST" > "$INDIR/dns.txt" 2>&1 || true

echo "[2/9] nmap (top 1000 ports)..."
nmap -sV --script=http-headers "$HOST" > "$INDIR/nmap.txt" 2>&1 || true

echo "[3/9] whatweb..."
whatweb "$TARGET" > "$INDIR/whatweb.txt" 2>&1 || true

echo "[4/9] sslscan..."
sslscan "$HOST" > "$INDIR/sslscan.txt" 2>&1 || true

echo "[5/9] nikto..."
nikto -h "$TARGET" -output "$INDIR/nikto.txt" 2>&1 || true

echo "[6/9] dirb (common dirs)..."
dirb "$TARGET" /usr/share/dirb/wordlists/common.txt -o "$INDIR/dirb.txt" 2>&1 || true

echo "[7/9] wafw00f..."
wafw00f "$TARGET" > "$INDIR/wafw00f.txt" 2>&1 || true

echo "[8/9] wapiti..."
wapiti -u "$TARGET" -f txt -o "$INDIR/wapiti" 2>&1 || true

echo "[9/9] headers + SSL info..."
curl -sI "$TARGET" > "$INDIR/headers.txt" 2>&1 || true
testssl.sh --quiet "$TARGET" > "$INDIR/testssl.txt" 2>&1 || true

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
