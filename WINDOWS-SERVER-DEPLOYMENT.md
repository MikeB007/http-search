# 🪟 Windows Server Deployment Guide for HTTP Search

## 📚 What We're Doing
Installing and running your HTTP Search application on your Windows "base" server using Docker Desktop for Windows.

## 🎯 End Goal
- HTTP Search application running on Windows server
- Accessible via `https://base` or `https://server-ip`
- Professional HTTPS security
- Automatic startup with Windows

---

## 📋 Prerequisites on Windows Base Server

### Step 1: Install Docker Desktop for Windows

#### Download and Install
1. **Download Docker Desktop**:
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click "Download for Windows"
   - Run the installer as Administrator

2. **During Installation**:
   - ✅ Enable "Use WSL 2 instead of Hyper-V" (recommended)
   - ✅ Add shortcut to desktop

3. **After Installation**:
   - Restart your computer when prompted
   - Docker Desktop should start automatically

#### Verify Installation
```powershell
# Open PowerShell as Administrator and test
docker --version
docker run hello-world
```

### Step 2: Enable Required Windows Features
```powershell
# Run PowerShell as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName containers -All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

---

## 🚀 Deploy Your Application on Windows

### Step 3: Create Deployment Directory
```powershell
# Create directory structure
New-Item -ItemType Directory -Force -Path "C:\opt\http-search\certs"
New-Item -ItemType Directory -Force -Path "C:\opt\http-search\logs"
New-Item -ItemType Directory -Force -Path "C:\opt\http-search\config"

# Navigate to deployment directory
Set-Location "C:\opt\http-search"
```

### Step 4: Download Docker Compose File
```powershell
# Download the production compose file using PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/docker-compose.prod.yml" -OutFile "docker-compose.prod.yml"
```

**What this does:**
- `Invoke-WebRequest` is PowerShell's equivalent to `wget`
- Downloads the Docker Compose configuration file
- Saves it as `docker-compose.prod.yml` in current directory

### Step 5: Create SSL Certificate (Windows PowerShell Method)
```powershell
# Create self-signed certificate using PowerShell
$cert = New-SelfSignedCertificate -DnsName "base", "localhost", "127.0.0.1" -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1)

# Set certificate password
$pw = ConvertTo-SecureString -String "production123" -Force -AsPlainText

# Export to PKCS#12 format
Export-PfxCertificate -Cert $cert -FilePath "C:\opt\http-search\certs\production.p12" -Password $pw

Write-Host "✓ Certificate created successfully"
```

**What this does:**
- Creates a self-signed SSL certificate valid for 1 year
- Certificate works for "base", "localhost", and "127.0.0.1"
- Exports to PKCS#12 format (.p12 file) that your application can use
- Password is set to "production123"

### Step 6: Update Docker Compose for Windows Paths
Create a Windows-specific compose file:

```powershell
# Create Windows-optimized docker-compose file
@"
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
      - SSL_PASSPHRASE=production123
    volumes:
      # Windows paths - note the forward slashes in container paths
      - C:/opt/http-search/certs:/app/certs:ro
      - C:/opt/http-search/logs:/app/logs
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
"@ | Out-File -FilePath "docker-compose.windows.yml" -Encoding UTF8
```

### Step 7: Start Your Application
```powershell
# Start the application using the Windows compose file
docker-compose -f docker-compose.windows.yml up -d
```

**What happens:**
1. Docker downloads your application image from GitHub
2. Creates a container named "http-search-production"
3. Maps Windows paths to container paths
4. Starts the application in background (-d flag)
5. Sets up networking and health checks

---

## 🔍 Verify Everything is Working

### Step 8: Check Application Status
```powershell
# Check if container is running
docker ps

# View application logs
docker logs http-search-production

# Check Docker Compose services
docker-compose -f docker-compose.windows.yml ps
```

**What to look for:**
- Container status should be "Up" and "healthy"
- Logs should show "HTTPS Server listening on port 8443"

### Step 9: Test the Application
```powershell
# Test from PowerShell (ignore certificate warnings)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$response = Invoke-WebRequest -Uri "https://localhost:443"
Write-Host "Response Status: $($response.StatusCode)"

