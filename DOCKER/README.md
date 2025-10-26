# Docker Configuration Files

This folder contains all Docker-related configuration files for the HTTP Search application.

## 📁 **Files Overview**

### **Core Docker Files**
- **`Dockerfile`** - Multi-stage Docker build configuration
- **`.dockerignore`** - Files and directories to exclude from Docker build context

### **Docker Compose Configurations**
- **`docker-compose.yml`** - Production Docker Compose configuration
- **`docker-compose.dev.yml`** - Development Docker Compose configuration  
- **`docker-compose.prod.yml`** - Alternative production configuration

## 🚀 **Usage Instructions**

### **Building the Docker Image**
```bash
# From project root
docker build -t http-search -f DOCKER/Dockerfile .
```

### **Running with Docker Compose**
```bash
# Production mode
docker-compose -f DOCKER/docker-compose.yml up --build

# Development mode  
docker-compose -f DOCKER/docker-compose.dev.yml up --build

# Detached mode (background)
docker-compose -f DOCKER/docker-compose.yml up -d --build
```

### **Using NPM Scripts** (Recommended)
```bash
# All Docker operations via npm scripts
npm run docker:build      # Build image
npm run docker:run        # Run production compose
npm run docker:dev        # Run development compose
npm run docker:stop       # Stop containers
npm run docker:logs       # View logs
npm run docker:clean      # Clean up containers and images
```

## 🔧 **Configuration Details**

### **Dockerfile Features**
- **Multi-stage build**: Separate builder and production stages
- **Node.js 18 Alpine**: Lightweight base image
- **OpenSSL**: For SSL certificate generation
- **Non-root user**: Security best practices
- **Automatic certificate setup**: Self-generating SSL certificates
- **Health checks**: Container health monitoring

### **Docker Compose Features**
- **Port mapping**: 8080 (HTTP) and 8443 (HTTPS)
- **Environment variables**: Production IP configuration
- **Volume mounts**: Certificate and log persistence
- **Health checks**: Application availability monitoring
- **Automatic restart**: Unless stopped manually

## 🌐 **Environment Variables**

The Docker containers support these environment variables:

```bash
# SSL Configuration
SSL_PASSPHRASE=production123
PFX_PATH=/app/certs/production.p12

# Network Configuration
PUBLIC_IP=[YOUR-PUBLIC-IP]    # Router/proxy IP
INTERNAL_IP=[YOUR-INTERNAL-IP]    # Base server IP

# Server Configuration  
NODE_ENV=production
HTTP_PORT=8080
HTTPS_PORT=8443
```

## 🏗️ **Build Process**

### **Stage 1: Builder**
1. Install Node.js dependencies
2. Install OpenSSL for certificate operations
3. Build Angular application with legacy OpenSSL support
4. Prepare all source files

### **Stage 2: Production**
1. Copy built application from builder stage
2. Set up non-root user for security
3. Create certificate directories
4. Configure health checks
5. Generate SSL certificates on startup

## 📋 **Container Specifications**

### **Resource Usage**
- **Base Image**: node:18-alpine (~40MB)
- **Final Size**: ~775MB (includes all dependencies)
- **Memory**: Typical usage ~200-300MB
- **CPU**: Minimal usage for web serving

### **Ports Exposed**
- **8080**: HTTP server (redirects to HTTPS)
- **8443**: HTTPS server (main application)

### **Volume Mounts**
- **`./certs:/app/certs`**: SSL certificate storage
- **`./logs:/app/logs`**: Application log files

## 🔒 **Security Features**

- **Non-root execution**: Runs as `nextjs` user (UID 1001)
- **SSL/TLS encryption**: Automatic HTTPS with self-signed certificates
- **Minimal attack surface**: Alpine Linux base image
- **Health monitoring**: Automatic container health checks
- **Secure defaults**: Production-ready security configuration

## 🚨 **Troubleshooting**

### **Common Issues**

**Build failures:**
```bash
# Clean build cache
docker system prune -a
npm run docker:clean
npm run docker:build
```

**Certificate issues:**
```bash
# Check certificate generation
docker-compose -f DOCKER/docker-compose.yml logs http-search-app

# Manual certificate setup
npm run setup:certs
```

**Port conflicts:**
```bash
# Check what's using ports
netstat -ano | findstr :8443    # Windows
lsof -i :8443                   # Linux/macOS

# Use different ports
docker-compose -f DOCKER/docker-compose.yml up -p 9080:8080 -p 9443:8443
```

### **Debugging**

```bash
# View logs
npm run docker:logs

# Shell into container
docker exec -it http-search-server sh

# Check container status
docker ps -a
```

## 🔄 **Development Workflow**

### **Local Development**
```bash
# Start development environment
npm run docker:dev

# Make changes to source code
# Container will rebuild automatically
```

### **Production Testing**
```bash
# Test production build locally
npm run docker:run

# Access application
https://localhost:8443
```

### **CI/CD Integration**
The Docker configuration integrates with GitHub Actions for:
- Automated building and testing
- Container registry publishing (ghcr.io)
- Remote deployment automation

## 📞 **Support**

For Docker-related issues:
- Check logs: `npm run docker:logs`
- Review health status: `docker ps`
- Clean and rebuild: `npm run docker:clean && npm run docker:build`
- Consult main documentation in `README/` folder

---

*All Docker configurations are optimized for both development and production use with automatic SSL certificate generation and secure defaults.*