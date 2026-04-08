# 🔐 Claude Security Research Skill

**A full-spectrum security research skill for Claude** — structured, tool-driven security assessment workflows built directly into your AI assistant.

Drop this skill into [Claude Code](https://claude.ai/code) or any Claude MCP setup and get an AI that thinks like a security researcher: structured phases, proper tool chaining, scoped recon, and professional reporting — not ad-hoc command generation.

Claude's role in this skill is to **interpret tool output, suggest next steps, and document findings**. Tools perform the active testing. Claude does not generate payloads or exploit code.

---

## What It Does

The skill gives Claude a complete engagement workflow across 6 phases:

```
RECON → ENUMERATION → VULN SCANNING → VULNERABILITY VALIDATION → SECRETS AUDIT → REPORTING
```

Claude automatically routes based on your target type, loads the right reference, suggests tools in the right order, and hands off outputs between phases.

### Supported Targets

| Target | Tools Used |
|---|---|
| Web server (Apache / Nginx / IIS) | nmap, nikto, nuclei, testssl |
| REST API | ffuf, sqlmap, dalfox |
| Web application | nikto, nuclei, ZAP, ffuf |
| Network / IP range | nmap, snmpwalk, enum4linux |
| Source code / repo | trufflehog |
| Full engagement | Everything, in phase order |

---

## Quick Start

### 1. Install the skill

**Claude Code (recommended):**
```bash
# Clone into your Claude skills directory
git clone https://github.com/rhysha/claude-security-research-skill ~/.claude/skills/security-research
```

**Manual / MCP:**
Copy `SKILL.md` and the `references/` folder to your Claude skills path.

### 2. Verify your tools
```bash
chmod +x scripts/tool-check.sh
./scripts/tool-check.sh
```

### 3. Start an engagement
```bash
chmod +x scripts/init-engagement.sh
./scripts/init-engagement.sh example.com
```

### 4. Talk to Claude
```
"Run a full security assessment on https://target.example.com — I have written authorization."
"Do passive recon on domain.com — stay passive only."
"Scan this API for OWASP Top 10 issues: https://api.example.com"
"Audit this repo for leaked secrets."
"Analyze these nmap results and suggest next assessment steps."
```

Claude will confirm scope, propose a phase plan, load the right references, and walk through the engagement step by step — pointing you at the tool that should run each check.

---

## Skill Structure

```
├── SKILL.md                    # Core skill definition (loaded by Claude)
├── references/
│   ├── recon.md                # subfinder, amass, httpx, waybackurls
│   ├── enumeration.md          # nmap, testssl, enum4linux, snmpwalk
│   ├── vuln-scanning.md        # nikto, nuclei, OWASP ZAP
│   ├── vulnscan.md             # Supplementary vuln scan patterns
│   ├── api-testing.md          # ffuf, sqlmap, dalfox, JWT testing
│   ├── auth-secrets.md         # hydra, trufflehog, credential auditing
│   └── reporting.md            # Severity ratings, finding templates
├── scripts/
│   ├── tool-check.sh           # Verify all required tools are installed
│   ├── init-engagement.sh      # Create engagement directory structure
│   └── setup_engagement.sh     # Alternative setup with scope template
└── .claude/
    └── settings.local.json     # Claude MCP configuration
```

---

## Required Tools

Claude will tell you which phases are blocked if tools are missing. Install what you need:

```bash
# Core
sudo apt install nmap nikto sqlmap hydra

# Go-based tools
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/hahwul/dalfox/v2@latest

# Secrets
pip install trufflehog

# Passive recon
go install github.com/tomnomnom/waybackurls@latest
```

---

## Ethics Gate

This skill enforces an ethics check **before** any other action:

1. **Written authorization** — you own the target or have explicit permission
2. **Defined scope** — specific targets, not "everything"
3. **Private findings** — no exfiltration of real credentials
4. **Tooling boundary** — Claude will not generate exploit code, payloads, or attack strings. If a step requires this, Claude identifies the appropriate tool and instructs you to run it directly.

Claude will ask for confirmation if any of these are unclear. This is not skippable.

---

## Output Format

Every finding follows a consistent structure:

```
[SEVERITY] Finding Title
  Target:      <url or host>
  Tool:        <tool that found it>
  Evidence:    <raw output or request/response>
  Impact:      <what a threat actor could do>
  Remediation: <specific fix>
  References:  <CVE / OWASP / CWE>
```

Severity scale: `CRITICAL > HIGH > MEDIUM > LOW > INFO`

---

## Who This Is For

- **Security researchers** who want AI-assisted engagement management, not AI guessing at commands
- **Bug bounty hunters** who want structured recon and chained tool workflows
- **Security engineers** running internal assessments
- **CTF participants** working through structured challenges

**Not for beginners** — this assumes you know what the tools do and have legal authorization to use them.

---

## Contributing

PRs welcome for:
- New reference files (cloud security research, mobile, thick clients)
- Additional tool integrations
- Improved reporting templates
- Platform-specific tool install guides

---

## License

MIT — use freely, responsibly, and only against targets you're authorized to test.

---

## Disclaimer

This tool is for authorized security testing only. The authors are not responsible for misuse. Always obtain written permission before testing any system you don't own.
