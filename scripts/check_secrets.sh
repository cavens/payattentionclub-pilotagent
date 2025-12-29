#!/bin/bash
# Check for secrets in staged files before push

set -e

echo "🔍 Checking for secrets in staged files..."

# Patterns to detect secrets
PATTERNS=(
    "META_ACCESS_TOKEN"                    # Meta/WhatsApp access token
    "META_WABA_PHONE_NUMBER_ID"            # WhatsApp Business Account ID
    "WHATSAPP_VERIFY_TOKEN"                # WhatsApp webhook verify token
    "eyJ[A-Za-z0-9_-]{100,}"               # JWT tokens (Supabase service role keys)
    "sbp_[a-zA-Z0-9]{32,}"                 # Supabase project tokens
    "AIRTABLE_API_KEY"                     # Airtable API key
    "AIRTABLE_BASE_ID"                     # Airtable base ID
    "sk_live_[a-zA-Z0-9]{24,}"             # Stripe live key (if used)
    "sk_test_[a-zA-Z0-9]{24,}"             # Stripe test key (if used)
)

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No staged files to check"
    exit 0
fi

FOUND_SECRETS=false

for file in $STAGED_FILES; do
    # Skip .env files (they're gitignored anyway)
    if [[ "$file" == *".env"* ]] || [[ "$file" == *".gitignore"* ]]; then
        continue
    fi
    
    for pattern in "${PATTERNS[@]}"; do
        if git diff --cached "$file" | grep -qiE "$pattern"; then
            echo "❌ SECRET DETECTED in $file:"
            echo "   Pattern: $pattern"
            FOUND_SECRETS=true
        fi
    done
done

if [ "$FOUND_SECRETS" = true ]; then
    echo ""
    echo "🚨 BLOCKED: Secrets detected in staged files!"
    echo "   Remove secrets before pushing to remote."
    echo "   Store secrets in Supabase Vault or .env files (gitignored)."
    exit 1
fi

echo "✅ No secrets detected"
exit 0

