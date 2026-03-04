#!/bin/bash

# Create Virtual Keys for NanoClaw Groups
# This script creates separate keys for each group to track usage

# Source configuration from run.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/run.sh" ]; then
    source <(grep '^LITELLM_PORT=' "$SCRIPT_DIR/run.sh")
    source <(grep '^LITELLM_MASTER_KEY=' "$SCRIPT_DIR/run.sh")
fi

# Configuration (can be overridden by environment variables)
LITELLM_PORT="${LITELLM_PORT:-4000}"
LITELLM_URL="${LITELLM_URL:-http://localhost:${LITELLM_PORT}}"
MASTER_KEY="${LITELLM_MASTER_KEY:-sk-admin}"

echo "=========================================="
echo "🔑 Creating Virtual Keys for NanoClaw Groups"
echo "=========================================="
echo ""

# Function to create a virtual key
create_key() {
    local key_alias=$1
    local max_budget=$2
    local description=$3

    echo "Creating key: $key_alias"

    RESPONSE=$(curl -s --location "${LITELLM_URL}/key/generate" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${MASTER_KEY}" \
        --data "{
            \"key_alias\": \"${key_alias}\",
            \"max_budget\": ${max_budget},
            \"duration\": null,
            \"models\": [],
            \"metadata\": {
                \"description\": \"${description}\",
                \"group\": \"${key_alias}\"
            }
        }")

    # Extract the key from response
    KEY=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', 'ERROR'))" 2>/dev/null)

    if [ "$KEY" != "ERROR" ] && [ -n "$KEY" ]; then
        echo "✅ Created: ${key_alias}"
        echo "   Key: ${KEY}"
        echo "   Budget: \$${max_budget}/month"
        echo ""

        # Store for later use
        echo "export ${key_alias^^}_KEY=\"${KEY}\"" >> /tmp/litellm-keys.env
    else
        echo "❌ Failed to create ${key_alias}"
        echo "   Response: $RESPONSE"
        echo ""
    fi
}

# Remove old keys file
rm -f /tmp/litellm-keys.env

# Create keys for each group
create_key "main" 50 "NanoClaw main group - control plane operations"
create_key "dev-team" 100 "NanoClaw dev-team group - complex coding tasks"
create_key "daily-news" 50 "NanoClaw daily-news group - news collection"
create_key "publisher" 30 "NanoClaw publisher group - blog publishing"
create_key "playground" 10 "NanoClaw playground group - testing"

echo "=========================================="
echo "✅ Virtual Keys Created!"
echo "=========================================="
echo ""
echo "Keys saved to: /tmp/litellm-keys.env"
echo ""
echo "Next steps:"
echo "1. Source the keys: source /tmp/litellm-keys.env"
echo "2. Update NanoClaw group .env files with these keys"
echo "3. View usage in UI: http://localhost:4000/ui"
echo ""
