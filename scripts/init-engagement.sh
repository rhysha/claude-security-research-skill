#!/bin/bash
# init-engagement.sh — Set up output directory structure for a new engagement
# Usage: ./init-engagement.sh <target-name>

TARGET_NAME=${1:-"target"}
DATE=$(date +%Y%m%d)
ENGAGEMENT_DIR="./security-assessment-${TARGET_NAME}-${DATE}"

mkdir -p "$ENGAGEMENT_DIR"/{recon,enum,vulns,api,secrets,reports}

cat > "$ENGAGEMENT_DIR/scope.txt" << SCOPE
# Engagement Scope
Date: $(date)
Target Name: $TARGET_NAME

## In Scope
# Add targets here

## Out of Scope
# Add exclusions here

## Authorization
# Evidence of authorization: 
SCOPE

cat > "$ENGAGEMENT_DIR/findings.md" << FINDINGS
# Findings — $TARGET_NAME — $(date +%Y-%m-%d)

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| HIGH     | 0     |
| MEDIUM   | 0     |
| LOW      | 0     |
| INFO     | 0     |

---

## Findings

FINDINGS

echo "Engagement directory created: $ENGAGEMENT_DIR"
echo "Edit scope.txt before starting."
ls -la "$ENGAGEMENT_DIR/"
