# Enumeration Reference

## Goal
Identify open ports, running services, versions, OS, and tech stack. Feeds all later phases.

---

## Nmap — Core Enumeration

### Quick Sweep (confirm alive hosts)
```bash
nmap -sn $TARGET_RANGE -oG ./enum/alive-hosts.gnmap
grep "Up" ./enum/alive-hosts.gnmap | awk '{print $2}' > ./enum/alive-ips.txt
```

### Full TCP Port Scan
```bash
# Fast full-range scan
nmap -p- --min-rate 5000 -T4 $TARGET -oN ./enum/all-ports.txt

# Then targeted service/version scan on found ports
PORTS=$(grep "^[0-9]" ./enum/all-ports.txt | grep open | cut -d'/' -f1 | tr '\n' ',')
nmap -sV -sC -p $PORTS -O $TARGET -oN ./enum/services.txt -oX ./enum/services.xml
```

### UDP Scan (don't skip — common miss)
```bash
nmap -sU --top-ports 100 $TARGET -oN ./enum/udp-top100.txt
# Focus: 53 (DNS), 161 (SNMP), 500 (IKE/VPN), 1900 (UPnP)
```

### Script-Based Enumeration
```bash
# Run all "safe" category scripts on found services
nmap -sV --script=safe -p $PORTS $TARGET -oN ./enum/nmap-safe-scripts.txt

# Web-specific
nmap --script=http-title,http-server-header,http-methods,http-auth-finder -p 80,443,8080,8443 $TARGET

# SMB
nmap --script=smb-vuln*,smb-enum-shares -p 445 $TARGET

# SSL/TLS
nmap --script=ssl-cert,ssl-enum-ciphers,ssl-dh-params -p 443 $TARGET
```

---

## Service-Specific Enumeration

### HTTP/HTTPS
```bash
# Banner grab + method enumeration
curl -sI $TARGET
curl -X OPTIONS $TARGET -v  # Risky methods exposed: PUT, DELETE, TRACE?

# HTTP security headers audit
curl -sI $TARGET | grep -iE "strict-transport|content-security|x-frame|x-xss|referrer"
```

### SSL/TLS Audit
```bash
# testssl.sh — comprehensive, offline-capable
testssl.sh --severity HIGH $TARGET 2>&1 | tee ./enum/tls-audit.txt

# Check for known weak configs
testssl.sh --protocols --ciphers --headers $TARGET
```

### SNMP (UDP 161)
```bash
snmpwalk -c public -v1 $TARGET
onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt $TARGET
```

### SMB/Samba
```bash
smbclient -L //$TARGET -N
enum4linux -a $TARGET
```

---

## Tech Stack Identification Matrix

| Finding              | Implication                                  |
|----------------------|----------------------------------------------|
| Server: Apache/2.4.x | Check CVEs for specific version              |
| X-Powered-By: PHP/x  | Check PHP CVEs, check phpinfo exposure       |
| WordPress detected   | Run wpscan                                   |
| IIS + .aspx          | Check for Telerik, SharpSerializer vulns     |
| CloudFlare/Akamai    | Origin IP identification needed (Shodan, securitytrails) |
| nginx/1.x.x          | Check for path traversal, alias misconfiguration |

---

## Enumeration → Next Phase Handoff

```bash
# Feed web ports into vuln scanners
grep "80/open\|443/open\|8080/open\|8443/open" ./enum/all-ports.txt | \
  awk '{print $2}' > ./vulns/web-targets.txt

# Feed all IPs into nikto
while read host; do
  nikto -h $host -o ./vulns/nikto-$host.txt &
done < ./vulns/web-targets.txt
```
