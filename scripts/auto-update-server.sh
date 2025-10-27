#!/bin/bash

# Auto-update script for base server
# Run this on your base server to set up automatic Docker image updates

set -e

DEPLOY_DIR="/opt/http-search"
IMAGE_NAME="ghcr.io/mikeb007/http-search:latest"
CONTAINER_NAME="http-search-production"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to update Docker image and restart container
update_application() {
    print_info "Starting auto-update process..."
    
    cd $DEPLOY_DIR
    
    # Pull latest image
    print_info "Pulling latest Docker image..."
    docker pull $IMAGE_NAME
    
    # Stop current container
    print_info "Stopping current container..."
    docker-compose -f docker-compose.yml down 2>/dev/null || true
    
    # Start updated container
    print_info "Starting updated container..."
    SSL_PASSPHRASE="${SSL_PASSPHRASE:-production123}" docker-compose -f docker-compose.yml up -d
    
    # Wait for startup
    sleep 10
    
    # Verify container is running
    if docker ps --filter name=$CONTAINER_NAME --filter status=running | grep -q $CONTAINER_NAME; then
        print_step "Update completed successfully!"
        print_info "Application is running at: https://$(hostname -I | awk '{print $1}'):8443"
    else
        echo "❌ Update failed - check logs:"
        docker-compose -f docker-compose.yml logs
        exit 1
    fi
}

# Function to set up cron job for periodic updates
setup_auto_update_cron() {
    print_info "Setting up automatic updates every 30 minutes..."
    
    # Create the cron job
    CRON_JOB="*/30 * * * * cd $DEPLOY_DIR && $0 update >/dev/null 2>&1"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "$0 update"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        print_step "Cron job added - auto-update every 30 minutes"
    else
        print_step "Cron job already exists"
    fi
}

# Function to set up webhook endpoint (advanced)
setup_webhook() {
    print_info "Setting up webhook endpoint for instant updates..."
    
    cat > $DEPLOY_DIR/webhook-server.js << 'EOF'
const http = require('http');
const { exec } = require('child_process');

const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/deploy') {
        console.log('Webhook received - starting deployment...');
        
        exec('cd /opt/http-search && ./auto-update-server.sh update', (error, stdout, stderr) => {
            if (error) {
                console.error('Deployment failed:', error);
                res.writeHead(500);
                res.end('Deployment failed');
            } else {
                console.log('Deployment successful:', stdout);
                res.writeHead(200);
                res.end('Deployment successful');
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not found');
    }
});

server.listen(9999, () => {
    console.log('Webhook server running on port 9999');
});
EOF

    # Create systemd service for webhook
    sudo tee /etc/systemd/system/http-search-webhook.service > /dev/null << EOF
[Unit]
Description=HTTP Search Webhook Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/node $DEPLOY_DIR/webhook-server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable http-search-webhook
    sudo systemctl start http-search-webhook
    
    print_step "Webhook server started on port 9999"
    print_info "Add this URL to GitHub webhook: http://$(hostname -I | awk '{print $1}'):9999/deploy"
}

# Show usage
show_usage() {
    echo "HTTP Search Auto-Update Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  update     - Update Docker image and restart container"
    echo "  setup-cron - Set up automatic updates every 30 minutes"
    echo "  setup-webhook - Set up webhook endpoint for instant updates"
    echo "  install    - Full setup (cron + webhook)"
    echo ""
    echo "Examples:"
    echo "  $0 update          # Manual update"
    echo "  $0 setup-cron      # Setup automatic updates"
    echo "  $0 install         # Complete setup"
}

# Main logic
case "${1:-}" in
    "update")
        update_application
        ;;
    "setup-cron")
        setup_auto_update_cron
        ;;
    "setup-webhook")
        setup_webhook
        ;;
    "install")
        setup_auto_update_cron
        setup_webhook
        print_step "Auto-update system installed!"
        print_info "Your server will now automatically update when:"
        print_info "1. Every 30 minutes (cron job)"
        print_info "2. When webhook is triggered from GitHub"
        ;;
    *)
        show_usage
        ;;
esac