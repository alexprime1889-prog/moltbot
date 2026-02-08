FROM node:22-slim

# Install system dependencies (git needed for npm, others for Playwright)
RUN apt-get update && apt-get install -y \
    git \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    curl \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy all source files first (needed for postinstall script)
COPY . .

# Show versions for debugging
RUN echo "=== Build Environment ===" && node --version && pnpm --version

# Install dependencies (using pnpm for workspace support)
RUN pnpm install --frozen-lockfile || pnpm install

# Build Control UI (CRITICAL - explicit install for vite)
# Note: vite outputs to ../dist/control-ui/ not ui/dist/
RUN echo "=== Building Control UI ===" && \
    cd ui && pnpm install && pnpm build && \
    echo "=== UI Build Complete ===" && \
    ls -la ../dist/control-ui/

# Build the main application (CRITICAL - compiles TypeScript to dist/)
RUN echo "=== Building Main Application ===" && \
    pnpm build && \
    echo "=== Build Complete ===" && \
    ls -la dist/index.js || (echo "ERROR: dist/index.js not found!" && exit 1)

# Install Playwright browsers
RUN npx playwright install chromium --with-deps || echo "Playwright install failed (optional)"

# Container runtime settings
ENV CLAWDBOT_NO_RESPAWN=1
ENV NODE_OPTIONS="--disable-warning=ExperimentalWarning"
ENV CLAWDBOT_STATE_DIR=/app/.state
ENV GATEWAY_MODE=local
ENV OPENCLAW_GATEWAY_MODE=local
ENV MOLTBOT_GATEWAY_MODE=local
ENV CLAWDBOT_ALLOW_UNCONFIGURED=true
ENV MOLTBOT_ALLOW_UNCONFIGURED=true
ENV OPENCLAW_ALLOW_UNCONFIGURED=true
RUN mkdir -p /app/.state

# Railway will inject PORT env var at runtime
EXPOSE 8080

# Copy and set up entrypoint script
COPY railway-entrypoint.sh /app/railway-entrypoint.sh
RUN chmod +x /app/railway-entrypoint.sh

# Cache bust for Railway (change this to force rebuild)
ARG CACHE_BUST=202602072005
# Force rebuild
RUN echo "Rebuild forced at $(date)" > /tmp/rebuild.txt

# Use explicit command to bypass Railway CMD override
# Railway often overrides CMD, so we use ENTRYPOINT + explicit args
ENTRYPOINT ["/app/railway-entrypoint.sh"]
CMD ["gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
