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

# Install Playwright browsers
RUN npx playwright install chromium --with-deps || echo "Playwright install failed (optional)"

# Container runtime settings
ENV CLAWDBOT_NO_RESPAWN=1
ENV NODE_OPTIONS="--disable-warning=ExperimentalWarning"
ENV CLAWDBOT_STATE_DIR=/app/.state
RUN mkdir -p /app/.state

# Railway will inject PORT env var at runtime
EXPOSE 8080

# Configure gateway for Railway proxy (100.64.0.0/16 is Railway's internal network)
# This enables auto-approve for device pairing from Railway load balancer
# Config goes to STATE_DIR which is /app/.state
RUN echo '{"gateway":{"trustedProxies":["100.64.0.0/16","10.0.0.0/8"]}}' > /app/.state/moltbot.json

# Startup diagnostics before launching gateway
CMD ["/bin/sh", "-c", "echo '=== Gateway Startup ===' && echo \"Node: $(node --version)\" && echo \"Port: 8080\" && echo \"Token: ${CLAWDBOT_GATEWAY_TOKEN:+SET}\" && echo \"UI dist:\" && ls -la ui/dist/ 2>&1 | head -5 && echo '=== Starting Gateway ===' && exec node moltbot.mjs gateway --port 8080 --allow-unconfigured --bind lan"]
