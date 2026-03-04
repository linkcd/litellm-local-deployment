#!/bin/bash

# ============================================
# CONFIGURATION
# ============================================
# AWS Bedrock Configuration
AWS_REGION_NAME="us-east-1"
BEDROCK_API_KEY="ABSK...."  # Replace with your actual Bedrock API key

# LiteLLM Authentication
# LITELLM_MASTER_KEY: API key for authenticating requests to LiteLLM proxy
LITELLM_MASTER_KEY="sk-admin"
# UI_USERNAME/UI_PASSWORD: Credentials for accessing LiteLLM admin UI
UI_USERNAME="admin"
UI_PASSWORD="admin"

# Docker Network
NETWORK_NAME="litellm-network"

# PostgreSQL Database Settings
POSTGRES_CONTAINER="litellm-postgres"
POSTGRES_DB="litellm"
POSTGRES_USER="litellm"
POSTGRES_PASSWORD="litellm123"
POSTGRES_PORT="5432"
POSTGRES_IMAGE="postgres:15-alpine"

# LiteLLM Proxy Settings
LITELLM_IMAGE="docker.litellm.ai/berriai/litellm:main-latest"
LITELLM_PORT="4000"
LITELLM_MODEL="claude-sonnet-4-5-20250929"  # Claude's official model name (NanoClaw compatible)
# ============================================

echo "========================================"
echo "🚀 Starting LiteLLM Proxy Setup"
echo "========================================"

echo ""
echo "📡 Creating Docker network: $NETWORK_NAME"
docker network create $NETWORK_NAME 2>/dev/null || true

echo ""
echo "🗄️  Checking PostgreSQL..."
if ! docker ps | grep -q $POSTGRES_CONTAINER; then
    echo "   Starting PostgreSQL container..."
    docker run -d \
        --name $POSTGRES_CONTAINER \
        --network $NETWORK_NAME \
        -e POSTGRES_DB=$POSTGRES_DB \
        -e POSTGRES_USER=$POSTGRES_USER \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -p $POSTGRES_PORT:5432 \
        $POSTGRES_IMAGE > /dev/null
    echo "   ✅ PostgreSQL started on port $POSTGRES_PORT"
    sleep 3
else
    echo "   ✅ PostgreSQL already running"
fi

echo ""
echo "🔄 Stopping old LiteLLM containers..."
docker stop litellm-proxy 2>/dev/null || true
docker rm litellm-proxy 2>/dev/null || true

echo ""
echo "🚀 Starting LiteLLM proxy on port $LITELLM_PORT..."
echo "   Model: $LITELLM_MODEL"
echo "   Region: $AWS_REGION_NAME"

docker run -d \
    --name litellm-proxy \
    --network $NETWORK_NAME \
    -v $(pwd)/config.yaml:/app/config.yaml \
    -e AWS_REGION_NAME=$AWS_REGION_NAME \
    -e BEDROCK_API_KEY=$BEDROCK_API_KEY \
    -e LITELLM_MASTER_KEY=$LITELLM_MASTER_KEY \
    -e UI_USERNAME=$UI_USERNAME \
    -e UI_PASSWORD=$UI_PASSWORD \
    -e DATABASE_URL=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_CONTAINER:5432/$POSTGRES_DB \
    -p $LITELLM_PORT:4000 \
    $LITELLM_IMAGE \
    --config /app/config.yaml --detailed_debug > /dev/null

echo "   ✅ LiteLLM proxy started"

echo ""
echo "⏳ Waiting for service to be ready..."
MAX_WAIT=60
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if docker logs litellm-proxy 2>&1 | grep -q "Application startup complete"; then
        echo "   ✅ Service is ready! (took ${ELAPSED}s)"
        sleep 2
        break
    fi
    
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo "   ⚠️  Service not responding after ${MAX_WAIT}s"
        docker logs litellm-proxy --tail 20
        exit 1
    fi
    
    sleep 0.5
done

echo ""
echo "========================================"
echo "🧪 Testing LiteLLM Proxy"
echo "========================================"
echo "📝 Test Input:"
echo "   Model: $LITELLM_MODEL"
echo "   Message: 'what llm are you'"
echo ""

RESPONSE=$(curl -s --location "http://0.0.0.0:$LITELLM_PORT/chat/completions" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $LITELLM_MASTER_KEY" \
--data "{
  \"model\": \"$LITELLM_MODEL\",
  \"messages\": [
    {
      \"role\": \"user\",
      \"content\": \"what llm are you\"
    }
  ]
}")

if echo "$RESPONSE" | grep -q "content"; then
    CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)
    echo "✅ Test successful! LiteLLM is working."
    echo ""
    echo "💬 Response:"
    echo "$CONTENT"
else
    echo "❌ Test failed."
    echo ""
    echo "🐞 Error Response:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
    echo "📋 Container logs:"
    docker logs litellm-proxy --tail 30
    exit 1
fi

echo ""
echo "========================================"
echo "✨ Setup Complete!"
echo "========================================"
echo "📍 API Endpoint: http://localhost:$LITELLM_PORT"
echo "🖥️  Admin UI: http://localhost:$LITELLM_PORT/ui"
echo "👤 UI Login: $UI_USERNAME / $UI_PASSWORD"
echo "🔑 API Key: $LITELLM_MASTER_KEY"
echo "========================================"
