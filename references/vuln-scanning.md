# Vulnerability Scanning Reference

## Goal
Automated detection of known vulnerabilities, misconfigurations, and OWASP Top 10 issues.

---

## Nikto — Web Server Scanner

```bash
# Basic scan
nikto -h $TARGET -o ./vulns/nikto.txt -Format txt

# With SSL
nikto -h $TARGET -ssl -o ./vulns/nikto-ssl.txt

# Against specific port
nikto -h $TARGET -port 8443 -ssl

# Tuned scan (focus on interesting categories)
# Tuning: 1=interesting, 2=misconfiguration, 4=injection, 8=upload, 9=SQL
nikto -h $TARGET -Tuning 124689 -o ./vulns/nikto-tuned.txt

# Authenticated scan
nikto -h $TARGET -id "admin:password"

# Evasion (WAF bypass testing)
nikto -h $TARGET -evasion 1  # Random URI encoding
```

### What Nikto Finds
- Outdated server software with known CVEs
- Default files and directories (admin panels, phpinfo, .git exposure)
- Dangerous HTTP methods (PUT, DELETE, TRACE)
- Missing security headers
- Directory listing enabled
- Insecure cookie flags

---

## Nuclei — Template-Based Scanner

Nuclei is the most powerful automated scanner. Template library covers thousands of CVEs,
misconfigs, and exposure checks.

```bash
# Update templates first (always)
nuclei -update-templates

# Full scan with all templates
nuclei -u $TARGET -o ./vulns/nuclei-all.txt

# High/Critical only (faster for quick triage)
nuclei -u $TARGET -severity high,critical -o ./vulns/nuclei-critical.txt

# Specific template categories
nuclei -u $TARGET -tags cve,rce,sqli,xss,lfi,ssrf -o ./vulns/nuclei-targeted.txt

# Scan a list of targets
nuclei -l ./vulns/web-targets.txt -severity medium,high,critical -o ./vulns/nuclei-bulk.txt

# Technology-specific templates
nuclei -u $TARGET -tags wordpress,apache,nginx,iis,php,laravel

# With custom rate limiting (avoid detection/throttling)
nuclei -u $TARGET -rate-limit 50 -timeout 10 -retries 2

# With headers (authenticated)
nuclei -u $TARGET -H "Authorization: Bearer $TOKEN" -H "Cookie: session=$COOKIE"
```

### High-Value Template Tags
```
cve           → known CVEs
exposed-panels → admin panels, dashboards
default-logins → unchanged credentials
takeovers     → subdomain takeover
misconfiguration → cloud, server misconfigs
xss, sqli, ssrf, lfi, rce, ssti
```

---

## OWASP ZAP — Automated DAST

### CLI / Daemon Mode (headless)
```bash
# Start ZAP daemon
zap.sh -daemon -host 127.0.0.1 -port 8090 -config api.key=ZAPKEY

# Spider the target
curl "http://localhost:8090/JSON/spider/action/scan/?apikey=ZAPKEY&url=$TARGET"

# Run active scan
curl "http://localhost:8090/JSON/ascan/action/scan/?apikey=ZAPKEY&url=$TARGET"

# Get alerts
curl "http://localhost:8090/JSON/alert/view/alerts/?apikey=ZAPKEY" | jq '.alerts[] | {risk, name, url, description}'
```

### ZAP Baseline Scan (Docker, fastest)
```bash
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t $TARGET \
  -r ./vulns/zap-report.html \
  -l WARN

# Full scan (active)
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t $TARGET \
  -r ./vulns/zap-full-report.html
```

### Authenticated ZAP Scan
```bash
# Use ZAP with a session token
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t $TARGET \
  -r ./vulns/zap-auth-report.html \
  -z "-config replacer.full_list(0).description=auth \
      -config replacer.full_list(0).enabled=true \
      -config replacer.full_list(0).matchtype=REQ_HEADER \
      -config replacer.full_list(0).matchstr=Authorization \
      -config replacer.full_list(0).replacement=Bearer\ $TOKEN"
```

---

## WordPress (wpscan)
```bash
wpscan --url $TARGET --enumerate vp,vt,u --api-token $WPSCAN_TOKEN -o ./vulns/wpscan.txt
# vp=vulnerable plugins, vt=vulnerable themes, u=users
```

---

## Triage Priority

After scanning, sort findings:
```bash
# Pull criticals from nuclei output
grep -i "critical\|high" ./vulns/nuclei-all.txt | sort -u

# ZAP: filter High risk alerts only
cat ./vulns/zap-report.html | grep -A5 "High"
```

Verify top findings manually before including in report — automated scanners have
false positive rates of 20-40% depending on the tool and target.
