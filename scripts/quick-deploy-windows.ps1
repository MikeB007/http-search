# Quick Deploy and Test Script for Windows Base Server
# Run this script directly on your Windows base server

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "192.168.86.40",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123"
)

Write-Host "🚀 HTTP Search - Quick Windows Deploy & Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$DeployPath = "C:\opt\http-search"

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 1: Create directories
    Write-Host "📁 Creating directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "$DeployPath\certs" | Out-Null
    New-Item -ItemType Directory -Force -Path "$DeployPath\logs" | Out-Null
    Set-Location $DeployPath

    # Step 2: Stop any existing container
    Write-Host "🛑 Stopping existing containers..." -ForegroundColor Yellow
    docker stop http-search-production 2>$null
    docker rm http-search-production 2>$null

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
    
    Write-Host "✓ Certificate created for: $($dnsNames -join ', ')" -ForegroundColor Green

    # Step 4: Create simple docker run command (easier than compose for testing)
    Write-Host "🚀 Starting HTTP Search container..." -ForegroundColor Yellow

    $dockerCmd = @"
docker run -d ``
  --name http-search-production ``
  --restart unless-stopped ``
  -p 80:8080 ``
  -p 443:8443 ``
  -e NODE_ENV=production ``
  -e PFX_PATH=/app/certs/production.p12 ``
  -e SSL_PASSPHRASE=$CertPassword ``
  -e NODE_OPTIONS=--openssl-legacy-provider ``
  -v "$DeployPath\certs:/app/certs:ro" ``
  -v "$DeployPath\logs:/app/logs" ``
  ghcr.io/mikeb007/http-search:latest
"@

    Write-Host "Executing: $dockerCmd" -ForegroundColor Cyan
    
    # Pull latest image first
    docker pull ghcr.io/mikeb007/http-search:latest
    
    # Run the container
    Invoke-Expression $dockerCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start container" -ForegroundColor Red
        exit 1
    }

    # Step 5: Wait and test
    Write-Host "⏳ Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Check container logs
    Write-Host "📋 Container logs:" -ForegroundColor Yellow
    docker logs http-search-production

    # Test the application
    Write-Host "🧪 Testing application..." -ForegroundColor Yellow
    
    try {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $response = Invoke-WebRequest -Uri "https://localhost:443" -TimeoutSec 15 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SUCCESS! Application is responding" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Application responding with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Checking if container is still running..." -ForegroundColor Yellow
        docker ps --filter "name=http-search-production"
    }

    # Step 6: Configure firewall
    Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
    
    Remove-NetFirewallRule -DisplayName "HTTP Search - HTTP" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -ErrorAction SilentlyContinue
    
    New-NetFirewallRule -DisplayName "HTTP Search - HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "HTTP Search - HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow | Out-Null
    
    Write-Host "✓ Firewall configured" -ForegroundColor Green

    # Final status
    Write-Host ""
    Write-Host "🎉 Deployment completed!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Access your application:" -ForegroundColor Cyan
    Write-Host "  • https://localhost" -ForegroundColor White
    Write-Host "  • https://$ServerIP" -ForegroundColor White
    Write-Host "  • https://base (if DNS is configured)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
    Write-Host "  • Check status:    docker ps" -ForegroundColor White
    Write-Host "  • View logs:       docker logs http-search-production" -ForegroundColor White
    Write-Host "  • Restart:         docker restart http-search-production" -ForegroundColor White
    Write-Host "  • Stop:            docker stop http-search-production" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Debug information:" -ForegroundColor Yellow
    Write-Host "Docker version:" -ForegroundColor White
    docker --version
    Write-Host ""
    Write-Host "Container status:" -ForegroundColor White
    docker ps -a --filter "name=http-search"
    Write-Host ""
    Write-Host "Recent container logs:" -ForegroundColor White
    docker logs http-search-production --tail 20 2>$null
}

Write-Host ""
Read-Host "Press Enter to exit"