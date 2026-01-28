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

# Install dependencies (--ignore-scripts skips postinstall which sets up git hooks - not needed in container)
RUN npm ci --omit=dev --ignore-scripts 2>/dev/null || npm install --omit=dev --ignore-scripts

# Install Playwright browsers
RUN npx playwright install chromium --with-deps 2>/dev/null || true

# Railway will inject PORT env var at runtime
# Do NOT set ENV PORT here - it can conflict with Railway's injection
EXPOSE 8080

# Gateway requires auth token for non-loopback binding
# CLAWDBOT_GATEWAY_TOKEN must be set in Railway environment variables

# Start gateway with hardcoded port 8080 (Railway routes to this via EXPOSE)
CMD ["/bin/sh", "-c", "echo '=== Gateway Startup ===' && echo 'PORT=8080 (hardcoded)' && echo \"TOKEN=${CLAWDBOT_GATEWAY_TOKEN:+SET}\" && exec node moltbot.mjs gateway --port 8080 --allow-unconfigured --bind lan"]
