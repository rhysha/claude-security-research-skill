#!/bin/bash
# setup_engagement.sh
# Creates the engagement directory structure for a new security assessment target
# Usage: ./setup_engagement.sh <target_domain_or_ip>

TARGET=${1:-"unknown-target"}
DATE=$(date +%Y%m%d)
DIR="engagement-${TARGET}-${DATE}"

mkdir -p "$DIR"/{recon,vulnscan,apitesting/sqlmap,authtest,requests,report}

cat > "$DIR/scope.txt" << EOF
# Engagement Scope - $TARGET - $DATE
# Fill in before starting

TARGET_IP:
TARGET_DOMAIN:
TARGET_URL:
IN_SCOPE:
OUT_OF_SCOPE:
AUTHORIZATION: [URL/doc]
RATE_LIMIT_CONSTRAINTS:
REPORTING_TO:
START_DATE: $DATE
END_DATE:
EOF

cat > "$DIR/commands.log" << EOF
# Command Log - $TARGET - $DATE
# Paste every command run during engagement
# Format: [TIMESTAMP] PHASE COMMAND

EOF

echo "[+] Engagement directory created: $DIR"
echo "[+] Fill in $DIR/scope.txt before running any tools"
echo "[+] Log all commands to $DIR/commands.log"
