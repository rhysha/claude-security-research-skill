# Product Hunt Launch Copy

Use this as your tagline, description, and first comment when launching.

---

## Tagline (60 chars max)

```
Full-spectrum security research workflows built into Claude
```

Alternative options:
```
Claude as your security research co-pilot — structured, scoped, tool-driven
AI-assisted security assessments: recon to report, in one skill
```

---

## Description (~300 words)

**Claude Security Research Skill** gives Claude Code a structured, professional security research workflow — not ad-hoc command generation.

Drop this skill into Claude and your AI assistant becomes a security research co-pilot that knows *exactly* what to do at each phase: passive recon before active enumeration, rate-limited scans by default, proper tool chaining, and professional findings reports.

Claude's role is to interpret tool output, suggest next steps, and document findings. Tools perform the active testing. Claude does not generate payloads or exploit code.

**What it covers:**
- 🔍 **Recon** — subfinder, amass, httpx, cert transparency, WHOIS/ASN
- 🗺️ **Enumeration** — nmap full TCP/UDP, SSL/TLS audit, service fingerprinting
- 🔬 **Vuln scanning** — nikto, nuclei, OWASP ZAP, WAF detection
- 💉 **Vulnerability validation** — ffuf, sqlmap, dalfox, JWT testing
- 🔑 **Secrets audit** — trufflehog, credential strength testing with hydra
- 📄 **Reporting** — structured findings with severity, impact, and remediation

**What makes it different from just asking Claude to run a security assessment:**
Claude without a skill makes up commands and skips phases. With this skill, it follows a real engagement workflow — asking for scope first, routing to the right tools for your target type, chaining outputs between phases, and flagging what needs manual verification.

Built for security researchers, security engineers, and bug bounty hunters who want AI to handle the logistics while they focus on the findings.

Ethics gate built in — Claude confirms written authorization before touching anything, and refuses to write payloads or exploit code.

**Free and open source. MIT licensed.**

---

## First Comment (maker post)

Hey PH! I built this after getting frustrated with Claude giving me random nmap commands with no structure when I asked it to help with security assessments.

This skill gives Claude a real engagement workflow — the same phases a human security researcher follows, with proper tool chaining and scoped outputs. Claude reads tool output and suggests what to run next; it does not generate payloads or attack code itself.

It's opinionated (ethics gate, rate-limiting by default, no hardcoded creds, tool-driven testing only) but that's the point. I want AI-assisted security research to be structured and professional, not a liability.

Would love feedback from the security community — especially on what reference files to add next (cloud security research, mobile, and thick client are on the roadmap).

---

## Tags

`security` `developer-tools` `open-source` `ai` `claude` `security-research` `cybersecurity`

---

## Topics for GitHub

`security-research` `security` `claude` `ai` `claude-skill` `nmap` `recon` `bug-bounty` `security-assessment`
