# Security Assessment Report — demo.example.com

> **This is a fictional sample report for demonstration purposes.**
> All hosts, IPs, credentials, and findings are invented to illustrate the
> output format Claude produces with the security-research skill. No real
> systems were tested.

---

## Engagement Metadata

| Field             | Value                                                       |
|-------------------|-------------------------------------------------------------|
| **Engagement**    | demo.example.com — Web application + API                   |
| **Date**          | 2026-04-08 → 2026-04-09                                     |
| **Researcher**    | Alex R. (security-research skill, Claude Code)              |
| **Authorization** | Written authorization on file (ENG-2026-04-DEMO)            |
| **Scope (in)**    | demo.example.com, api.demo.example.com, *.demo.example.com  |
| **Scope (out)**   | billing.example.com, third-party SaaS integrations          |
| **Methodology**   | Phased engagement: recon → enum → vuln scan → validation    |
| **Tools used**    | nmap, nuclei, nikto, ffuf, sqlmap, dalfox, trufflehog       |

### Finding Summary

| Severity  | Count |
|-----------|-------|
| CRITICAL  | 1     |
| HIGH      | 1     |
| MEDIUM    | 1     |
| LOW       | 1     |
| INFO      | 1     |
| **Total** | **5** |

---

## Findings

### [CRITICAL] Unauthenticated SQL Injection in `/api/v1/users` Lookup

**Target:** https://api.demo.example.com/v1/users?id=1
**Tool:** sqlmap (validation), nuclei `cve/2023-*` template (initial detection)
**CVSS:** 9.8 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H)
**CWE:** CWE-89 — Improper Neutralization of Special Elements used in an SQL Command
**OWASP:** A03:2021 — Injection

#### Description
The `id` parameter on the unauthenticated endpoint `GET /api/v1/users?id=` is
concatenated directly into a backend SQL query. sqlmap confirmed boolean-based
blind, time-based blind, and UNION-based injection techniques against a MySQL
8.0.34 backend. The endpoint requires no authentication and no rate limiting
is enforced.

#### Evidence
```
$ sqlmap -u "https://api.demo.example.com/v1/users?id=1" --batch --level=3 --risk=2

[INFO] testing connection to the target URL
[INFO] heuristics detected web page charset 'ascii'
[INFO] target URL appears to be UNION injectable with 5 columns
---
Parameter: id (GET)
    Type: boolean-based blind
    Title: AND boolean-based blind - WHERE or HAVING clause
    Payload: id=1 AND 4811=4811

    Type: time-based blind
    Title: MySQL >= 5.0.12 AND time-based blind (query SLEEP)
    Payload: id=1 AND (SELECT 4892 FROM (SELECT(SLEEP(5)))xWnP)

    Type: UNION query
    Title: Generic UNION query (NULL) - 5 columns
    Payload: id=-3422 UNION ALL SELECT NULL,NULL,CONCAT(0x71...),NULL,NULL--
---
[INFO] the back-end DBMS is MySQL
web server operating system: Linux Ubuntu 22.04
back-end DBMS: MySQL >= 8.0.34
available databases [4]:
[*] information_schema
[*] mysql
[*] performance_schema
[*] webapp_prod
```

#### Impact
A threat actor could exfiltrate the entire `webapp_prod` database — including
user records, password hashes, and PII — without authentication. Depending on
the database user's privileges, this may also allow writes via `INTO OUTFILE`
or stored procedure abuse, leading to remote code execution on the database
host.

#### Remediation
- Replace string concatenation with parameterized queries / prepared statements
  in the user lookup handler (`api/handlers/users.py:42`)
- Enforce a strict integer validator on the `id` parameter at the framework layer
- Run the database connection under a least-privilege account that lacks
  `FILE` and `SUPER` privileges
- Deploy a WAF rule for SQLi patterns as defense-in-depth (not a primary fix)
- Add logging and alerting on repeated 5xx responses from this endpoint

#### References
- https://owasp.org/www-community/attacks/SQL_Injection
- https://cwe.mitre.org/data/definitions/89.html
- https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

### [HIGH] Exposed `.git/` Directory on Production Web Root

**Target:** https://demo.example.com/.git/
**Tool:** nikto, nuclei `exposures/configs/git-config.yaml`
**CVSS:** 7.5 (AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N)
**CWE:** CWE-538 — Insertion of Sensitive Information into Externally-Accessible File
**OWASP:** A05:2021 — Security Misconfiguration

