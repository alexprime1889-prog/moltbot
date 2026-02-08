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

echo "Starting moltbot with --allow-unconfigured..."

# Try to find the moltbot binary
if [ -f /app/moltbot.mjs ]; then
    echo "Found moltbot.mjs"
    exec node /app/moltbot.mjs --allow-unconfigured
elif [ -f /app/dist/index.js ]; then
    echo "Found dist/index.js"
    exec node /app/dist/index.js --allow-unconfigured
else
    echo "ERROR: Cannot find moltbot entry point"
    ls -la /app/
    exit 1
fi
