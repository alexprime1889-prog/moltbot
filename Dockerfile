FROM node:22-slim

WORKDIR /app

# Build args and env for CI
ARG CI=true
ENV CI=true
ENV NODE_ENV=production
ENV PNPM_CONFIRM_MODULES_DIR=false

# Skip postinstall scripts during build
ENV CLAWDBOT_SKIP_POSTINSTALL=1
# Skip A2UI bundle check in Docker (sources excluded by .dockerignore)
ENV CLAWDBOT_A2UI_SKIP_MISSING=1

# Install pnpm
RUN npm install -g pnpm

# Copy root package files
COPY package.json ./
COPY pnpm-lock.yaml* ./

# Copy UI package files first (for better caching)
COPY ui/package.json ./ui/
COPY ui/pnpm-lock.yaml* ./ui/

# Install root dependencies
RUN pnpm install --frozen-lockfile --ignore-scripts || pnpm install --ignore-scripts

# Install UI dependencies (do this before copying full source to leverage Docker cache)
RUN cd ui && pnpm install --frozen-lockfile --ignore-scripts || cd ui && pnpm install --ignore-scripts

# Copy source code (excluding node_modules via .dockerignore)
COPY . .

# Build UI assets
RUN pnpm ui:build

# Build the project
RUN pnpm build

# Expose port
EXPOSE 8080

# Run gateway
CMD ["node", "dist/index.js", "gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