#### Description
The `.git/` directory is served by the web server at the document root.
nuclei flagged `/.git/config`, `/.git/HEAD`, and `/.git/index` as accessible.
A full repository reconstruction is possible using `git-dumper` or similar
tools, exposing source code, commit history, and any secrets that have been
committed.

#### Evidence
```
$ nuclei -u https://demo.example.com -tags exposure,git
[git-config] [http] [medium] https://demo.example.com/.git/config
[git-head]   [http] [medium] https://demo.example.com/.git/HEAD
[git-index]  [http] [medium] https://demo.example.com/.git/index

$ curl -sI https://demo.example.com/.git/config
HTTP/1.1 200 OK
Server: nginx/1.24.0
Content-Type: text/plain
Content-Length: 158

$ curl -s https://demo.example.com/.git/config
[core]
    repositoryformatversion = 0
    filemode = true
[remote "origin"]
    url = git@github.com:example-corp/demo-frontend.git
```

```
$ nikto -h https://demo.example.com -Tuning 2
+ /.git/HEAD: Git HEAD file found, may expose repo information.
+ /.git/config: Git config file found, may expose repository details.
```

#### Impact
The full source code of the production frontend can be reconstructed,
exposing the upstream GitHub repository name, branch structure, and any
historical commits. If secrets (API keys, JWT signing keys, database
credentials) were ever committed and not rotated, they are now disclosed.

#### Remediation
- Block access to `.git/` at the nginx layer:
  ```nginx
  location ~ /\.git(/|$) { deny all; return 404; }
  ```
- Audit the upstream repository for any historically committed secrets and
  rotate anything that was exposed
- Add a deploy-time check that verifies `.git/` is not present in build artifacts

#### References
- https://owasp.org/www-community/vulnerabilities/Insecure_Direct_Object_References
- https://cwe.mitre.org/data/definitions/538.html

---

### [MEDIUM] Missing Security Headers on Application Responses

**Target:** https://demo.example.com/
**Tool:** nikto, manual `curl -sI`
**CVSS:** 5.3 (AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:L/A:N)
**CWE:** CWE-693 — Protection Mechanism Failure
**OWASP:** A05:2021 — Security Misconfiguration

#### Description
The main application response is missing several recommended security headers.
nikto flagged the absence of `Strict-Transport-Security`,
`Content-Security-Policy`, `X-Content-Type-Options`, and `Referrer-Policy`.
The `X-Frame-Options` header is also absent, leaving the site vulnerable to
clickjacking via iframe embedding.

#### Evidence
```
$ curl -sI https://demo.example.com/
HTTP/1.1 200 OK
Server: nginx/1.24.0
Date: Wed, 08 Apr 2026 14:22:11 GMT
Content-Type: text/html; charset=UTF-8
Content-Length: 14728
Connection: keep-alive
Set-Cookie: session=abc123; Path=/

$ nikto -h https://demo.example.com
+ The anti-clickjacking X-Frame-Options header is not present.
+ The X-Content-Type-Options header is not set.
+ Strict-Transport-Security header missing.
+ Content-Security-Policy header missing.
```

#### Impact
- **No HSTS** → users can be downgraded to HTTP via SSL stripping
- **No CSP** → reflected/stored XSS findings have no in-browser mitigation
- **No X-Frame-Options** → clickjacking is possible against authenticated views
- **No X-Content-Type-Options** → MIME sniffing may execute uploaded files

#### Remediation
Add the following headers at the nginx layer:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; object-src 'none'" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```
Validate the resulting CSP against the application's actual asset origins
before enabling enforcement.

#### References
- https://owasp.org/www-project-secure-headers/
- https://cwe.mitre.org/data/definitions/693.html

---

### [LOW] Verbose Server Banner Discloses nginx Version

**Target:** https://demo.example.com/
**Tool:** nmap `-sV`, manual `curl -sI`
**CVSS:** 3.1 (AV:N/AC:H/PR:N/UI:N/S:U/C:L/I:N/A:N)
**CWE:** CWE-200 — Exposure of Sensitive Information to an Unauthorized Actor
**OWASP:** A05:2021 — Security Misconfiguration

#### Description
The web server returns the full nginx version string in the `Server` response
header. nmap service detection corroborated this with `nginx 1.24.0`. While
not directly exploitable, version disclosure simplifies the work of identifying
applicable CVEs for an unauthenticated attacker.

