# Windows Base Server - Quick Deploy Script
# Run this script on your Windows base server to automatically deploy HTTP Search

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "base",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123",
    
    [Parameter(Mandatory=$false)]
    [string]$DeployPath = "C:\opt\http-search"
)

Write-Host "🚀 HTTP Search - Windows Server Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    # Step 1: Check Docker installation
    Write-Host "🔍 Checking Docker installation..." -ForegroundColor Yellow
    
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker is not installed or not running" -ForegroundColor Red
        Write-Host "Please install Docker Desktop for Windows first:" -ForegroundColor Yellow
        Write-Host "https://www.docker.com/products/docker-desktop/" -ForegroundColor Blue
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
    
    # Step 2: Create deployment directories
    Write-Host "📁 Creating deployment directories..." -ForegroundColor Yellow
    
    $directories = @("$DeployPath", "$DeployPath\certs", "$DeployPath\logs", "$DeployPath\config")
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            Write-Host "✓ Created: $dir" -ForegroundColor Green
        } else {
            Write-Host "✓ Exists: $dir" -ForegroundColor Green
        }
    }
    
    # Step 3: Download Docker Compose file
    Write-Host "⬇️ Downloading Docker Compose configuration..." -ForegroundColor Yellow
    
    $composeUrl = "https://raw.githubusercontent.com/MikeB007/http-search/master/DOCKER/docker-compose.yml"
    $composePath = "$DeployPath\docker-compose.yml"
    
    try {
        Invoke-WebRequest -Uri $composeUrl -OutFile $composePath -UseBasicParsing
        Write-Host "✓ Downloaded docker-compose.yml" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download compose file: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 4: Create Windows-optimized compose file
    Write-Host "📝 Creating Windows-optimized compose file..." -ForegroundColor Yellow
    
    $windowsCompose = @"
version: '3.8'

services:
  http-search-app:
    image: ghcr.io/mikeb007/http-search:latest
    container_name: http-search-production
    restart: unless-stopped
    ports:
      - "80:8080"    # HTTP redirect
      - "8443:8443"  # HTTPS main port
    environment:
      - NODE_ENV=production
      - PFX_PATH=/app/certs/production.p12
      - SSL_PASSPHRASE=$CertPassword
      - NODE_OPTIONS=--openssl-legacy-provider
    volumes:
      # Windows paths - using bind mounts
      - type: bind
        source: $DeployPath\certs
        target: /app/certs
        read_only: true
      - type: bind
        source: $DeployPath\logs
        target: /app/logs
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
"@
    
    $windowsCompose | Out-File -FilePath "$DeployPath\docker-compose.windows.yml" -Encoding UTF8
    Write-Host "✓ Created Windows-optimized compose file" -ForegroundColor Green
    
    # Step 5: Create SSL Certificate
    Write-Host "🔐 Creating SSL certificate..." -ForegroundColor Yellow
    
    $certPath = "$DeployPath\certs\production.p12"
    if (Test-Path $certPath) {
        Write-Host "⚠️ Certificate already exists. Recreating..." -ForegroundColor Yellow
        Remove-Item $certPath -Force
    }
    
    try {
        # Create certificate with multiple DNS names
        $dnsNames = @($ServerName, "localhost", "127.0.0.1")
        $cert = New-SelfSignedCertificate -DnsName $dnsNames -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1) -Subject "CN=$ServerName"
        
        # Export certificate
        $pw = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
        Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $pw | Out-Null
        
        Write-Host "✓ SSL certificate created successfully" -ForegroundColor Green
        Write-Host "  Certificate valid for: $($dnsNames -join ', ')" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ Failed to create certificate: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 6: Configure Windows Firewall
    Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
    
    try {
        # Remove existing rules if they exist
        Remove-NetFirewallRule -DisplayName "HTTP Search - HTTP" -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -ErrorAction SilentlyContinue
        
        # Create new firewall rules
        New-NetFirewallRule -DisplayName "HTTP Search - HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow | Out-Null
        New-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -Direction Inbound -Protocol TCP -LocalPort 8443 -Action Allow | Out-Null
        
        Write-Host "✓ Firewall rules configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not configure firewall: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You may need to manually allow ports 80 and 443" -ForegroundColor Yellow
    }
    
    # Step 7: Stop existing container if running
    Write-Host "🛑 Stopping existing container (if any)..." -ForegroundColor Yellow
    
    Set-Location $DeployPath
    docker-compose -f docker-compose.windows.yml down 2>$null
    
    # Step 8: Pull latest image and start application
    Write-Host "📦 Pulling latest application image..." -ForegroundColor Yellow
    
    docker pull ghcr.io/mikeb007/http-search:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to pull Docker image" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "🚀 Starting HTTP Search application..." -ForegroundColor Yellow
    
    docker-compose -f docker-compose.windows.yml up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to start application" -ForegroundColor Red
        Write-Host "Check Docker logs for details:" -ForegroundColor Yellow
        Write-Host "docker logs http-search-production" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Step 9: Wait for application to be ready
    Write-Host "⏳ Waiting for application to start..." -ForegroundColor Yellow
    
    $maxWait = 60
    $waited = 0
    $healthy = $false
    
    while ($waited -lt $maxWait -and -not $healthy) {
        Start-Sleep -Seconds 2
        $waited += 2
        
        $containerStatus = docker inspect http-search-production --format "{{.State.Health.Status}}" 2>$null
        if ($containerStatus -eq "healthy") {
            $healthy = $true
        }
        
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($healthy) {
        Write-Host "✅ Application is healthy and ready!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Application started but health check is pending..." -ForegroundColor Yellow
    }
    
    # Step 10: Test the application
    Write-Host "🧪 Testing application..." -ForegroundColor Yellow
    
        try {
            # Ignore SSL certificate validation for testing
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            $response = Invoke-WebRequest -Uri "https://localhost:8443" -TimeoutSec 10 -UseBasicParsing        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Application responding successfully!" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Application responding with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Could not test application: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 11: Display deployment information
    Write-Host ""
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
        Write-Host "📍 Application URLs:" -ForegroundColor Cyan
        Write-Host "  • https://$ServerName:8443" -ForegroundColor White
        Write-Host "  • https://localhost:8443" -ForegroundColor White
        
        # Get server IP addresses
        $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | Select-Object -ExpandProperty IPAddress
        foreach ($ip in $ipAddresses) {
            Write-Host "  • https://$ip:8443" -ForegroundColor White
        }    Write-Host ""
    Write-Host "📂 Deployment files located at:" -ForegroundColor Cyan
    Write-Host "  $DeployPath" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Management commands:" -ForegroundColor Cyan
    Write-Host "  • View logs:    docker logs http-search-production" -ForegroundColor White
    Write-Host "  • Restart app:  docker-compose -f docker-compose.windows.yml restart" -ForegroundColor White
    Write-Host "  • Stop app:     docker-compose -f docker-compose.windows.yml down" -ForegroundColor White
    Write-Host "  • Update app:   docker-compose -f docker-compose.windows.yml pull && docker-compose -f docker-compose.windows.yml up -d" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️ Note: You'll see a security warning in your browser due to the self-signed certificate." -ForegroundColor Yellow
    Write-Host "   Click 'Advanced' → 'Continue to $ServerName (unsafe)' to access the application." -ForegroundColor Yellow
    
} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure Docker Desktop is running" -ForegroundColor White
    Write-Host "  2. Check internet connectivity" -ForegroundColor White
    Write-Host "  3. Verify you're running as Administrator" -ForegroundColor White
    Write-Host "  4. Check Docker logs: docker logs http-search-production" -ForegroundColor White
    
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Read-Host "Press Enter to exit"