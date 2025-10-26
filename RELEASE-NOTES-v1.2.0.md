# Release Notes - v1.2.0 🚀

**Release Date:** October 26, 2025  
**Stability:** Stable Release  
**Compatibility:** Node.js 18+, Windows/Linux/Docker  

## 🎯 **Major Improvements**

### 🔐 **SSL Certificate Compatibility**
- ✅ **Node.js 18+ SSL Support**: Updated certificate generation for modern Node.js compatibility
- ✅ **PEM Fallback Mechanism**: Automatic fallback to PEM format when PKCS12 fails
- ✅ **Enhanced Error Handling**: Improved certificate loading with retry logic
- ✅ **Cross-Platform Certificates**: Works consistently across Windows, Linux, and Docker

### 🐳 **Docker Build Performance**
- ⚡ **5x Faster Builds**: Optimized from 15-20 minutes to 3-5 minutes
- 🔧 **npm Install Optimizations**: Disabled audit/fund checks, added --force flags
- 📦 **Package Lock Sync**: Fixed sync issues between package.json and package-lock.json
- 🚀 **Reliable Builds**: Eliminated build failures and timeout issues

### 🖥️ **Windows PowerShell Support**
- ✅ **Execution Policy Fix**: Automated PowerShell execution policy configuration
- ✅ **Cross-Platform Environment Variables**: Added cross-env for Windows compatibility
- ✅ **npm Script Compatibility**: All npm commands now work in Windows PowerShell
- ✅ **Legacy OpenSSL Provider**: Added support for Angular 12 + Node.js 22

### 📁 **Project Organization**
- 📂 **WIN_SCRIPTS Folder**: Centralized Windows PowerShell helper scripts
- 🐳 **DOCKER Folder**: Organized Docker configuration files
- 🔧 **Updated References**: All scripts and workflows updated for new structure
- 📋 **Comprehensive Documentation**: Added README files for each folder

## 🛠️ **Technical Details**

### **SSL Certificate Generation**
```bash
# Automatic certificate creation with Node.js 18+ compatibility
openssl pkcs12 -export -legacy -macalg sha1 ...
```

### **Docker Optimizations**
```dockerfile
# Faster npm installs
RUN npm config set fund false && \
    npm config set audit false && \
    npm install --force --no-optional --production=false
```

### **Windows PowerShell Support**
```json
{
  "start": "cross-env NODE_OPTIONS=\"--openssl-legacy-provider\" ng serve"
}
```

## 🎛️ **Configuration**

### **Environment Variables**
- `SSL_PASSPHRASE`: Certificate password (default: production123)
- `NODE_ENV`: Environment mode (development/production)
- `PUBLIC_IP`: Public server IP for certificate generation
- `INTERNAL_IP`: Internal server IP for certificate generation

### **Ports**
- **HTTP**: 8080 (redirects to HTTPS)
- **HTTPS**: 8443 (main application)

## 🚀 **Getting Started**

### **Development (Windows)**
```powershell
npm install
npm start                    # Angular dev server
npm run serve:https         # HTTPS server with SSL
```

### **Production (Docker)**
```bash
npm run docker:build       # Build Docker image
npm run docker:run         # Run with Docker Compose
```

### **Deployment**
```bash
# Local deployment
npm run setup:certs && npm run serve:https

# Docker deployment
docker-compose -f DOCKER/docker-compose.yml up -d
```

## 🔄 **Migration from Previous Versions**

### **PowerShell Users**
1. Update execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
2. Install updated dependencies: `npm install`
3. Test with: `npm start`

### **Docker Users**
1. Rebuild images: `npm run docker:build`
2. Update compose files to reference `DOCKER/` folder
3. Test deployment: `npm run docker:run`

## 🐛 **Bug Fixes**

- Fixed SSL certificate loading errors in Node.js 18+
- Resolved Docker build package-lock sync issues
- Fixed Windows PowerShell execution policy blocking
- Corrected GitHub Actions Docker file path references
- Fixed cross-env version compatibility with Node.js 18

## ⚠️ **Breaking Changes**

- **Docker file paths**: Docker files moved to `DOCKER/` folder
- **PowerShell scripts**: Moved to `WIN_SCRIPTS/` folder  
- **Certificate format**: Now generates both PKCS12 and PEM formats

## 🔮 **What's Next**

- Enhanced monitoring and logging
- Kubernetes deployment configurations
- Additional security hardening
- Performance monitoring integration

---

**Full Changelog**: [View on GitHub](https://github.com/MikeB007/http-search/compare/v1.1.0...v1.2.0)  
**Docker Image**: `ghcr.io/mikeb007/http-search:v1.2.0`  
**Documentation**: Updated README files in project folders