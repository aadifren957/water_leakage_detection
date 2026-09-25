# Node.js 20 Alpine Base Image
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies and Prisma schema
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

# Copy application source code
COPY tsconfig.json ./
COPY src ./src/

# Generate Prisma Client and Compile TypeScript
RUN npx prisma generate
RUN npm run build

# Production Runtime Stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --only=production

COPY prisma ./prisma/
RUN npx prisma generate

COPY --from=builder /app/dist ./dist

EXPOSE 5001

CMD ["node", "dist/server.js"]
