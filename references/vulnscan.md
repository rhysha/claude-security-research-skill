# Phase 2: Vulnerability Scanning

## Tools: nikto, nuclei, OWASP ZAP

---

## Installation

```bash
# nikto
sudo apt install nikto -y

# nuclei + templates
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
nuclei -update-templates

# ZAP (headless)
# Download: https://www.zaproxy.org/download/
# Or Docker:
docker pull ghcr.io/zaproxy/zaproxy:stable
```

---

## 2.1 — Web Server Scanning (nikto)

### Standard scan
```bash
nikto -h <TARGET_URL> -o ./vulnscan/nikto.txt -Format txt
```

### With output formats + SSL
```bash
nikto -h <TARGET_URL> -ssl -o ./vulnscan/nikto.html -Format html -Tuning x 6 7 8 9
```

### Against multiple targets
```bash
nikto -h ./recon/live_subdomains.txt -o ./vulnscan/nikto_all.html -Format html
```

### Nikto tuning flags (useful combos)
| Flag | Checks |
|------|--------|
| `1` | Interesting files / seen in logs |
| `2` | Misconfiguration / default files |
| `3` | Information disclosure |
| `4` | Injection (XSS/Script) |
| `6` | Denial of Service (careful on prod) |
| `7` | Remote file retrieval (server root) |
| `8` | Command execution / remote shell |
| `9` | SQL injection |
| `x` | Reverse tuning (exclude listed) |

### High-value nikto findings
- Server version disclosure in headers/error pages
- Default files: `/phpinfo.php`, `/.git/`, `/backup/`, `/admin/`, `/wp-admin/`
- Directory indexing enabled
- Outdated SSL/TLS (SSLv3, TLS 1.0)
- HTTP TRACE/TRACK methods enabled (XST test vector)
- Missing security headers

---

## 2.2 — Template-Based Scanning (nuclei)

### Full scan with all templates
```bash
nuclei -u <TARGET_URL> -o ./vulnscan/nuclei.txt -severity critical,high,medium
```

### Targeted by category
```bash
# CVE checks only
nuclei -u <TARGET_URL> -tags cve -o ./vulnscan/nuclei_cves.txt

# Misconfigurations
nuclei -u <TARGET_URL> -tags misconfig -o ./vulnscan/nuclei_misconfig.txt

# Exposed panels (admin, phpmyadmin, jenkins, etc.)
nuclei -u <TARGET_URL> -tags panel -o ./vulnscan/nuclei_panels.txt

# Default credentials
nuclei -u <TARGET_URL> -tags default-login -o ./vulnscan/nuclei_defaultcreds.txt

# Exposed files/paths
nuclei -u <TARGET_URL> -tags exposure,takeover -o ./vulnscan/nuclei_exposure.txt
```

### Scan a list of targets (post-subdomain enum)
```bash
nuclei -l ./recon/live_subdomains.txt -severity critical,high -o ./vulnscan/nuclei_all.txt -c 25
```

### nuclei rate limiting (important for prod targets)
```bash
# Throttle to avoid WAF triggering / DoS
nuclei -u <TARGET_URL> -rate-limit 10 -bulk-size 5 -concurrency 5
```

### Key nuclei template categories
- `cve/` — Known CVEs with PoC
- `misconfiguration/` — CORS, headers, HTTP methods
- `exposures/` — .env, .git, backup files, config leaks
- `default-logins/` — Common default creds across 100+ services
- `takeovers/` — Subdomain takeover fingerprints
- `technologies/` — Version detection with vuln correlation

---

## 2.3 — OWASP ZAP (Automated + Active Scan)

### Baseline passive scan (safe for prod)
```bash
docker run --rm ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t <TARGET_URL> \
  -r ./vulnscan/zap_baseline.html \
  -l WARN
```

### Full active scan (do NOT run on prod without permission)
```bash
docker run --rm -v $(pwd):/zap/wrk ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py \
  -t <TARGET_URL> \
  -r /zap/wrk/vulnscan/zap_full.html \
  -J /zap/wrk/vulnscan/zap_full.json \
  -l WARN \
  -T 60
```

### API-specific ZAP scan (with OpenAPI/Swagger)
```bash
docker run --rm -v $(pwd):/zap/wrk ghcr.io/zaproxy/zaproxy:stable zap-api-scan.py \
  -t <SWAGGER_URL_OR_FILE> \
  -f openapi \
  -r /zap/wrk/vulnscan/zap_api.html
```

### ZAP alert severity levels
- **High**: Actively exploitable (SQLi, XSS, RCE indicators)
- **Medium**: Likely exploitable with conditions (CSRF, CORS, clickjacking)
- **Low**: Defense-in-depth gaps (missing headers, cookie flags)
- **Informational**: Version disclosure, debug info

---

## 2.4 — TLS/SSL Assessment

```bash
# testssl.sh (comprehensive)
./testssl.sh --htmlfile ./vulnscan/tls.html <TARGET_URL>

# sslscan (quick)
sslscan <TARGET>:443 | tee ./vulnscan/sslscan.txt

# nmap TLS scripts
nmap -p 443 --script ssl-enum-ciphers,ssl-cert,ssl-heartbleed,ssl-poodle <TARGET>
```

### Critical TLS findings
- SSLv2/3 or TLS 1.0/1.1 supported → CRITICAL/HIGH
- BEAST, POODLE, HEARTBLEED → CRITICAL
- Weak ciphers (RC4, DES, 3DES, EXPORT) → HIGH
- Expired/self-signed cert → MEDIUM
- Missing HSTS → MEDIUM

---

## Phase 2 Output Checklist

- [ ] nikto scan complete — findings reviewed and severity tagged
- [ ] nuclei run with cve + misconfig + exposure + default-login templates
- [ ] ZAP baseline (minimum) or full scan complete
- [ ] TLS assessment done if HTTPS target
- [ ] All HIGH/CRITICAL findings documented with evidence

**Proceed to**: `api-testing.md` (Phase 3a) and/or `auth-secrets.md` (Phase 3b)
