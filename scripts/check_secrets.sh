#!/bin/bash
# Check for secrets in staged files before push

set -e

echo "🔍 Checking for secrets in staged files..."

# Patterns to detect actual secret values (not variable names)
PATTERNS=(
    "eyJ[A-Za-z0-9_-]{100,}"               # JWT tokens (Supabase service role keys)
    "sbp_[a-zA-Z0-9]{32,}"                 # Supabase project tokens
    "sk_live_[a-zA-Z0-9]{24,}"             # Stripe live key
    "sk_test_[a-zA-Z0-9]{24,}"             # Stripe test key
    "EAA[a-zA-Z0-9]{100,}"                 # Meta access tokens (start with EAA)
    "pat_[a-zA-Z0-9]{40,}"                  # Airtable personal access tokens
)

# Patterns for secret assignments (KEY=value or KEY: value)
SECRET_ASSIGNMENT_PATTERNS=(
    "META_ACCESS_TOKEN\\s*[=:][^\\s]*[A-Za-z0-9]{20,}"  # Meta access token assignment
    "META_WABA_PHONE_NUMBER_ID\\s*[=:][^\\s]*[0-9]{10,}" # WhatsApp phone number ID
    "WHATSAPP_VERIFY_TOKEN\\s*[=:][^\\s]*[A-Za-z0-9]{10,}" # Verify token assignment
    "AIRTABLE_API_KEY\\s*[=:][^\\s]*[A-Za-z0-9]{20,}"    # Airtable API key assignment
    "AIRTABLE_BASE_ID\\s*[=:][^\\s]*[A-Za-z0-9]{10,}"   # Airtable base ID assignment
)

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No staged files to check"
    exit 0
fi

FOUND_SECRETS=false

for file in $STAGED_FILES; do
    # Skip .env files and the check_secrets.sh script itself
    if [[ "$file" == *".env"* ]] || [[ "$file" == *".gitignore"* ]] || [[ "$file" == *"check_secrets.sh"* ]]; then
        continue
    fi
    
    # Check for actual secret values
    for pattern in "${PATTERNS[@]}"; do
        if git diff --cached "$file" | grep -qiE "$pattern"; then
            echo "❌ SECRET DETECTED in $file:"
            echo "   Pattern: $pattern"
            FOUND_SECRETS=true
        fi
    done
    
    # Check for secret assignments (KEY=value)
    for pattern in "${SECRET_ASSIGNMENT_PATTERNS[@]}"; do
        if git diff --cached "$file" | grep -qiE "$pattern"; then
            echo "❌ SECRET ASSIGNMENT DETECTED in $file:"
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