#### Evidence
```
$ nmap -sV -p 443 demo.example.com
PORT    STATE SERVICE  VERSION
443/tcp open  ssl/http nginx 1.24.0
Service Info: OS: Linux

$ curl -sI https://demo.example.com/ | grep Server
Server: nginx/1.24.0
```

#### Impact
Version disclosure does not directly compromise the server, but it lowers
the cost of reconnaissance and lets a threat actor narrow CVE searches to
the exact installed version.

#### Remediation
Set `server_tokens off;` in the nginx `http {}` block and reload the service.
Optionally, override the `Server` header entirely using the `headers-more-nginx`
module.

#### References
- https://cwe.mitre.org/data/definitions/200.html
- https://nginx.org/en/docs/http/ngx_http_core_module.html#server_tokens

---

### [INFO] Three Subdomains Identified via Certificate Transparency

**Target:** *.demo.example.com
**Tool:** subfinder, crt.sh
**CVSS:** N/A
**CWE:** N/A
**OWASP:** N/A — Recon finding

#### Description
Passive recon via subfinder and certificate transparency logs identified three
subdomains beyond the in-scope hosts. These are recorded for awareness; none
were tested as part of this engagement because they fall outside the
authorized scope.

#### Evidence
```
$ subfinder -d demo.example.com -silent
api.demo.example.com
demo.example.com
internal-tools.demo.example.com
staging.demo.example.com
metrics.demo.example.com

$ curl -s "https://crt.sh/?q=%25.demo.example.com&output=json" | jq -r '.[].name_value' | sort -u
api.demo.example.com
demo.example.com
internal-tools.demo.example.com
metrics.demo.example.com
staging.demo.example.com
```

#### Impact
Informational only. The presence of `internal-tools.demo.example.com` and
`metrics.demo.example.com` in public certificate transparency logs suggests
internal-facing services that may not be intended for public discovery.
The asset owner may want to review whether these hostnames should be
issued from a private CA instead.

#### Remediation
- Review whether `internal-tools` and `metrics` subdomains should be reachable
  from the public internet or moved behind a VPN
- Consider issuing certificates for internal services from a private CA so
  they do not appear in public CT logs
- Add these hostnames to a future engagement scope if testing is desired

#### References
- https://crt.sh/
- https://datatracker.ietf.org/doc/html/rfc6962

---

## Remediation Priority

Address findings in the order below. Critical and high items should be fixed
before this report is shared beyond the engineering team.

| Priority | Severity | Finding                                          | Effort | Owner          |
|----------|----------|--------------------------------------------------|--------|----------------|
| **P0**   | CRITICAL | SQL injection in `/api/v1/users` lookup          | Medium | Backend team   |
| **P1**   | HIGH     | Exposed `.git/` directory on production          | Low    | Platform team  |
| **P2**   | MEDIUM   | Missing security headers                         | Low    | Platform team  |
| **P3**   | LOW      | nginx version disclosure in `Server` header      | Trivial| Platform team  |
| **P4**   | INFO     | Internal subdomains in CT logs (review only)     | N/A    | Security lead  |

### Suggested Timeline
- **P0**: Patch within 24 hours; coordinate database credential rotation
- **P1**: Patch within 72 hours; rotate any historically committed secrets
- **P2**: Include in the next deploy
- **P3**: Include in the next deploy
- **P4**: Discuss in the next architecture review

---

## Methodology Notes

This engagement followed the phased workflow defined in `SKILL.md`:

1. **Recon** — passive subdomain enumeration via subfinder + crt.sh; whatweb
   for tech fingerprinting
2. **Enumeration** — nmap full TCP scan plus `-sV -sC` on open ports; testssl
   for TLS audit
3. **Vuln scanning** — nikto and nuclei (`-severity high,critical` and
   `-tags exposure,cve,misconfig`) against in-scope hosts
4. **Vulnerability validation** — sqlmap to confirm the suspected SQLi flagged
   by nuclei; manual `curl` to validate `.git/` exposure and missing headers
5. **Reporting** — findings written into the structured format above

Claude's role across all phases was to interpret tool output, suggest the
next tool to run, and assemble findings. Tools performed all active testing.

---

*Generated by the [Claude Security Research Skill](https://github.com/rhysha/claude-security-research-skill).*
