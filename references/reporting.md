# Reporting Reference

## Goal
Produce structured, actionable findings. No fluff. Severity-ranked. Dev-ready remediation.

---

## Severity Rating (CVSS-aligned)

| Severity | CVSS Score | Examples                                        |
|----------|------------|-------------------------------------------------|
| CRITICAL | 9.0–10.0   | Unauthenticated RCE, SQLi with data exfil       |
| HIGH     | 7.0–8.9    | Authenticated RCE, IDOR exposing PII, SQLi      |
| MEDIUM   | 4.0–6.9    | Stored XSS, SSRF, broken auth on non-sensitive  |
| LOW      | 1.0–3.9    | Info disclosure, missing headers, verbose errors|
| INFO     | 0          | Recon findings, best-practice notes             |

---

## Finding Template

```markdown
## [SEVERITY] Finding Title

**Target:** https://example.com/api/users?id=1  
**Tool:** sqlmap / manual  
**CVSS:** 9.1 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H)  
**CWE:** CWE-89 — SQL Injection  
**OWASP:** A03:2021 — Injection  

### Description
One paragraph. What the vulnerability is, where it exists, and why the affected
component is vulnerable.

### Evidence
```
Request:
GET /api/users?id=1' OR '1'='1 HTTP/1.1
Host: example.com

Response:
HTTP/1.1 200 OK
[full user table returned]
```

### Impact
What a threat actor could do: exfiltrate the users table, extract password hashes,
potentially achieve OS-level access via xp_cmdshell (MSSQL) or INTO OUTFILE (MySQL).

### Remediation
- Use parameterized queries / prepared statements (not string concatenation)
- Example fix (Python): `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))`
- Deploy a WAF as defense-in-depth (not a primary fix)
- Input validation: reject non-integer values for numeric ID fields

### References
- https://owasp.org/www-community/attacks/SQL_Injection
- https://cwe.mitre.org/data/definitions/89.html
```

---

## Report Automation

### Aggregate All Tool Outputs
```bash
#!/bin/bash
REPORT_DIR="./security-assessment-$(date +%Y%m%d)"
REPORT="$REPORT_DIR/findings-summary.md"

echo "# Security Assessment Report — $(date +%Y-%m-%d)" > $REPORT
echo "**Target:** $TARGET" >> $REPORT
echo "" >> $REPORT

# Nuclei criticals/highs
echo "## Nuclei — Critical/High Findings" >> $REPORT
grep -E "\[critical\]|\[high\]" $REPORT_DIR/vulns/nuclei-all.txt >> $REPORT

# Nikto interesting
echo "## Nikto Findings" >> $REPORT
grep -v "^-\|^\+" $REPORT_DIR/vulns/nikto.txt | grep -v "^$" >> $REPORT

# Secrets
echo "## Secrets Found" >> $REPORT
cat $REPORT_DIR/secrets/trufflehog-*.json | jq -r '.SourceMetadata.Data, .Raw' 2>/dev/null >> $REPORT

echo "Report written to $REPORT"
```

### Finding Count Summary
```bash
echo "=== FINDING SUMMARY ==="
echo "CRITICAL: $(grep -c '\[CRITICAL\]' findings.md)"
echo "HIGH:     $(grep -c '\[HIGH\]' findings.md)"
echo "MEDIUM:   $(grep -c '\[MEDIUM\]' findings.md)"
echo "LOW:      $(grep -c '\[LOW\]' findings.md)"
echo "INFO:     $(grep -c '\[INFO\]' findings.md)"
```

---

## OWASP Top 10 Coverage Checklist

After testing, check off each category:

```
[ ] A01 Broken Access Control   — IDOR, BOLA, privilege escalation tests
[ ] A02 Cryptographic Failures  — TLS audit, weak ciphers, plaintext secrets
[ ] A03 Injection               — SQLi, NoSQLi, command injection, SSTI
[ ] A04 Insecure Design         — Logic flaws, rate limiting, workflow bypass
[ ] A05 Security Misconfiguration — Default creds, exposed admin, verbose errors
[ ] A06 Vulnerable Components   — Nuclei CVE templates, outdated libs
[ ] A07 Auth Failures           — Brute force, weak JWT, session fixation
[ ] A08 Software Integrity      — Unsigned updates, dependency confusion
[ ] A09 Logging Failures        — Test if security events are logged/alerted
[ ] A10 SSRF                    — Internal service access via URL parameters
```

---

## Deliverable Formats

| Audience      | Format                              |
|---------------|-------------------------------------|
| Technical     | Markdown with raw evidence          |
| Management    | Executive summary + finding counts  |
| Dev team      | Per-finding tickets with code fixes |
| Compliance    | CVSS scores + CWE/OWASP mapping     |
