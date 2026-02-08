#!/bin/sh
# Railway Entrypoint Fix
# This script works around Railway's CMD override by detecting Railway environment
# and automatically launching with correct flags

echo "=== Moltbot Railway Launcher ==="
echo "Environment: ${RAILWAY_ENVIRONMENT_NAME:-unknown}"
echo "Service: ${RAILWAY_SERVICE_NAME:-unknown}"

# Ensure state directory exists
mkdir -p /app/.state

# Set required environment variables
export GATEWAY_MODE=local
export OPENCLAW_GATEWAY_MODE=local
export MOLTBOT_GATEWAY_MODE=local
export CLAWDBOT_ALLOW_UNCONFIGURED=true
export OPENCLAW_ALLOW_UNCONFIGURED=true
export MOLTBOT_ALLOW_UNCONFIGURED=true
export MOLTBOT_NO_RESPAWN=1
export CLAWDBOT_NO_RESPAWN=1

echo "Starting moltbot..."
echo "Working directory: $(pwd)"
echo "Listing /app:"
ls -la /app/ | head -20

# Try to find the moltbot binary
if [ -f /app/moltbot.mjs ]; then
    echo "Found moltbot.mjs - starting..."
    exec node /app/moltbot.mjs
elif [ -f /app/dist/index.js ]; then
    echo "Found dist/index.js - starting..."
    exec node /app/dist/index.js
else
    echo "ERROR: Cannot find moltbot entry point"
    echo "Contents of /app:"
    ls -la /app/
    echo "Contents of /app/dist:"
    ls -la /app/dist/ 2>/dev/null || echo "No /app/dist directory"
    exit 1
fi
