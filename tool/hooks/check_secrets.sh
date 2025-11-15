#!/usr/bin/env bash

# Prevent committing sensitive credentials or plaintext env files.
# This script scans staged changes (git diff --cached) for high-risk tokens.

set -euo pipefail

TMP_DIFF="$(mktemp)"
trap 'rm -f "$TMP_DIFF"' EXIT

git diff --cached --text > "$TMP_DIFF"

if [[ ! -s "$TMP_DIFF" ]]; then
  exit 0
fi

# Common secret patterns
PATTERNS=(
  "SENDGRID_API_KEY"
  "STRIPE_SECRET"
  "STRIPE_WEBHOOK"
  "firebaseConfig"
  "AIza[0-9A-Za-z_-]{35}"
  "sk_live_[0-9A-Za-z]{20,}"
  "-----BEGIN PRIVATE KEY-----"
  "appspot.com"
  "ACCESS_KEY_ID"
  "SECRET_ACCESS_KEY"
)

REGEX=$(IFS='|'; echo "${PATTERNS[*]}")

if grep -E "$REGEX" "$TMP_DIFF" >/dev/null 2>&1; then
  cat <<'EOF'
❌ Potential secret detected in staged changes.
Please remove the credential, use env_vault.mjs for encrypted storage,
or mask the value before committing.

If this is a false positive, consider updating tool/hooks/check_secrets.sh
with a narrower pattern.
EOF
  exit 1
fi

# Block committing decrypted environment files inadvertently
if git diff --cached --name-only | grep -E '^(\.env|.*\.env\.local|env\.secrets\.json)$' >/dev/null 2>&1; then
  cat <<'EOF'
❌ Plaintext environment file detected in staged changes.
Encrypt secrets using node tool/env_vault.mjs and commit only the encrypted payload.
EOF
  exit 1
fi

exit 0

