# Contributing to Claude Security Research Skill

Thanks for helping make this better. Here's how to contribute effectively.

---

## What We're Looking For

**High priority:**
- New reference files: cloud security research (AWS/GCP/Azure), mobile (Android/iOS), thick client, IoT
- Additional tool integrations with chaining examples
- Improved or expanded reporting templates
- Platform-specific install guides (macOS, Kali, Parrot, Docker)

**Always welcome:**
- Bug fixes in scripts
- Better tool command examples
- Updated CVE/technique references

---

## Reference File Format

New reference files in `references/` should follow this structure:

```markdown
# [Phase] Reference

## Goal
One sentence: what this phase achieves.

---

## Tool Name — Purpose

### Sub-task
```bash
# Brief comment explaining why
command --flags $VARIABLE
```

---

## Key Findings to Flag
- What to look for
- What it means
```

Rules:
- Use shell variables (`$TARGET`, `$DOMAIN`, `$PORT`) — never hardcode
- Include output file paths matching the engagement directory structure
- Rate-limit by default; note when a flag increases aggression
- Note when a tool requires root or specific permissions

---

## Submitting

1. Fork the repo
2. Create a branch: `git checkout -b add-cloud-security-research-references`
3. Make your changes
4. Test your scripts if applicable
5. Open a PR with a clear description of what you added and why

---

## Ethics Requirement

All contributions must be usable only within the ethics gate defined in `SKILL.md`:
- Techniques must require authorization to use legally
- No contributions that bypass the scope/authorization checks
- No default-aggressive settings (must be opt-in)

PRs that weaken the ethics gate will not be merged.
