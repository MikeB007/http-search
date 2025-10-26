# Quick Fix for SSL Certificate Error on Windows Base Server
# Run this script on your Windows base server to fix the certificate issue

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerIP = "192.168.86.40",
    
    [Parameter(Mandatory=$false)]
    [string]$PublicIP = "147.194.240.208",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123"
)

Write-Host "🔧 Fixing SSL Certificate Issue" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    $DeployPath = "C:\opt\http-search"
    
    # Step 1: Create directories
    Write-Host "📁 Creating directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "$DeployPath\certs" | Out-Null
    New-Item -ItemType Directory -Force -Path "$DeployPath\logs" | Out-Null
    Set-Location $DeployPath

    # Step 2: Stop and remove any existing containers
    Write-Host "🛑 Cleaning up existing containers..." -ForegroundColor Yellow
    docker stop http-search-production 2>$null | Out-Null
    docker rm http-search-production 2>$null | Out-Null
    docker container prune -f 2>$null | Out-Null

    # Step 3: Create SSL certificate
    Write-Host "🔐 Creating SSL certificate..." -ForegroundColor Yellow
    
    # Remove old certificates first
    Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { 
        $_.Subject -like "*base*" -or 
        $_.Subject -like "*$ServerIP*" -or 
        $_.Subject -like "*$PublicIP*"
    } | Remove-Item -Force -ErrorAction SilentlyContinue

    # Create certificate with all needed DNS names/IPs
    $dnsNames = @("base", "localhost", "127.0.0.1", $ServerIP, $PublicIP)
    
    Write-Host "Creating certificate for:" -ForegroundColor Cyan
    $dnsNames | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
    
    $cert = New-SelfSignedCertificate `
        -DnsName $dnsNames `
        -CertStoreLocation "cert:\LocalMachine\My" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddYears(1) `
        -Subject "CN=$PublicIP" `
        -FriendlyName "HTTP Search Certificate"
    
    # Export certificate for Docker (PKCS#12 format)
    $pfxPath = "$DeployPath\certs\production.p12"
    $pw = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pw -Force | Out-Null
    
    Write-Host "✓ Certificate created: $pfxPath" -ForegroundColor Green

    # Verify certificate file exists
    if (Test-Path $pfxPath) {
        $fileSize = (Get-Item $pfxPath).Length
        Write-Host "✓ Certificate file verified: $fileSize bytes" -ForegroundColor Green
    } else {
        Write-Host "❌ Certificate file not created!" -ForegroundColor Red
        exit 1
    }

    # Step 4: Pull latest Docker image
    Write-Host "📦 Pulling latest Docker image..." -ForegroundColor Yellow
    docker pull ghcr.io/mikeb007/http-search:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to pull Docker image" -ForegroundColor Red
        exit 1
    }

    # Step 5: Start container with proper certificate mounting
    Write-Host "🚀 Starting HTTP Search container..." -ForegroundColor Yellow
    
    # Use absolute Windows paths for volume mounting
    $certVolumeMount = "${DeployPath}\certs:/app/certs:ro"
    $logVolumeMount = "${DeployPath}\logs:/app/logs"
    
    Write-Host "Certificate volume: $certVolumeMount" -ForegroundColor Cyan
    Write-Host "Log volume: $logVolumeMount" -ForegroundColor Cyan
    
    $dockerCmd = @"
docker run -d \
  --name http-search-production \
  --restart unless-stopped \
  -p 80:8080 \
  -p 8443:8443 \
  -e NODE_ENV=production \
  -e PFX_PATH=/app/certs/production.p12 \
  -e SSL_PASSPHRASE=$CertPassword \
  -e NODE_OPTIONS=--openssl-legacy-provider \
  -v "$certVolumeMount" \
  -v "$logVolumeMount" \
  ghcr.io/mikeb007/http-search:latest
"@

    # Execute the docker run command
    $result = Invoke-Expression $dockerCmd.Replace('\', '')
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully: $result" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start container" -ForegroundColor Red
        Write-Host "Trying alternative approach..." -ForegroundColor Yellow
        
        # Alternative approach using docker run with individual parameters
        & docker run -d `
            --name http-search-production `
            --restart unless-stopped `
            -p 80:8080 `
            -p 8443:8443 `
            -e NODE_ENV=production `
            -e PFX_PATH=/app/certs/production.p12 `
            -e "SSL_PASSPHRASE=$CertPassword" `
            -e NODE_OPTIONS=--openssl-legacy-provider `
            -v "${DeployPath}\certs:/app/certs:ro" `
            -v "${DeployPath}\logs:/app/logs" `
            ghcr.io/mikeb007/http-search:latest
    }

    # Step 6: Wait and check status
    Write-Host "⏳ Waiting for container to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    # Check container status
    $containerStatus = docker ps --filter "name=http-search-production" --format "{{.Status}}"
    if ($containerStatus) {
        Write-Host "✓ Container is running: $containerStatus" -ForegroundColor Green
    } else {
        Write-Host "❌ Container not running. Checking logs..." -ForegroundColor Red
        docker logs http-search-production --tail 20
        exit 1
    }

    # Check container logs for SSL errors
    Write-Host "📋 Checking container logs..." -ForegroundColor Yellow
    $logs = docker logs http-search-production --tail 10 2>&1
    
    if ($logs -like "*ENOENT*" -or $logs -like "*no such file*") {
        Write-Host "❌ Still seeing certificate errors in logs:" -ForegroundColor Red
        Write-Host $logs -ForegroundColor Red
        
        Write-Host "🔍 Debugging certificate mount..." -ForegroundColor Yellow
        docker exec http-search-production ls -la /app/certs/ 2>$null
        docker exec http-search-production printenv | grep -E "(PFX_PATH|SSL_PASSPHRASE)" 2>$null
        
    } elseif ($logs -like "*HTTPS Server listening*") {
        Write-Host "✅ SUCCESS! HTTPS server is running" -ForegroundColor Green
    } else {
        Write-Host "📋 Container logs:" -ForegroundColor Yellow
        Write-Host $logs -ForegroundColor White
    }

    # Step 7: Test the application
    Write-Host "🧪 Testing application..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    try {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $response = Invoke-WebRequest -Uri "https://localhost:8443" -TimeoutSec 15 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Application is responding successfully!" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Application test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "The container may still be starting up..." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🎉 Deployment Status" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "📍 Local access: https://localhost:8443" -ForegroundColor White
    Write-Host "📍 Network access: https://$ServerIP`:8443" -ForegroundColor White
    Write-Host "📍 Public access: https://$PublicIP`:9090 (if router configured)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
    Write-Host "  docker logs http-search-production" -ForegroundColor White
    Write-Host "  docker ps" -ForegroundColor White
    Write-Host "  docker restart http-search-production" -ForegroundColor White

} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check Docker is running: docker version" -ForegroundColor White
    Write-Host "2. Check certificate files exist in C:\opt\http-search\certs\" -ForegroundColor White
    Write-Host "3. Check container logs: docker logs http-search-production" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"