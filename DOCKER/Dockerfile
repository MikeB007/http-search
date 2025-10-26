# Multi-stage build for Angular + Node.js HTTPS server
FROM node:18-alpine AS builder

# Install OpenSSL for certificate generation
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for building)
# Use npm install instead of npm ci to handle package-lock sync issues
RUN npm install --force && npm cache clean --force

# Copy source code
COPY . .

# Build Angular application with legacy OpenSSL support for Angular 12
RUN NODE_OPTIONS="--openssl-legacy-provider" npm run build

# Production stage
FROM node:18-alpine AS production

# Install OpenSSL for certificate generation at runtime
RUN apk add --no-cache openssl

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy built application and server files
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/server.js ./
COPY --from=builder --chown=nextjs:nodejs /app/package*.json ./
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts

# Create directory for SSL certificates
RUN mkdir -p /app/certs && chown nextjs:nodejs /app/certs

# Switch to non-root user
USER nextjs

# Expose ports
EXPOSE 8080 8443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) process.exit(0); else process.exit(1); }).on('error', () => process.exit(1));"

# Generate SSL certificates and start the application
CMD ["sh", "-c", "node scripts/setup-certificates.js || echo 'Certificate generation failed, continuing...'; node server.js"]