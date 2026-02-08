FROM node:22-slim

WORKDIR /app

# Build args and env for CI
ARG CI=true
ENV CI=true
ENV NODE_ENV=production

# Skip postinstall scripts during build
ENV CLAWDBOT_SKIP_POSTINSTALL=1
# Skip A2UI bundle check in Docker (sources excluded by .dockerignore)
ENV CLAWDBOT_A2UI_SKIP_MISSING=1

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json ./
COPY pnpm-lock.yaml* ./

# Install dependencies (ignore scripts to skip postinstall)
RUN pnpm install --frozen-lockfile --ignore-scripts || pnpm install --ignore-scripts

# Copy source code
COPY . .

# Install UI dependencies (needed for ui:build)
RUN cd ui && pnpm install --frozen-lockfile --ignore-scripts || cd ui && pnpm install --ignore-scripts

# Build the project
RUN pnpm build

# Build UI assets (needed for gateway control panel)
RUN CI=true pnpm ui:build

# Expose port
EXPOSE 8080

# Run gateway
CMD ["node", "dist/index.js", "gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
