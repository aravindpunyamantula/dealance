# Stage 1: Build
FROM node:20-slim AS builder

WORKDIR /app

# Install build dependencies for Prisma and native modules
RUN apt-get update && apt-get install -y openssl python3 make g++ && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm install

# Copy prisma schema first for generation
COPY prisma ./prisma/
RUN npx prisma generate

# Copy source and config
COPY . .

# Build TypeScript
RUN npm run build

# Stage 2: Production
FROM node:20-slim AS runner

WORKDIR /app

# Install runtime dependencies (OpenSSL is required by Prisma, curl for healthcheck)
RUN apt-get update && apt-get install -y openssl curl && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies
RUN npm install --omit=dev

# Copy compiled code
COPY --from=builder /app/dist ./dist
# Copy generated prisma client
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
# Copy prisma directory (needed for migrations/push)
COPY --from=builder /app/prisma ./prisma

# Create uploads directory
RUN mkdir -p uploads && chmod 777 uploads

EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start command
# If migrations folder exists, use migrate deploy; otherwise use db push
CMD ["sh", "-c", "if [ -d \"prisma/migrations\" ]; then npx prisma migrate deploy; else npx prisma db push --accept-data-loss; fi && npm start"]
