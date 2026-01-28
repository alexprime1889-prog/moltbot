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

WORKDIR /app

# Copy all source files first (needed for postinstall script)
COPY . .

# Show versions for debugging
RUN echo "=== Build Environment ===" && node --version && npm --version

# Install dependencies (--ignore-scripts skips postinstall which sets up git hooks - not needed in container)
RUN npm ci --omit=dev --ignore-scripts || npm install --omit=dev --ignore-scripts

# Verify critical dependencies installed
RUN echo "=== Verify Dependencies ===" && \
    ls -la node_modules/chalk 2>/dev/null || echo "WARNING: chalk not found" && \
    ls -la node_modules/commander 2>/dev/null || echo "WARNING: commander not found"

# Install Playwright browsers
RUN npx playwright install chromium --with-deps || echo "Playwright install failed (optional)"

# Disable respawn logic in entry.js (not needed in container)
ENV CLAWDBOT_NO_RESPAWN=1
ENV NODE_OPTIONS="--disable-warning=ExperimentalWarning"

# Railway will inject PORT env var at runtime
EXPOSE 8080

# Startup diagnostics before launching gateway
CMD ["/bin/sh", "-c", "echo '=== Gateway Startup ===' && echo \"Node: $(node --version)\" && echo \"Port: 8080\" && echo \"Token: ${CLAWDBOT_GATEWAY_TOKEN:+SET}\" && echo \"Files:\" && ls -la moltbot.mjs dist/entry.js 2>&1 && echo '=== Starting Gateway ===' && exec node moltbot.mjs gateway --port 8080 --allow-unconfigured --bind lan"]
