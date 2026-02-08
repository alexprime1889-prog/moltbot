FROM node:22-slim

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the project
RUN pnpm build

# Expose port
EXPOSE 8080

# Run gateway
CMD ["node", "dist/index.js", "gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
