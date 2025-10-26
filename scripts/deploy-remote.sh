#!/bin/bash

# Remote deployment script for HTTP Search application
# Usage: ./deploy-remote.sh [server] [user] [ssl_password]

set -e  # Exit on error

# Configuration
REMOTE_SERVER="${1:-base}"
REMOTE_USER="${2:-admin}"
SSL_PASSWORD="${3:-production123}"
IMAGE_NAME="ghcr.io/mikeb007/http-search:latest"
DEPLOY_DIR="/opt/http-search"
CONTAINER_NAME="http-search-production"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          HTTP Search Remote Deployment              ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to run commands on remote server
run_remote() {
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" "$1"
}

# Function to copy files to remote server
copy_to_remote() {
    scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$1" "$REMOTE_USER@$REMOTE_SERVER:$2"
}

# Main deployment function
deploy() {
    print_header
    
    print_info "Deploying to: $REMOTE_USER@$REMOTE_SERVER"
    print_info "Target directory: $DEPLOY_DIR"
    print_info "Container image: $IMAGE_NAME"
    echo ""
    
    # Step 1: Test connection
    print_info "Step 1: Testing connection to remote server..."
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" exit 2>/dev/null; then
        print_error "Cannot connect to $REMOTE_SERVER as $REMOTE_USER"
        print_info "Make sure:"
        print_info "1. Server is accessible: ping $REMOTE_SERVER"
        print_info "2. SSH is configured: ssh $REMOTE_USER@$REMOTE_SERVER"
        print_info "3. SSH keys are set up for passwordless login"
        exit 1
    fi
    print_step "Connection successful"
    
    # Step 2: Check Docker installation
    print_info "Step 2: Checking Docker installation..."
    if ! run_remote "command -v docker >/dev/null 2>&1"; then
        print_error "Docker is not installed on remote server"
        print_info "Please install Docker first:"
        print_info "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
        exit 1
    fi
    print_step "Docker is installed"
    
    # Step 3: Create deployment directory
    print_info "Step 3: Creating deployment directory..."
    run_remote "sudo mkdir -p $DEPLOY_DIR/{certs,logs,config} && sudo chown $USER:$USER $DEPLOY_DIR -R"
    print_step "Deployment directory ready"
    
    # Step 4: Copy deployment files
    print_info "Step 4: Copying deployment files..."
    copy_to_remote "docker-compose.prod.yml" "$DEPLOY_DIR/"
    
    # Copy certificate if it exists locally
    if [ -f "./certs/localhost.p12" ]; then
        copy_to_remote "./certs/localhost.p12" "$DEPLOY_DIR/certs/production.p12"
        print_step "Certificate copied (using development cert for testing)"
        print_warning "Replace with production certificate for live deployment"
    else
        print_warning "No certificate found - you'll need to generate one on the server"
    fi
    
    print_step "Files copied successfully"
    
    # Step 5: Pull Docker image
    print_info "Step 5: Pulling Docker image..."
    run_remote "cd $DEPLOY_DIR && docker pull $IMAGE_NAME"
    print_step "Docker image pulled"
    
    # Step 6: Stop existing container
    print_info "Step 6: Stopping existing container..."
    run_remote "cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml down 2>/dev/null || true"
    print_step "Existing container stopped"
    
    # Step 7: Start new container
    print_info "Step 7: Starting new container..."
    run_remote "cd $DEPLOY_DIR && SSL_PASSPHRASE='$SSL_PASSWORD' docker-compose -f docker-compose.prod.yml up -d"
    
    # Wait for container to start
    sleep 10
    
    # Step 8: Verify deployment
    print_info "Step 8: Verifying deployment..."
    if run_remote "docker ps --filter name=$CONTAINER_NAME --filter status=running | grep -q $CONTAINER_NAME"; then
        print_step "Container is running"
        
        # Test health check
        if run_remote "docker exec $CONTAINER_NAME node -e \"require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) process.exit(0); else process.exit(1); }).on('error', () => process.exit(1));\"" 2>/dev/null; then
            print_step "Health check passed"
        else
            print_warning "Health check failed - check application logs"
        fi
    else
        print_error "Container failed to start"
        run_remote "cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml logs"
        exit 1
    fi
    
    # Step 9: Show deployment info
    print_info "Step 9: Deployment complete!"
    echo ""
    echo -e "${GREEN}🎉 Deployment Summary:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Server: https://$REMOTE_SERVER"
    echo "HTTP:   http://$REMOTE_SERVER (redirects to HTTPS)"
    echo "Container: $CONTAINER_NAME"
    echo "Image: $IMAGE_NAME"
    echo ""
    echo "Management commands:"
    echo "• View logs:    ssh $REMOTE_USER@$REMOTE_SERVER 'cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml logs -f'"
    echo "• Stop app:     ssh $REMOTE_USER@$REMOTE_SERVER 'cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml down'"
    echo "• Restart app:  ssh $REMOTE_USER@$REMOTE_SERVER 'cd $DEPLOY_DIR && docker-compose -f docker-compose.prod.yml restart'"
    echo "• Update app:   ./deploy-remote.sh $REMOTE_SERVER $REMOTE_USER"
    echo ""
    
    # Show container status
    print_info "Current container status:"
    run_remote "docker ps --filter name=$CONTAINER_NAME --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [server] [user] [ssl_password]"
    echo ""
    echo "Arguments:"
    echo "  server       Remote server hostname or IP (default: base)"
    echo "  user         SSH username (default: admin)"
    echo "  ssl_password SSL certificate password (default: production123)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy to base server with defaults"
    echo "  $0 192.168.1.100                     # Deploy to specific IP"
    echo "  $0 base ubuntu mypassword             # Custom user and password"
    echo ""
    echo "Prerequisites:"
    echo "  • SSH access to target server"
    echo "  • Docker installed on target server"
    echo "  • docker-compose.prod.yml in current directory"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run deployment
deploy