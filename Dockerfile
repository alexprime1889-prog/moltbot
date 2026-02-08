FROM node:22-slim

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

COPY . .

RUN pnpm install --frozen-lockfile || pnpm install

RUN pnpm build

EXPOSE 8080

CMD ["node", "dist/index.js", "gateway", "run", "--allow-unconfigured", "--port", "8080", "--bind", "0.0.0.0"]
