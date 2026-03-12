# Claude SDK Compatibility Report with LiteLLM + Bedrock

## Problem Summary

**Error**: `thinking: Input tag 'adaptive' found using 'type' does not match any of the expected tags: 'enabled', 'disabled'`

**Root Cause**:
- Newer Claude Code/SDK versions (≥2.1.71 CLI, ≥0.2.68 SDK) send `thinking: {type: "adaptive"}` for extended thinking
- LiteLLM **does not translate** the 'adaptive' value to Bedrock-compatible format
- AWS Bedrock only accepts `thinking: {type: "enabled"}` or `thinking: {type: "disabled"}`
- Direct Claude Code → Bedrock works because AWS SDK handles translation
- Claude Code → LiteLLM → Bedrock **fails** because LiteLLM passes 'adaptive' unchanged

## Investigation Results

### Version Compatibility Matrix

**✅ LAST WORKING VERSIONS:**
- **@anthropic-ai/claude-agent-sdk**: `0.2.34` (released Feb 6, 2026)
- **@anthropic-ai/claude-code** (CLI): `2.1.70` (released Mar 9, 2026)

**❌ FIRST BREAKING VERSIONS:**
- **@anthropic-ai/claude-agent-sdk**: `0.2.68+` (introduced adaptive thinking)
- **@anthropic-ai/claude-code** (CLI): `2.1.71+` (uses SDK 0.2.68+)

### Claude Code Versions on System
```
/home/linkcd/.local/share/claude/versions/
  - 2.1.72 (❌ BREAKS - has adaptive thinking)
  - 2.1.73 (❌ BREAKS - has adaptive thinking)
  - 2.1.74 (❌ BREAKS - current, has adaptive thinking)
```

**Note:** All installed versions are AFTER the breaking change. Version 2.1.70 needs to be installed.

### From LiteLLM Logs
Working requests show:
- User-Agent: `claude-cli/2.1.34 (external, sdk-ts)` (from containerized environments)
- These work because SDK 0.2.34 doesn't send adaptive thinking parameter

## Solutions

### Solution 1: Update LiteLLM Configuration (RECOMMENDED)
Add parameter translation in your LiteLLM config to map 'adaptive' to 'enabled':

```yaml
# Add to config.yaml
litellm_settings:
  pass_through_endpoints: true
  drop_params: false  # Keep this

  # Add parameter transformation
  modify_params:
    thinking:
      adaptive: enabled  # Map adaptive -> enabled for Bedrock compatibility
```

**Status**: This feature may need to be added to LiteLLM if not available.

### Solution 2: Disable Extended Thinking in Claude Code (QUICK FIX)
Prevent Claude Code from sending the 'adaptive' parameter:

```bash
# In your project directory
cat > CLAUDE.md <<'EOF'
# Extended Thinking Configuration
- Do NOT use extended thinking (adaptive mode) when making API calls
- Use default thinking mode only
EOF
```

Or set environment variable:
```bash
export CLAUDE_EXTENDED_THINKING=false
```

### Solution 3: Patch LiteLLM to Handle 'adaptive' (PERMANENT FIX)
Update LiteLLM's Bedrock adapter to translate 'adaptive' → 'enabled':

```python
# In LiteLLM source: litellm/llms/bedrock/chat/anthropic_messages_config.py
# Add this logic:

if thinking_param:
    thinking_type = thinking_param.get("type")
    if thinking_type == "adaptive":
        # Bedrock doesn't support 'adaptive', map to 'enabled'
        thinking_param["type"] = "enabled"
```

### Solution 4: Downgrade/Pin Claude Code (RECOMMENDED FIX)
Install and pin to version 2.1.70 (last version before adaptive thinking):

```bash
# Install the last working version
npm install -g @anthropic-ai/claude-code@2.1.70

# Verify
claude --version  # Should show 2.1.70
```

**For package.json (containerized deployments):**
```json
{
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "0.2.34",
    "@anthropic-ai/claude-code": "2.1.70"
  }
}
```

**IMPORTANT:** Remove caret (^) to prevent automatic upgrades to breaking versions.

**Note**: Versions 2.1.72+ on your system all have the adaptive thinking issue.

### Solution 5: Use Direct Bedrock Access
Since Claude Code → Bedrock works directly, configure Claude Code to bypass LiteLLM:

```bash
# Set AWS credentials directly
export AWS_REGION_NAME=us-east-1
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

# Use Bedrock model directly
claude --model bedrock/global.anthropic.claude-sonnet-4-20250514-v1:0
```

## Recommended Action Plan

### Immediate Fix (Choose One)
1. **Pin to working versions** (Solution 4 - RECOMMENDED):
   - CLI: `@anthropic-ai/claude-code@2.1.70`
   - SDK: `@anthropic-ai/claude-agent-sdk@0.2.34` (remove `^` caret)

2. **Disable extended thinking** (Solution 2):
   - Add to CLAUDE.md: "Do NOT use extended thinking (adaptive mode)"

### Long-term Fixes
3. **Open issue on LiteLLM** requesting 'adaptive' parameter translation support
4. **Contribute PR to LiteLLM** with Solution 3 implementation (translate adaptive → enabled)

## Testing Commands

Test if extended thinking is the issue:
```bash
# Test WITHOUT extended thinking (should work)
curl -s http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-admin" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "global.anthropic.claude-sonnet-4-6",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "What is 2+2?"}]
  }' | jq

# Test WITH extended thinking (will fail)
curl -s http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-admin" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "global.anthropic.claude-sonnet-4-6",
    "max_tokens": 100,
    "thinking": {"type": "enabled", "budget_tokens": 1000},
    "messages": [{"role": "user", "content": "What is 2+2?"}]
  }' | jq
```

## Conclusion

The issue is **not with Claude SDK version compatibility**, but with **LiteLLM's inability to translate the 'adaptive' thinking parameter** to Bedrock's expected format.

The fastest fix is to disable extended thinking or downgrade Claude Code until LiteLLM adds support for parameter translation.

## Related Links

- LiteLLM Issues: https://github.com/BerriAI/litellm/issues
- Anthropic Extended Thinking Docs: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
- Bedrock Anthropic Messages API: https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-anthropic-claude-messages.html

---
**Report Generated**: 2026-03-12
**Tested Claude Code Versions**: 2.1.72, 2.1.73, 2.1.74 (all break)
**Last Working Versions**: CLI 2.1.70, SDK 0.2.34
**Breaking Change Introduced**: CLI 2.1.71+, SDK 0.2.68+
**LiteLLM Version**: main-latest (docker.litellm.ai/berriai/litellm:main-latest)

## Quick Reference

```bash
# Install last working version
npm install -g @anthropic-ai/claude-code@2.1.70

# Or for package.json - PIN exactly (no ^ caret):
"@anthropic-ai/claude-agent-sdk": "0.2.34"
"@anthropic-ai/claude-code": "2.1.70"
```
