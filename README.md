# LiteLLM Proxy - Local Deployment

Run LiteLLM locally (as container) and connect it to AWS Bedrock models.

**Use cases:**
- Local development and testing LiteLLM
- Connect local agentic workloads (like OpenClaw) to Bedrock-hosted models via local LiteLLM proxy server

## Prerequisites
- Docker
- AWS Bedrock API Key (get from AWS Console > Bedrock > API Keys)

## Quick Start

```bash
# 1. Update credentials in run.sh:
#    - BEDROCK_API_KEY: Your AWS Bedrock API key
#    - AWS_REGION_NAME: Your AWS region
#    - LITELLM_MASTER_KEY: Choose your API key
#    - UI_USERNAME/UI_PASSWORD: Choose admin user name and password for Admin UI access

# 2. Run the setup
./run.sh
```

The script will:
- Start PostgreSQL database (container)
- Launch LiteLLM proxy (container)
- Run a test query
- Display access information

## Access

- **LiteLLM API**: http://localhost:4000
- **LiteLLM Admin UI**: http://localhost:4000/ui

## Configuration

Edit `config.yaml` to add more models or change settings.
Edit `run.sh` CONFIGURATION section for credentials and ports.

## Virtual Keys

To create virtual keys for usage tracking and budget management:

```bash
./create-keys.sh
```

See the script for virtual key creation and budget configuration.

## NanoClaw Integration

For using LiteLLM as a proxy for NanoClaw with per-group usage tracking, see [NANOCLAW-INTEGRATION.md](NANOCLAW-INTEGRATION.md).
