# Recon Reference

## Goal
Map the assessment surface before touching the target. Passive first, active second.

---

## Phase 1A: Passive Recon (no direct target contact)

### Subdomain Enumeration
```bash
# subfinder — passive, fast
subfinder -d $DOMAIN -o ./recon/subdomains.txt -v

# Combine with amass for broader coverage
amass enum -passive -d $DOMAIN -o ./recon/amass-subdomains.txt
cat ./recon/subdomains.txt ./recon/amass-subdomains.txt | sort -u > ./recon/all-subdomains.txt
```

### DNS Intelligence
```bash
# Resolve live subdomains
cat ./recon/all-subdomains.txt | httpx -silent -o ./recon/live-hosts.txt

# MX, TXT, NS records (reveals email providers, SPF, DKIM, cloud providers)
dig $DOMAIN MX TXT NS ANY +short
```

### Certificate Transparency
```bash
# Free, no auth needed
curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" | jq '.[].name_value' | sort -u
```

### WHOIS + ASN
```bash
whois $DOMAIN
# Find IP ranges owned by the org
whois -h whois.radb.net -- "-i origin $(whois $IP | grep -i 'origin:' | awk '{print $2}')"
```

---

## Phase 1B: Active Recon (direct contact — ensure authorization)

### Web Tech Fingerprinting
```bash
# whatweb — identifies CMS, frameworks, server, WAF hints
whatweb -a 3 $TARGET -v 2>&1 | tee ./recon/whatweb.txt

# wappalyzer CLI alternative
npx wappalyzer $TARGET
```

### WAF Detection
```bash
wafw00f $TARGET
# If WAF detected: adjust scanner aggression, use evasion flags in tools below
```

### URL/Path Discovery (passive sources)
```bash
# Pull known URLs from wayback machine
waybackurls $DOMAIN | tee ./recon/wayback-urls.txt

# Extract parameters from known URLs (useful candidates for injection testing)
cat ./recon/wayback-urls.txt | grep "?" | qsreplace FUZZ > ./recon/param-urls.txt
```

---

## Recon Chaining

Feed recon output into enumeration:
```bash
# Pass live hosts to nmap (enumeration phase)
cat ./recon/live-hosts.txt > ./enum/targets.txt

# Pass param URLs to ffuf/dalfox (api-testing phase)
cat ./recon/param-urls.txt > ./api/fuzz-targets.txt
```

---

## Key Findings to Flag

- Subdomains pointing to unclaimed cloud resources (subdomain takeover candidates)
- Dev/staging/internal subdomains exposed externally
- Leaked internal hostnames in TLS certificates
- Mismatched SPF/DMARC → email spoofing possible
- Third-party services identified (expand assessment surface)
