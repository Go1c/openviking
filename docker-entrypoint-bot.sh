#!/bin/sh
set -e

# Generate /root/.openviking/ov.conf from environment variables at container startup.
# Keeps secrets out of the image; makes Zeabur env-var configuration work.

: "${OV_OPENROUTER_API_KEY:?OV_OPENROUTER_API_KEY is required}"
: "${OV_OPENAI_API_KEY:?OV_OPENAI_API_KEY is required (used for embeddings)}"
: "${OV_ROOT_API_KEY:?OV_ROOT_API_KEY is required}"

VLM_MODEL="${OV_VLM_MODEL:-anthropic/claude-3.5-sonnet}"
EMBEDDING_MODEL="${OV_EMBEDDING_MODEL:-text-embedding-3-large}"
EMBEDDING_DIM="${OV_EMBEDDING_DIMENSION:-3072}"
SERVER_URL="${OV_SERVER_URL:-http://openviking-server.zeabur.internal:1933}"

mkdir -p /root/.openviking /root/.openviking/data

cat > /root/.openviking/ov.conf << CONF
{
  "storage": {
    "workspace": "/root/.openviking/data"
  },
  "log": {
    "level": "INFO",
    "output": "stdout"
  },
  "vlm": {
    "provider": "openai",
    "api_base": "https://openrouter.ai/api/v1",
    "api_key": "${OV_OPENROUTER_API_KEY}",
    "model": "${VLM_MODEL}",
    "max_concurrent": 10
  },
  "embedding": {
    "dense": {
      "provider": "openai",
      "api_base": "https://api.openai.com/v1",
      "api_key": "${OV_OPENAI_API_KEY}",
      "model": "${EMBEDDING_MODEL}",
      "dimension": ${EMBEDDING_DIM}
    },
    "max_concurrent": 10
  },
  "bot": {
    "agents": {
      "model": "${VLM_MODEL}",
      "max_tool_iterations": 50,
      "memory_window": 50
    },
    "gateway": {
      "host": "0.0.0.0",
      "port": 18790
    },
    "ov_server": {
      "server_url": "${SERVER_URL}",
      "root_api_key": "${OV_ROOT_API_KEY}"
    }
  }
}
CONF

exec "$@"
