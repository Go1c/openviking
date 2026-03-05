#!/bin/sh
set -e

# Generate /app/ov.conf from environment variables at container startup.
# This keeps secrets out of the image and makes Zeabur env-var configuration work.

: "${OV_OPENROUTER_API_KEY:?OV_OPENROUTER_API_KEY is required}"
: "${OV_OPENAI_API_KEY:?OV_OPENAI_API_KEY is required (used for embeddings)}"
: "${OV_ROOT_API_KEY:?OV_ROOT_API_KEY is required}"

VLM_MODEL="${OV_VLM_MODEL:-anthropic/claude-3.5-sonnet}"
EMBEDDING_MODEL="${OV_EMBEDDING_MODEL:-text-embedding-3-large}"
EMBEDDING_DIM="${OV_EMBEDDING_DIMENSION:-3072}"

mkdir -p /app/data

cat > /app/ov.conf << CONF
{
  "storage": {
    "workspace": "/app/data"
  },
  "log": {
    "level": "INFO",
    "output": "stdout"
  },
  "server": {
    "host": "0.0.0.0",
    "port": 1933,
    "root_api_key": "${OV_ROOT_API_KEY}"
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
  }
}
CONF

exec "$@"
