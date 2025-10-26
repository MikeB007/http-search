# 🌐 Remote Server Deployment Guide - "base" Server

This guide will help you deploy the HTTP Search application to your "base" server using Docker.

## 📋 Prerequisites on Base Server

### 1. Install Docker and Docker Compose
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (requires re-login)
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### 2. Verify Docker Installation
```bash
docker --version
docker-compose --version
docker run hello-world
```

## 🚀 Deployment Methods

### Method 1: Pull from GitHub Container Registry (Recommended)

Once your GitHub Actions pipeline completes, your image will be available publicly. 

#### Step 1: Pull the Image
```bash
# Pull the latest image
docker pull ghcr.io/mikeb007/http-search:latest

# Or pull a specific version
docker pull ghcr.io/mikeb007/http-search:master-<commit-sha>
```

#### Step 2: Create Production Docker Compose
Create `docker-compose.prod.yml` on base server:
```yaml
version: '3.8'

services:
  http-search-app:
    image: ghcr.io/mikeb007/http-search:latest
    container_name: http-search-production
    restart: unless-stopped
    ports:
      - "80:8080"    # HTTP redirect
      - "443:8443"   # HTTPS main port
    environment:
      - NODE_ENV=production
      - PFX_PATH=/app/certs/production.p12
      - SSL_PASSPHRASE=${SSL_PASSPHRASE}
    volumes:
      # Mount production certificates
      - ./certs:/app/certs:ro
      # Mount logs for monitoring
      - ./logs:/app/logs
    networks:
      - http-search-network
    healthcheck:
      test: ["CMD", "node", "-e", "require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) process.exit(0); else process.exit(1); }).on('error', () => process.exit(1));"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  http-search-network:
    driver: bridge

volumes:
  app-data:
```

#### Step 3: Setup Production Certificates
```bash
# Create certificates directory
mkdir -p certs logs

# Option A: Copy your existing development certificate (for testing)
scp your-dev-machine:/path/to/localhost.p12 ./certs/production.p12

# Option B: Generate new certificate for your domain
# See "Production Certificate Setup" section below
```

#### Step 4: Deploy
```bash
# Set SSL password (replace with your actual password)
export SSL_PASSPHRASE="your-production-password"

# Deploy the application
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

### Method 2: Build Locally on Base Server

#### Step 1: Clone Repository
```bash
git clone https://github.com/MikeB007/http-search.git
cd http-search
```

#### Step 2: Build and Deploy
```bash
# Build the image locally
docker build -t http-search-local .

# Run with local image
docker run -d \
  --name http-search-production \
  -p 80:8080 \
  -p 443:8443 \
  -v $(pwd)/certs:/app/certs:ro \
  -e NODE_ENV=production \
  -e PFX_PATH=/app/certs/production.p12 \
  -e SSL_PASSPHRASE="your-password" \
  http-search-local
```

## 🔐 Production Certificate Setup

### Option 1: Let's Encrypt (Free SSL Certificate)
```bash
# Install Certbot
sudo apt install certbot

# Generate certificate for your domain
sudo certbot certonly --standalone -d your-domain.com

# Convert to PKCS#12 format
sudo openssl pkcs12 -export \
  -out ./certs/production.p12 \
  -inkey /etc/letsencrypt/live/your-domain.com/privkey.pem \
  -in /etc/letsencrypt/live/your-domain.com/fullchain.pem \
  -passout pass:your-secure-password

# Set appropriate permissions
sudo chown $USER:$USER ./certs/production.p12
chmod 600 ./certs/production.p12
```

### Option 2: Self-Signed Certificate for Internal Network
```bash
# Generate self-signed certificate for base server
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout base-server.key -out base-server.crt \
  -subj "/CN=base" \
  -addext "subjectAltName=DNS:base,DNS:base.local,IP:YOUR_BASE_SERVER_IP"

# Convert to PKCS#12
openssl pkcs12 -export \
  -out ./certs/production.p12 \
  -inkey base-server.key \
  -in base-server.crt \
  -passout pass:your-secure-password

# Clean up temporary files
rm base-server.key base-server.crt
```

## 🔧 Network Configuration

### Firewall Setup
```bash
# Ubuntu/Debian with UFW
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# CentOS/RHEL with firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

### Port Verification
```bash
# Check if ports are listening
sudo netstat -tulpn | grep :443
sudo netstat -tulpn | grep :80

# Test connectivity from another machine
curl -k https://base:443
curl http://base:80
```

## 📊 Monitoring and Maintenance

### Health Checks
```bash
# Check application health
curl -k -I https://base:443

# Check Docker container status
docker ps --filter "name=http-search"

# View logs
docker logs http-search-production -f

# Check resource usage
docker stats http-search-production
```

### Updates and Rollbacks
```bash
# Update to latest version
docker pull ghcr.io/mikeb007/http-search:latest
docker-compose -f docker-compose.prod.yml up -d

# Rollback to previous version
docker pull ghcr.io/mikeb007/http-search:previous-tag
docker-compose -f docker-compose.prod.yml up -d

# View available image tags
docker images ghcr.io/mikeb007/http-search
```

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied on Certificate Files**
   ```bash
   sudo chown $USER:$USER ./certs/*
   chmod 600 ./certs/*
   ```

2. **Port Already in Use**
   ```bash
   # Find what's using the port
   sudo lsof -i :443
   sudo lsof -i :80
   
   # Stop conflicting services
   sudo systemctl stop apache2  # or nginx
   ```

3. **Container Won't Start**
   ```bash
   # Check detailed logs
   docker logs http-search-production
   
   # Debug with interactive shell
   docker run -it --rm ghcr.io/mikeb007/http-search:latest sh
   ```

4. **Network Connectivity Issues**
   ```bash
   # Test from base server
   curl -k https://localhost:443
   
   # Test from other machines
   ping base
   telnet base 443
   ```

### Log Locations
- Application logs: `./logs/` (if volume mounted)
- Docker logs: `docker logs http-search-production`
- System logs: `/var/log/syslog` or `journalctl -u docker`

## 🚀 Access Your Application

Once deployed, your application will be available at:
- **HTTPS**: `https://base:443` or `https://your-domain.com`
- **HTTP**: `http://base:80` (redirects to HTTPS)

## 🔄 Automated Deployment (Optional)

For automated deployments, see the separate SSH automation script that can be integrated with your CI/CD pipeline.

---

**Note**: Replace `base`, `your-domain.com`, and `your-password` with your actual server details and secure passwords.