# NanoClaw + LiteLLM Integration

This document explains how NanoClaw integrates with LiteLLM for per-group usage tracking.

## Architecture

```
NanoClaw Groups → LiteLLM Proxy → AWS Bedrock
```

**Key Features:**
- All groups use the same LiteLLM proxy endpoint
- Each group can have its own virtual key for separate tracking
- Budget limits and rate limits managed in LiteLLM UI
- Model selection happens at runtime (Opus/Sonnet/Haiku)

## How It Works

### 1. LiteLLM Proxy Setup

**Configuration files:**
- `config.yaml` - Model mappings (Claude names → Bedrock endpoints)
- `run.sh` - Proxy startup script with credentials

**Start the proxy:**
```bash
./run.sh
```

This starts PostgreSQL database and LiteLLM proxy. See `run.sh` for port and credentials.

### 2. NanoClaw Configuration

**Root `.env` (default settings):**
- Points to LiteLLM proxy endpoint
- Sets default model names
- Master API key (fallback if group has no key)

**Group `.env` files (overrides):**
- `ANTHROPIC_API_KEY` - Virtual key for usage tracking
- Optional model overrides (not recommended)

**Merge behavior:**
```
Final config = { ...root/.env, ...groups/{folder}/.env }
```

Group settings override global settings.

### 3. Virtual Keys

**Create keys in LiteLLM UI or via API:**
- Each NanoClaw group gets its own key
- Keys track usage separately
- Set budgets and rate limits per key

**Key creation script:**
```bash
./create-keys.sh
```

See script output for generated keys.

### 4. Usage Tracking

**What gets tracked:**
- Token consumption per group
- Cost per group (based on model pricing)
- Request count and rate
- Budget remaining

**Where to view:**
- LiteLLM UI dashboard (see `run.sh` for URL/credentials)
- PostgreSQL database (query directly if needed)
- API endpoints (see LiteLLM docs)

## Configuration Files

**LiteLLM side:**
- `config.yaml` - Model definitions and mappings
- `run.sh` - Bedrock credentials, database config, ports
- `create-keys.sh` - Virtual key creation

**NanoClaw side:**
- `NanoClaw/.env` - Root config (proxy endpoint, defaults)
- `groups/{folder}/.env` - Per-group overrides (virtual keys)
- `groups/{folder}/.env.example` - Templates

## Testing

**Test LiteLLM proxy:**
```bash
./test-group-keys.sh
```

**Test NanoClaw integration:**
1. Start NanoClaw: `npm run dev`
2. Send message to any group
3. Check LiteLLM UI for request logs

## Troubleshooting

**Proxy not running:**
```bash
docker ps | grep litellm-proxy
docker logs litellm-proxy
```

**Wrong endpoint:**
Check `ANTHROPIC_BASE_URL` in NanoClaw's `.env` files.

**Authentication errors:**
Check virtual keys in LiteLLM UI. Keys are stored in PostgreSQL.

**Model not found:**
Check `config.yaml` for model name mappings.

## Advanced Usage

**Multiple Bedrock accounts:**
Run multiple LiteLLM proxies on different ports, set different `ANTHROPIC_BASE_URL` per group.

**Custom model routing:**
Edit `config.yaml` to add new model mappings or change Bedrock endpoints.

**Budget alerts:**
Configure in LiteLLM UI per virtual key.

## File References

All configuration values are in:
- `litellm/config.yaml` - Model mappings
- `litellm/run.sh` - Bedrock credentials, ports, database
- `litellm/create-keys.sh` - Virtual key generation
- `NanoClaw/.env` - Root proxy settings
- `NanoClaw/groups/*/.env` - Group-specific keys

Do not hardcode values in documentation - refer to these files for actual configuration.
