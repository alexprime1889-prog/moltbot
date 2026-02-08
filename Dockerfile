FROM node:22-slim

WORKDIR /app

# Build args and env for CI
ARG CI=true
ENV CI=true
ENV PNPM_CONFIRM_MODULES_DIR=false

# Skip postinstall scripts during build
ENV CLAWDBOT_SKIP_POSTINSTALL=1
# Skip A2UI bundle check in Docker (sources excluded by .dockerignore)
ENV CLAWDBOT_A2UI_SKIP_MISSING=1

# Install pnpm and typescript (for build)
RUN npm install -g pnpm typescript tsx

# Copy root package files
COPY package.json ./
COPY pnpm-lock.yaml* ./

# Copy UI package files first (for better caching)
COPY ui/package.json ./ui/

# Install ALL dependencies (including dev deps needed for build)
RUN pnpm install --frozen-lockfile --ignore-scripts || pnpm install --ignore-scripts

# Copy source code (excluding node_modules via .dockerignore)
COPY . .

# Build UI assets (skip if it fails - UI is optional for gateway)
RUN pnpm ui:build || echo "UI build failed, continuing..."

# Build the project using custom script that continues despite type errors
RUN ./scripts/docker-build.sh

# Set production env for runtime
ENV NODE_ENV=production

# Create config directory and copy minimal config for gateway mode=local
RUN mkdir -p /root/.config/moltbot
COPY config.json /root/.config/moltbot/config.json

# Expose port
EXPOSE 8080

# Run gateway
CMD ["node", "dist/index.js", "gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
