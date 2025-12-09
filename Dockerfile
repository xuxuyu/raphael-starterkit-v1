FROM node:20-alpine AS base

# Set working directory
WORKDIR /app

# Install dependencies only when needed
FROM base AS deps

# Install necessary OS packages (optional, extend as needed)
RUN apk add --no-cache libc6-compat

COPY package.json package-lock.json* ./

# Using npm because package-lock.json is present
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder

ENV NODE_ENV=production

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js build (App Router)
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner

ENV NODE_ENV=production

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs \
  && adduser -S nextjs -u 1001

COPY --from=builder /app/public ./public

# For Next.js "standalone" output, copy .next and node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER nextjs

EXPOSE 3000

ENV PORT=3000

CMD ["npm", "run", "start"]


