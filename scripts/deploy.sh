#!/bin/bash
# Simple deployment script - Checks secrets, commits, pushes, and optionally deploys Edge Functions
# Usage: ./scripts/deploy.sh [commit-message]
#        ./scripts/deploy.sh "feat: Add new function"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

COMMIT_MESSAGE="${1:-feat: Update code}"

echo "=========================================="
echo "🚀 Deployment Script"
echo "=========================================="
echo ""

# Step 1: Check for secrets
echo "📋 Step 1: Checking for secrets..."
if ! ./scripts/check_secrets.sh; then
    echo "❌ Secrets check failed. Aborting deployment."
    exit 1
fi
echo "✅ Secrets check passed"
echo ""

# Step 2: Stage changes
echo "📋 Step 2: Staging changes..."
git add -A
echo "✅ Changes staged"
echo ""

# Step 3: Commit
echo "📋 Step 3: Committing changes..."
if git diff --staged --quiet; then
    echo "⚠️  No changes to commit"
else
    git commit -m "$COMMIT_MESSAGE"
    echo "✅ Changes committed"
fi
echo ""

# Step 4: Push
echo "📋 Step 4: Pushing to remote..."
git push
echo "✅ Changes pushed to remote"
echo ""

# Step 5: Deploy Edge Functions (optional)
if command -v supabase >/dev/null 2>&1; then
    echo "📋 Step 5: Deploying Edge Functions..."
    
    FUNCTIONS_DIR="$PROJECT_ROOT/supabase/functions"
    if [ -d "$FUNCTIONS_DIR" ]; then
        DEPLOYED_COUNT=0
        FAILED_COUNT=0
        
        # Deploy each edge function
        for func_dir in "$FUNCTIONS_DIR"/*/; do
            if [ -d "$func_dir" ] && [ -f "$func_dir/index.ts" ]; then
                func_name=$(basename "$func_dir")
                echo "  Deploying $func_name..."
                
                if supabase functions deploy "$func_name" 2>&1 | grep -qE "Deployed|deployed|Success"; then
                    echo "    ✅ $func_name deployed"
                    DEPLOYED_COUNT=$((DEPLOYED_COUNT + 1))
                else
                    echo "    ⚠️  $func_name deployment failed or skipped"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                fi
            fi
        done
        
        echo "  Edge Functions: $DEPLOYED_COUNT deployed, $FAILED_COUNT failed/skipped"
    else
        echo "  ⚠️  Functions directory not found: $FUNCTIONS_DIR"
    fi
    echo ""
else
    echo "📋 Step 5: Skipping Edge Functions deployment (Supabase CLI not available)"
    echo "   Install: npm install -g supabase"
    echo ""
fi

echo "=========================================="
echo "✅ Deployment complete!"
echo "=========================================="

