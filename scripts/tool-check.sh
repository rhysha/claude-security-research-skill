#!/bin/bash
# tool-check.sh — Verify all required security research tools are available
# Run at start of any engagement

TOOLS=(nmap nikto nuclei subfinder whatweb ffuf sqlmap dalfox hydra trufflehog)
OPTIONAL=(wafw00f amass httpx waybackurls wpscan testssl.sh jwt_tool hashcat cewl git-dumper)

echo "=== Required Tools ==="
MISSING=0
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" &>/dev/null; then
    VERSION=$(($tool --version 2>/dev/null || $tool -V 2>/dev/null || echo "installed") | head -1)
    echo "  OK  $tool — $VERSION"
  else
    echo "  !! MISSING $tool"
    MISSING=$((MISSING+1))
  fi
done

echo ""
echo "=== Optional Tools ==="
for tool in "${OPTIONAL[@]}"; do
  if command -v "$tool" &>/dev/null; then
    echo "  OK  $tool"
  else
    echo "  --  $tool (not installed)"
  fi
done

echo ""
if [ $MISSING -gt 0 ]; then
  echo "WARNING: $MISSING required tools missing. Affected phases:"
  command -v nmap &>/dev/null || echo "  - Enumeration (nmap)"
  command -v nikto &>/dev/null || echo "  - Vuln scanning (nikto)"
  command -v nuclei &>/dev/null || echo "  - Vuln scanning (nuclei)"
  command -v subfinder &>/dev/null || echo "  - Recon (subfinder)"
  command -v ffuf &>/dev/null || echo "  - API fuzzing (ffuf)"
  command -v sqlmap &>/dev/null || echo "  - SQL injection (sqlmap)"
  command -v dalfox &>/dev/null || echo "  - XSS scanning (dalfox)"
  command -v hydra &>/dev/null || echo "  - Auth brute force (hydra)"
  command -v trufflehog &>/dev/null || echo "  - Secrets scanning (trufflehog)"
else
  echo "All required tools present. Ready to engage."
fi
