FROM node:20-slim

# Install dependencies for Playwright
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production 2>/dev/null || npm install --only=production

# Copy source
COPY . .

# Install Playwright browsers
RUN npx playwright install chromium --with-deps 2>/dev/null || true

# Expose port (Railway will set PORT env var)
ENV PORT=8080
EXPOSE 8080

# Start gateway using shell to expand $PORT
CMD node moltbot.mjs gateway --port ${PORT:-8080}
