# 🖥️ Base Server Quick Setup Guide

## 📋 One-Time Server Setup

### 1. Install Docker on Base Server
```bash
# Connect to your base server
ssh admin@base  # Replace with your actual username and server

# Install Docker (Ubuntu/Debian)
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Re-login or run:
newgrp docker

# Test Docker installation
docker --version
docker run hello-world
```

### 2. Setup Deployment Directory
```bash
# Create deployment directory
sudo mkdir -p /opt/http-search/{certs,logs,config}
sudo chown $USER:$USER /opt/http-search -R
cd /opt/http-search
```

### 3. Generate Production Certificate
```bash
# Option A: Self-signed certificate for internal use
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout server.key -out server.crt \
  -subj "/CN=base" \
  -addext "subjectAltName=DNS:base,DNS:base.local,IP:$(hostname -I | awk '{print $1}')"

# Convert to PKCS#12 format
openssl pkcs12 -export \
  -out ./certs/production.p12 \
  -inkey server.key \
  -in server.crt \
  -passout pass:production123

# Cleanup
rm server.key server.crt

# Option B: Copy existing certificate (for testing)
# scp your-dev-machine:/path/to/localhost.p12 ./certs/production.p12
```

### 4. Configure Firewall
```bash
# Ubuntu/Debian with UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH
sudo ufw --force enable

# Check status
sudo ufw status
```

## 🚀 Quick Deployment Methods

### Method 1: Manual Pull and Run (Fastest)
```bash
# Connect to base server
ssh admin@base
cd /opt/http-search

# Pull latest image
docker pull ghcr.io/mikeb007/http-search:latest

# Run container
docker run -d \
  --name http-search-production \
  --restart unless-stopped \
  -p 80:8080 \
  -p 443:8443 \
  -v $(pwd)/certs:/app/certs:ro \
  -v $(pwd)/logs:/app/logs \
  -e NODE_ENV=production \
  -e PFX_PATH=/app/certs/production.p12 \
  -e SSL_PASSPHRASE=production123 \
  ghcr.io/mikeb007/http-search:latest

# Check status
docker ps
docker logs http-search-production
```

### Method 2: Using Docker Compose (Recommended)
```bash
# Download production compose file
wget https://raw.githubusercontent.com/MikeB007/http-search/master/docker-compose.prod.yml

# Start application
SSL_PASSPHRASE=production123 docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

### Method 3: Automated Script from Your Local Machine
```bash
# From your development machine (Windows)
.\scripts\deploy-remote.ps1 -Server "base" -User "admin" -Password "production123"

# From your development machine (Linux/macOS)
./scripts/deploy-remote.sh base admin production123
```

## 🔧 Management Commands

### Application Management
```bash
# View logs
docker logs http-search-production -f

# Restart application
docker restart http-search-production

# Stop application
docker stop http-search-production

# Update to latest version
docker pull ghcr.io/mikeb007/http-search:latest
docker stop http-search-production
docker rm http-search-production
# Re-run the docker run command above
```

### Docker Compose Management
```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart
docker-compose -f docker-compose.prod.yml restart

# Stop
docker-compose -f docker-compose.prod.yml down

# Update and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 🌐 Access Your Application

Once deployed, access your application at:
- **HTTPS**: `https://base` or `https://YOUR_SERVER_IP`
- **HTTP**: `http://base` (automatically redirects to HTTPS)

## 🔍 Troubleshooting

### Check if application is running
```bash
# Check container status
docker ps --filter name=http-search

# Check port listeners
sudo netstat -tulpn | grep :443
sudo netstat -tulpn | grep :80

# Test connectivity
curl -k https://localhost:443
curl -k https://base:443
```

### View logs
```bash
# Application logs
docker logs http-search-production

# System logs
journalctl -u docker -f
```

### Common issues
```bash
# Permission issues with certificates
sudo chown $USER:$USER /opt/http-search/certs/*
chmod 600 /opt/http-search/certs/*

# Port conflicts
sudo lsof -i :443  # See what's using port 443
sudo systemctl stop apache2  # Stop conflicting services
```

## 🔄 Updates

Your application will automatically update when you push changes to GitHub (if CI/CD is configured), or you can manually update using:

```bash
# Pull latest image
docker pull ghcr.io/mikeb007/http-search:latest

# Restart with new image
docker-compose -f docker-compose.prod.yml up -d
```

---

**Note**: Replace `base`, `admin`, and `production123` with your actual server details and secure passwords.