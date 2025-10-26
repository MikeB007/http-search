# Local HTTP Search Deployment Script for Windows Base Server
# Run this script directly on your Windows base server (192.168.86.40)

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "192.168.86.40",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123"
)

Write-Host "🚀 HTTP Search - Windows Server Deployment (Local)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$DeployPath = "C:\opt\http-search"

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Check Docker
    Write-Host "🔍 Checking Docker..." -ForegroundColor Yellow
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker not found. Install Docker Desktop for Windows first." -ForegroundColor Red
        Write-Host "Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Blue
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green

    # Step 1: Create directories
    Write-Host "📁 Creating directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "$DeployPath\certs" | Out-Null
    New-Item -ItemType Directory -Force -Path "$DeployPath\logs" | Out-Null
    Set-Location $DeployPath
    Write-Host "✓ Directories created" -ForegroundColor Green

    # Step 2: Stop any existing container
    Write-Host "🛑 Stopping existing containers..." -ForegroundColor Yellow
    docker stop http-search-production 2>$null | Out-Null
    docker rm http-search-production 2>$null | Out-Null
    Write-Host "✓ Cleanup completed" -ForegroundColor Green

    # Step 3: Create SSL certificate
    Write-Host "🔐 Creating SSL certificate..." -ForegroundColor Yellow
    $certPath = "$DeployPath\certs\production.p12"
    
    if (Test-Path $certPath) {
        Remove-Item $certPath -Force
    }

    # Create certificate with server IP
    $dnsNames = @("base", "localhost", "127.0.0.1", $ServerIP)
    $cert = New-SelfSignedCertificate -DnsName $dnsNames -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1)
    
    $pw = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $pw | Out-Null
    
    # Export public certificate for client trust
    $publicCertPath = "$DeployPath\certs\base-ca.cer"
    Export-Certificate -Cert $cert -FilePath $publicCertPath | Out-Null
    
    Write-Host "✓ Certificate created for: $($dnsNames -join ', ')" -ForegroundColor Green
    Write-Host "✓ Public certificate exported to: $publicCertPath" -ForegroundColor Green
    
    # Optionally install certificate as trusted on this server
    try {
        Import-Certificate -FilePath $publicCertPath -CertStoreLocation "cert:\LocalMachine\Root" | Out-Null
        Write-Host "✓ Certificate installed as trusted on this server" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not auto-install as trusted: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Step 4: Pull Docker image
    Write-Host "📦 Pulling latest Docker image..." -ForegroundColor Yellow
    docker pull ghcr.io/mikeb007/http-search:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to pull Docker image" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host "✓ Image pulled successfully" -ForegroundColor Green

    # Step 5: Start container
    Write-Host "🚀 Starting HTTP Search container..." -ForegroundColor Yellow

    $dockerArgs = @(
        "run", "-d",
        "--name", "http-search-production",
        "--restart", "unless-stopped",
        "-p", "80:8080",
        "-p", "8443:8443",
        "-e", "NODE_ENV=production",
        "-e", "PFX_PATH=/app/certs/production.p12",
        "-e", "SSL_PASSPHRASE=$CertPassword",
        "-e", "NODE_OPTIONS=--openssl-legacy-provider",
        "-v", "$DeployPath\certs:/app/certs:ro",
        "-v", "$DeployPath\logs:/app/logs",
        "ghcr.io/mikeb007/http-search:latest"
    )

    Write-Host "Executing: docker $($dockerArgs -join ' ')" -ForegroundColor Cyan
    
    & docker @dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start container" -ForegroundColor Red
        docker logs http-search-production 2>$null
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 6: Configure firewall
    Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
    
    try {
        Remove-NetFirewallRule -DisplayName "HTTP Search - HTTP" -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -ErrorAction SilentlyContinue
        
        New-NetFirewallRule -DisplayName "HTTP Search - HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow | Out-Null
        New-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -Direction Inbound -Protocol TCP -LocalPort 8443 -Action Allow | Out-Null
        
        Write-Host "✓ Firewall configured" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not configure firewall: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Step 7: Wait and test
    Write-Host "⏳ Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    # Check container status
    $containerStatus = docker inspect http-search-production --format "{{.State.Status}}" 2>$null
    Write-Host "Container status: $containerStatus" -ForegroundColor Cyan

    # Show container logs
    Write-Host "📋 Container logs:" -ForegroundColor Yellow
    docker logs http-search-production --tail 10

    # Test the application
    Write-Host "🧪 Testing application..." -ForegroundColor Yellow
    
    try {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        
        $response = Invoke-WebRequest -Uri "https://localhost:8443" -TimeoutSec 15 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SUCCESS! Application is responding" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Application responding with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This might be normal if the app is still starting up." -ForegroundColor Yellow
    }

    # Final status
    Write-Host ""
    Write-Host "🎉 Deployment completed!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Access your application:" -ForegroundColor Cyan
    Write-Host "  • https://localhost:8443" -ForegroundColor White
    Write-Host "  • https://$ServerIP`:8443" -ForegroundColor White
    Write-Host "  • http://$ServerIP (redirects to HTTPS)" -ForegroundColor White
    Write-Host ""
    Write-Host "� Certificate Information:" -ForegroundColor Cyan
    Write-Host "  • Certificate auto-installed as trusted on this server" -ForegroundColor Green
    Write-Host "  • Public certificate: C:\opt\http-search\certs\base-ca.cer" -ForegroundColor White
    Write-Host "  • To trust on other computers, copy base-ca.cer and install it" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "�🔧 Useful commands:" -ForegroundColor Cyan
    Write-Host "  • Check status:    docker ps" -ForegroundColor White
    Write-Host "  • View logs:       docker logs http-search-production" -ForegroundColor White
    Write-Host "  • Follow logs:     docker logs http-search-production -f" -ForegroundColor White
    Write-Host "  • Restart:         docker restart http-search-production" -ForegroundColor White
    Write-Host "  • Stop:            docker stop http-search-production" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️ For other computers to trust the certificate:" -ForegroundColor Yellow
    Write-Host "   1. Copy C:\opt\http-search\certs\base-ca.cer to the client computer" -ForegroundColor Yellow
    Write-Host "   2. Run: Import-Certificate -FilePath 'base-ca.cer' -CertStoreLocation 'cert:\LocalMachine\Root'" -ForegroundColor Cyan
    Write-Host "   3. Or use the install-trusted-certificate.ps1 script" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Debug information:" -ForegroundColor Yellow
    Write-Host "Docker version:" -ForegroundColor White
    docker --version 2>$null
    Write-Host ""
    Write-Host "Container status:" -ForegroundColor White
    docker ps -a --filter "name=http-search" 2>$null
    Write-Host ""
    Write-Host "Recent container logs:" -ForegroundColor White
    docker logs http-search-production --tail 20 2>$null
}

Write-Host ""
Read-Host "Press Enter to exit"