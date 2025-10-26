# HTTP Search Application - Quick Start Guide

![HTTP Search](https://img.shields.io/badge/HTTP-Search-blue) ![Node.js](https://img.shields.io/badge/Node.js-22.21.0-green) ![Angular](https://img.shields.io/badge/Angular-12-red) ![Docker](https://img.shields.io/badge/Docker-Ready-blue)

A fully automated HTTPS-enabled Angular application with Node.js backend, featuring automatic SSL certificate generation and multi-environment deployment support.

## 🚀 Quick Start (One-Command Launch)

### Option 1: Automatic Setup + Start
```bash
npm run serve:auto
```
This command will:
- ✅ Automatically generate SSL certificates
- ✅ Set up environment variables  
- ✅ Start the HTTPS server
- ✅ Display all access URLs

### Option 2: Docker (Recommended for Production)
```bash
npm run docker:run
```
This command will:
- ✅ Build Docker container with automatic certificate generation
- ✅ Configure production environment variables
- ✅ Start with proper IP configuration (internal: 192.168.86.40, public: 147.194.240.208)
- ✅ Set up health checks and auto-restart

### Option 3: Production Ready
```bash
npm run prod:docker
```
This command runs with full production configuration including:
- ✅ Public IP: 147.194.240.208 (router proxy)
- ✅ Internal IP: 192.168.86.40 (base server)
- ✅ Production-grade SSL certificates
- ✅ Automatic port forwarding support

## 🌐 Access URLs

After starting the application, it will be available at:

| Environment | URL | Description |
|-------------|-----|-------------|
| **Local Development** | https://localhost:8443 | Direct HTTPS access |
| **Local HTTP** | http://localhost:8080 | Redirects to HTTPS |
| **Internal Network** | https://192.168.86.40:8443 | Base server access |
| **Public Access** | https://147.194.240.208:9090 | Router proxy → :8443 |

## 📋 Prerequisites

- **Node.js** 18+ (tested with 22.21.0)
- **Docker** (optional, but recommended)
- **OpenSSL** (auto-installed in Docker, may need manual install on Windows)

## 🔐 SSL Certificate Details

The application automatically generates self-signed SSL certificates that are:

- ✅ **Valid for multiple hosts**: localhost, 127.0.0.1, base, configured IPs
- ✅ **Cross-platform compatible**: Works on Windows, Linux, macOS
- ✅ **Docker-optimized**: Auto-generated inside containers
- ✅ **Production-ready**: Configurable for public/internal IP addresses

### Certificate Information
- **File**: `./certs/production.p12`
- **Password**: `production123`
- **Format**: PKCS#12 (supports both PFX and PEM)
- **Validity**: 1 year from generation

## 🛠️ Manual Setup (If Needed)

### 1. Install Dependencies
```bash
npm install
```

### 2. Generate SSL Certificates
```bash
npm run setup:certs
```

### 3. Build Angular Application
```bash
npm run build:prod
```

### 4. Start HTTPS Server
```bash
npm run serve:https
```

## 🐳 Docker Options

### Development Mode
```bash
npm run docker:dev
```
- Mounts source code for live development
- Includes Angular dev server on port 4200
- Auto-reloads on file changes

### Production Mode (Background)
```bash
npm run docker:run:detached
```
- Runs containers in background
- Production-optimized build
- Automatic restarts on failure

### View Logs
```bash
npm run docker:logs
```

### Stop All Containers
```bash
npm run docker:stop
```

### Clean Everything
```bash
npm run docker:clean
```

## 🔧 Configuration

### Environment Variables

The application supports these environment variables:

```bash
# SSL Configuration
SSL_PASSPHRASE=production123
PFX_PATH=./certs/production.p12

# Network Configuration  
PUBLIC_IP=147.194.240.208    # Router/proxy IP
INTERNAL_IP=192.168.86.40    # Base server IP

# Server Configuration
NODE_ENV=production
HTTP_PORT=8080
HTTPS_PORT=8443
```

### Docker Environment Files

Create a `.env` file for Docker Compose:
```bash
SSL_PASSPHRASE=production123
PUBLIC_IP=147.194.240.208
INTERNAL_IP=192.168.86.40
```

## 🔒 Security Notes

### Self-Signed Certificates
- ⚠️ Browsers will show "Not Secure" warning
- This is **normal** for self-signed certificates
- Click "Advanced" → "Proceed to localhost" to continue
- For production, consider using Let's Encrypt or commercial certificates

### Certificate Trust (Optional)
To avoid browser warnings, you can:

1. **Install certificate in browser** (Chrome/Edge)
2. **Add to system trust store** (Windows/macOS)
3. **Use certificate distribution script** (see deployment folder)

## 📁 Project Structure

```
http-search/
├── 📁 src/                     # Angular application source
├── 📁 scripts/                 # Automation scripts
│   └── setup-certificates.js   # Auto SSL cert generation
├── 📁 certs/                   # SSL certificates (auto-generated)
├── 📁 deployment/              # Production deployment scripts
├── 📁 README/                  # Documentation files
├── 🐳 Dockerfile              # Container definition
├── 🐳 docker-compose.yml      # Production container setup
├── 🐳 docker-compose.dev.yml  # Development container setup
├── ⚡ server.js               # HTTPS Node.js server
├── ⚡ start-application.js    # Auto-setup launcher
└── 📄 package.json            # NPM scripts and dependencies
```

## 🚨 Troubleshooting

### Certificate Issues
```bash
# Regenerate certificates
npm run setup:certs

# Check certificate details
openssl pkcs12 -info -in certs/production.p12 -noout
```

### Port Conflicts
```bash
# Check what's using port 8443
netstat -ano | findstr :8443    # Windows
lsof -i :8443                   # Linux/macOS

# Stop conflicting services
npm run docker:stop
```

### Container Issues
```bash
# Rebuild containers from scratch
npm run docker:clean
npm run docker:run

# View detailed logs
docker logs http-search-server
```

### Network Access Issues
```bash
# Test internal access
curl -k https://192.168.86.40:8443

# Test public access (through router)
curl -k https://147.194.240.208:9090

# Check firewall (Windows)
netsh advfirewall firewall show rule name="HTTP Search"
```

## 🎯 Production Deployment

For production deployment on the base server (192.168.86.40):

1. **Clone repository** on target server
2. **Run automatic setup**:
   ```bash
   npm run prod:docker
   ```
3. **Configure router** port forwarding: 9090 → 8443
4. **Verify access** from both internal and external networks

## 📞 Support

For deployment issues or questions:
- Check the `README/` folder for detailed guides
- View `deployment/` scripts for Windows-specific setup
- Check Docker logs: `npm run docker:logs`
- Review certificate generation: `node scripts/setup-certificates.js`

---

## ⚡ TL;DR - One Command Start

```bash
# Install and start everything automatically
npm install && npm run serve:auto
```

**That's it!** 🎉 Your HTTPS application is now running with automatic SSL certificates!

Access it at: **https://localhost:8443**