# Test health check
docker exec http-search-production node -e "require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) console.log('✓ App is healthy'); else console.log('❌ App has issues'); }).on('error', () => console.log('❌ Connection failed'));"
```

### Step 10: Configure Windows Firewall
```powershell
# Allow HTTP and HTTPS through Windows Firewall
New-NetFirewallRule -DisplayName "HTTP Search - HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

Write-Host "✓ Firewall rules added"
```

---

## 🌐 Access Your Application

### From Any Web Browser
1. Open web browser
2. Go to: `https://base` or `https://your-server-ip`
3. You'll see a security warning (self-signed certificate)
4. Click "Advanced" → "Continue to base (unsafe)"
5. Your HTTP Search application should load!

### From Network Computers
- `https://base` (if DNS is configured)
- `https://192.168.1.100` (replace with actual server IP)

---

## 🛠️ Managing Your Application (Windows Commands)

### View Live Logs
```powershell
# See real-time logs
docker-compose -f docker-compose.windows.yml logs -f
# Press Ctrl+C to stop viewing
```

### Restart Application
```powershell
# Restart the application
docker-compose -f docker-compose.windows.yml restart
```

### Stop Application
```powershell
# Stop the application
docker-compose -f docker-compose.windows.yml down
```

### Update Application
```powershell
# Pull latest version and restart
docker-compose -f docker-compose.windows.yml pull
docker-compose -f docker-compose.windows.yml up -d
```

### Start on Windows Boot
```powershell
# Make Docker Desktop start with Windows (usually enabled by default)
# Ensure "Start Docker Desktop when you log in" is checked in Docker Desktop settings

# Verify auto-start is configured
docker-compose -f docker-compose.windows.yml up -d
```

---

## 🔧 Windows-Specific Troubleshooting

### Docker Desktop Issues
```powershell
# Restart Docker Desktop
Stop-Process -Name "Docker Desktop" -Force
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

### WSL 2 Backend Issues
```powershell
# Update WSL 2
wsl --update

# Restart WSL
wsl --shutdown
```

### Port Conflicts (IIS or other services)
```powershell
# Check what's using ports 80/443
netstat -ano | findstr :80
netstat -ano | findstr :443

# Stop IIS if it's running
Stop-Service -Name W3SVC -Force
Set-Service -Name W3SVC -StartupType Disabled
```

### Certificate Issues
```powershell
# Recreate certificate if needed
Remove-Item "C:\opt\http-search\certs\production.p12" -Force
# Then re-run Step 5 above
```

---

## 🔒 Windows Security Considerations

### Antivirus Exclusions
Add these to your antivirus exclusions:
- `C:\Program Files\Docker\`
- `C:\opt\http-search\`
- Docker Desktop processes

### Windows Updates
- Schedule restarts during maintenance windows
- Docker containers will auto-restart after reboot

---

## 🚀 Alternative: Automated PowerShell Deployment

Instead of manual steps, you can use the automated script:

```powershell
# From your development machine, deploy to Windows base server
# (Requires SSH or PowerShell remoting to be enabled on base server)
.\scripts\deploy-remote.ps1 -Server "base" -User "Administrator" -Password "production123"
```

---

## 📞 Quick Reference Commands

```powershell
# Status
docker ps
docker-compose -f docker-compose.windows.yml ps

# Logs  
docker logs http-search-production
docker-compose -f docker-compose.windows.yml logs -f

# Management
docker-compose -f docker-compose.windows.yml restart  # Restart
docker-compose -f docker-compose.windows.yml down     # Stop
docker-compose -f docker-compose.windows.yml up -d    # Start

# Update
docker-compose -f docker-compose.windows.yml pull && docker-compose -f docker-compose.windows.yml up -d
```

---

## 🎉 Success!

Your HTTP Search application should now be running on your Windows base server and accessible via HTTPS from any computer on your network!

**Next Steps:**
- Access via `https://base` from your network
- Set up a real SSL certificate for production use
- Configure automatic backups
- Monitor application logs

Need help with any of these steps? Let me know! 🚀