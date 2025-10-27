#!/bin/bash

# Docker Refresh Script for http-search Production Container
# This script provides multiple options for updating the production Docker container
# with the latest image from GitHub Container Registry

set -e

CONTAINER_NAME="http-search-production"
IMAGE_NAME="ghcr.io/mikeb007/http-search:latest"
CERTS_PATH="/opt/http-search/certs"
LOGS_PATH="/opt/http-search/logs"

echo "🐳 Docker Container Refresh Script for http-search"
echo "=================================================="
echo ""

# Function to check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Option 1: Quick restart (if container exists)
quick_restart() {
    echo "🔄 Option 1: Quick restart with latest image"
    echo "Pulling latest image..."
    docker pull $IMAGE_NAME
    
    if container_exists; then
        echo "Restarting existing container..."
        docker restart $CONTAINER_NAME
        echo "✅ Container restarted successfully!"
    else
        echo "❌ Container $CONTAINER_NAME does not exist. Use option 3 to create it."
        return 1
    fi
}

# Option 2: Full refresh (stop, remove, recreate)
full_refresh() {
    echo "🔄 Option 2: Full refresh - stop, remove, and recreate container"
    echo "Pulling latest image..."
    docker pull $IMAGE_NAME
    
    if container_exists; then
        if container_running; then
            echo "Stopping container..."
            docker stop $CONTAINER_NAME
        fi
        echo "Removing container..."
        docker rm $CONTAINER_NAME
    fi
    
    echo "Creating new container with latest image..."
    create_new_container
}

# Option 3: Create new container
create_new_container() {
    echo "🔄 Option 3: Creating new container with latest code"
    
    # Check if container already exists
    if container_exists; then
        echo "❌ Container $CONTAINER_NAME already exists. Use option 2 for full refresh."
        return 1
    fi
    
    echo "Pulling latest image..."
    docker pull $IMAGE_NAME
    
    echo "Starting new container..."
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p 80:8080 \
        -p 8443:8443 \
        -e NODE_ENV=production \
        -e PFX_PATH=/app/certs/production.p12 \
        -e SSL_PASSPHRASE=production123 \
        -e NODE_OPTIONS=--openssl-legacy-provider \
        -v "${CERTS_PATH}:/app/certs:ro" \
        -v "${LOGS_PATH}:/app/logs" \
        $IMAGE_NAME
    
    echo "✅ New container created and started successfully!"
}

# Function to show container status
show_status() {
    echo "📊 Current container status:"
    echo "=============================="
    
    if container_exists; then
        echo "Container exists: ✅"
        if container_running; then
            echo "Container running: ✅"
            echo ""
            echo "Container details:"
            docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        else
            echo "Container running: ❌ (stopped)"
        fi
    else
        echo "Container exists: ❌"
    fi
    echo ""
}

# Function to show logs
show_logs() {
    if container_exists; then
        echo "📋 Container logs (last 50 lines):"
        echo "=================================="
        docker logs --tail 50 $CONTAINER_NAME
    else
        echo "❌ Container $CONTAINER_NAME does not exist."
    fi
}

# Main menu
show_menu() {
    echo "Available options:"
    echo "1) Quick restart (pull latest + restart existing container)"
    echo "2) Full refresh (stop + remove + recreate with latest)"
    echo "3) Create new container (if none exists)"
    echo "4) Show container status"
    echo "5) Show container logs"
    echo "6) Exit"
    echo ""
}

# Main script logic
if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_status
        show_menu
        read -p "Choose an option (1-6): " choice
        echo ""
        
        case $choice in
            1) quick_restart ;;
            2) full_refresh ;;
            3) create_new_container ;;
            4) show_status ;;
            5) show_logs ;;
            6) echo "👋 Goodbye!"; exit 0 ;;
            *) echo "❌ Invalid option. Please choose 1-6." ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
else
    # Command line mode
    case $1 in
        "quick"|"restart") quick_restart ;;
        "full"|"refresh") full_refresh ;;
        "new"|"create") create_new_container ;;
        "status") show_status ;;
        "logs") show_logs ;;
        *)
            echo "Usage: $0 [quick|full|new|status|logs]"
            echo ""
            echo "Commands:"
            echo "  quick    - Pull latest image and restart existing container"
            echo "  full     - Stop, remove, and recreate container with latest image"
            echo "  new      - Create new container (if none exists)"
            echo "  status   - Show current container status"
            echo "  logs     - Show container logs"
            echo ""
            echo "Run without arguments for interactive mode."
            exit 1
            ;;
    esac
fi