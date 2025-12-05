# Multi-stage build for iTechDMV Platform
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    openssl \
    libpng-dev \
    cairo-dev \
    pango-dev \
    musl-dev \
    jpeg-dev \
    giflib-dev \
    pixman-dev \
    pangomm-dev \
    libjpeg-turbo-dev \
    freetype-dev

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Install production dependencies
RUN apk add --no-cache \
    openssl \
    libpng \
    cairo \
    pango \
    musl \
    jpeg \
    giflib \
    pixman \
    pangomm \
    libjpeg-turbo \
    freetype \
    ttf-freefont

# Create app user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S itechdmv -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=itechdmv:nodejs /app/dist ./dist
COPY --from=builder --chown=itechdmv:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=itechdmv:nodejs /app/package*.json ./

# Create necessary directories
RUN mkdir -p uploads logs && \
    chown -R itechdmv:nodejs uploads logs

# Switch to non-root user
USER itechdmv

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Start the application
CMD ["node", "dist/server/index.js"]
