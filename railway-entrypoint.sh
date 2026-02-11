#!/bin/sh

set -eu

log() {
  printf '[railway-entrypoint] %s\n' "$*"
}

log "=== Moltbot Railway Launcher ==="
log "Environment: ${RAILWAY_ENVIRONMENT_NAME:-unknown}"
log "Service: ${RAILWAY_SERVICE_NAME:-unknown}"
log "Node version: $(node --version 2>/dev/null || echo unavailable)"
log "PWD: $(pwd)"
log "PORT: ${PORT:-unset}"

STATE_DIR="${CLAWDBOT_STATE_DIR:-/app/.state}"
mkdir -p "${STATE_DIR}"
export CLAWDBOT_STATE_DIR="${STATE_DIR}"

# Keep aliases in sync across legacy/new env variable names.
export GATEWAY_MODE="${GATEWAY_MODE:-local}"
export OPENCLAW_GATEWAY_MODE="${OPENCLAW_GATEWAY_MODE:-local}"
export MOLTBOT_GATEWAY_MODE="${MOLTBOT_GATEWAY_MODE:-local}"
export CLAWDBOT_ALLOW_UNCONFIGURED="${CLAWDBOT_ALLOW_UNCONFIGURED:-true}"
export OPENCLAW_ALLOW_UNCONFIGURED="${OPENCLAW_ALLOW_UNCONFIGURED:-true}"
export MOLTBOT_ALLOW_UNCONFIGURED="${MOLTBOT_ALLOW_UNCONFIGURED:-true}"
export MOLTBOT_NO_RESPAWN=1
export CLAWDBOT_NO_RESPAWN=1

if [ -f /app/moltbot.mjs ]; then
  ENTRYPOINT_FILE="/app/moltbot.mjs"
elif [ -f /app/dist/index.js ]; then
  ENTRYPOINT_FILE="/app/dist/index.js"
else
  log "ERROR: Cannot find moltbot entrypoint (/app/moltbot.mjs or /app/dist/index.js)"
  log "Contents of /app:"
  ls -la /app || true
  log "Contents of /app/dist:"
  ls -la /app/dist 2>/dev/null || log "No /app/dist directory"
  exit 1
fi

# If Railway does not pass a command override, run gateway with Railway-safe defaults.
if [ "$#" -eq 0 ]; then
  PORT_VALUE="${PORT:-8080}"
  BIND_MODE="${MOLTBOT_GATEWAY_BIND:-0.0.0.0}"
  set -- gateway run --allow-unconfigured --port "${PORT_VALUE}" --bind "${BIND_MODE}"
  log "No runtime args provided; using default gateway command."
else
  log "Runtime args: $*"
  if [ "$1" = "gateway" ]; then
    has_allow=0
    has_port=0
    has_bind=0
    for arg in "$@"; do
      if [ "$arg" = "--allow-unconfigured" ]; then
        has_allow=1
      fi
      if [ "$arg" = "--port" ]; then
        has_port=1
      fi
      if [ "$arg" = "--bind" ]; then
        has_bind=1
      fi
    done

    if [ "${has_allow}" -eq 0 ]; then
      set -- "$@" --allow-unconfigured
      log "Appended missing --allow-unconfigured."
    fi
    if [ "${has_port}" -eq 0 ] && [ -n "${PORT:-}" ]; then
      set -- "$@" --port "${PORT}"
      log "Appended missing --port ${PORT}."
    fi
    if [ "${has_bind}" -eq 0 ]; then
      BIND_MODE="${MOLTBOT_GATEWAY_BIND:-0.0.0.0}"
      set -- "$@" --bind "${BIND_MODE}"
      log "Appended missing --bind ${BIND_MODE}."
    fi
  fi
fi

log "Using entrypoint: ${ENTRYPOINT_FILE}"
log "Executing: node ${ENTRYPOINT_FILE} $*"
exec node "${ENTRYPOINT_FILE}" "$@"
