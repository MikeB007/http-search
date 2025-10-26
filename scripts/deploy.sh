#!/bin/bash

# Build and deployment script for HTTP Search application

set -e  # Exit on error

echo "🚀 HTTP Search - Build and Deploy Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="http-search"
CONTAINER_NAME="http-search-server"
BUILD_TARGET="${1:-production}"

print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Step 1: Setup certificates
echo "📋 Step 1: Setting up certificates..."
if [ ! -f "./certs/localhost.p12" ]; then
    npm run setup:certs
    print_step "Certificates configured"
else
    print_step "Certificates already exist"
fi

# Step 2: Install dependencies
echo "📋 Step 2: Installing dependencies..."
npm ci
print_step "Dependencies installed"

# Step 3: Build Angular application
echo "📋 Step 3: Building Angular application..."
if [ "$BUILD_TARGET" = "production" ]; then
    npm run build:prod
else
    npm run build
fi
print_step "Angular application built"

# Step 4: Build Docker image
echo "📋 Step 4: Building Docker image..."
if docker build -t "$IMAGE_NAME:latest" .; then
    print_step "Docker image built successfully"
else
    print_error "Docker build failed"
    exit 1
fi

# Step 5: Stop existing container
echo "📋 Step 5: Stopping existing container..."
if docker stop "$CONTAINER_NAME" 2>/dev/null; then
    print_step "Existing container stopped"
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
else
    print_warning "No existing container found"
fi

# Step 6: Run new container
echo "📋 Step 6: Starting new container..."
if docker run -d \
    --name "$CONTAINER_NAME" \
    -p 8080:8080 \
    -p 8443:8443 \
    -v "$(pwd)/certs:/app/certs:ro" \
    -e NODE_ENV="$BUILD_TARGET" \
    -e PFX_PATH="/app/certs/localhost.p12" \
    -e SSL_PASSPHRASE="dev123" \
    "$IMAGE_NAME:latest"; then
    print_step "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Step 7: Show status
echo "📋 Step 7: Checking application status..."
sleep 5  # Wait for container to start

if docker ps | grep -q "$CONTAINER_NAME"; then
    print_step "Application is running!"
    echo ""
    echo "🌐 Application URLs:"
    echo "   HTTPS: https://localhost:8443"
    echo "   HTTP:  http://localhost:8080 (redirects to HTTPS)"
    echo ""
    echo "📊 Container status:"
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "📝 View logs with: docker logs $CONTAINER_NAME"
    echo "🛑 Stop with: docker stop $CONTAINER_NAME"
else
    print_error "Container failed to start"
    echo "📝 Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi

echo ""
echo "🎉 Deployment completed successfully!"