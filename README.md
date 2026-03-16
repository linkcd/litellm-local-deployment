# LiteLLM Proxy - Local Deployment

Run LiteLLM locally (as container) and connect it to AWS Bedrock models.

**Use cases:**
- Local development and testing LiteLLM
- Connect local agentic workloads (like NanoClaw) to Bedrock-hosted models via local LiteLLM proxy server
- Per-group usage tracking and budget management

## Prerequisites
- Docker
- AWS Bedrock API Key (get from AWS Console > Bedrock > API Keys)

## Quick Start

```bash
# 1. Create your .env file from the template
cp .env.example .env

# 2. Edit .env and add your AWS Bedrock API key
#    - BEDROCK_API_KEY: Your AWS Bedrock API key
#    - AWS_REGION_NAME: Your AWS region (default: us-east-1)
#    - LITELLM_MASTER_KEY: API key for LiteLLM proxy (default: sk-admin)
#    - UI_USERNAME/UI_PASSWORD: Admin UI credentials (default: admin/admin)

# 3. Run the setup
./run.sh
```

The script will:
- Load configuration from `.env` file
- Start PostgreSQL database (container with persistent storage)
- Launch LiteLLM proxy (container)
- Run a test query
- Display access information

## Access

- **LiteLLM API**: http://localhost:4000
- **LiteLLM Admin UI**: http://localhost:4000/ui (login with UI_USERNAME/UI_PASSWORD from .env)

## Configuration

### Environment Variables
All configuration is managed in the `.env` file. See `.env.example` for all available options.

### Model Mappings
Edit `config.yaml` to add more models or change Bedrock endpoint mappings.

### Data Persistence
PostgreSQL data is stored in `./postgres-data/` and persists across container restarts. This ensures:
- Virtual keys are preserved
- Usage tracking history is maintained
- Budget limits and settings survive restarts

## Virtual Keys

Create virtual keys for usage tracking and budget management:

```bash
./create-keys.sh
```

This creates separate keys for each NanoClaw group with individual budgets:
- `main`: $50/month
- `dev-team`: $100/month
- `daily-news`: $50/month
- `publisher`: $30/month
- `playground`: $10/month

Virtual keys are stored in PostgreSQL and persist across restarts. View usage and manage budgets in the Admin UI.

## Observability with Langfuse

LiteLLM integrates with [Langfuse](https://langfuse.com) for comprehensive observability and tracing:

### Setup

1. Create a Langfuse account at https://cloud.langfuse.com
2. Get your API keys from the Langfuse dashboard
3. Add them to your `.env` file:

```bash
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_OTEL_HOST=https://cloud.langfuse.com  # or https://us.cloud.langfuse.com for US region
```

4. Restart the proxy:

```bash
./run.sh
```

### What You Get

Langfuse automatically traces all requests through the proxy:
- **Request/Response data**: Full conversation history
- **Token usage**: Input, output, and cached tokens
- **Latency metrics**: Response times and performance
- **Cost tracking**: Automatic cost calculation per request
- **Model performance**: Success rates and error tracking
- **User analytics**: Per-key usage patterns

### Access Dashboard

View your traces at https://cloud.langfuse.com

### Configuration

The integration uses OpenTelemetry and is configured in:
- `config.yaml`: `callbacks: ["langfuse_otel"]`
- `.env`: Langfuse credentials
- `run.sh`: Passes environment variables to container

## Troubleshooting

### Container won't start
```bash
# Check container logs
docker logs litellm-proxy

# Check database logs
docker logs litellm-postgres

# Restart containers
docker restart litellm-proxy litellm-postgres
```

### Database issues
If you encounter database schema errors, reset the database:
```bash
docker stop litellm-postgres
docker rm litellm-postgres
./run.sh  # Will create fresh database
```

Note: This preserves data in `./postgres-data/` - only remove that directory if you want to completely reset.

### Authentication errors
- Verify your `BEDROCK_API_KEY` in `.env` is valid
- Check the key has permissions for Claude models in AWS Bedrock
- Ensure `AWS_REGION_NAME` matches where your API key was created

### "thinking: adaptive" errors
If you see errors like `Input tag 'adaptive' found using 'type' does not match any of the expected tags`:
- This is a Claude SDK compatibility issue
- **Solution**: Pin to Claude Code 2.1.70 and SDK 0.2.34
- See [SDK_COMPATIBILITY_REPORT.md](SDK_COMPATIBILITY_REPORT.md) for full details

## Claude SDK Compatibility

⚠️ **Known Issue**: Claude Code CLI versions 2.1.71+ and SDK versions 0.2.68+ send `thinking: {type: "adaptive"}` which LiteLLM doesn't translate properly for Bedrock.

**Quick Fix:**
```bash
# Pin to last working version
npm install -g @anthropic-ai/claude-code@2.1.70
```

**For package.json:**
```json
{
  "@anthropic-ai/claude-agent-sdk": "0.2.34",
  "@anthropic-ai/claude-code": "2.1.70"
}
```

📖 **Full details and solutions**: See [SDK_COMPATIBILITY_REPORT.md](SDK_COMPATIBILITY_REPORT.md)

## NanoClaw Integration

For using LiteLLM as a proxy for NanoClaw with per-group usage tracking, see [NANOCLAW-INTEGRATION.md](NANOCLAW-INTEGRATION.md).
