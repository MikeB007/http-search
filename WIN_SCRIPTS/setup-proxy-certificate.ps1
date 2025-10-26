# Reverse Proxy SSL Certificate Setup
# For accessing internal server through public proxy
# Internal: https://192.168.86.40:8443
# Public: https://147.194.240.208:9090

param(
    [Parameter(Mandatory=$false)]
    [string]$PublicIP = "147.194.240.208",
    
    [Parameter(Mandatory=$false)]
    [string]$PublicPort = "9090",
    
    [Parameter(Mandatory=$false)]
    [string]$InternalIP = "192.168.86.40",
    
    [Parameter(Mandatory=$false)]
    [string]$InternalPort = "8443",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123"
)

Write-Host "🌐 Reverse Proxy SSL Certificate Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Public URL: https://$PublicIP`:$PublicPort" -ForegroundColor Yellow
Write-Host "Internal URL: https://$InternalIP`:$InternalPort" -ForegroundColor Yellow
Write-Host ""

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    $DeployPath = "C:\opt\http-search"
    
    # Create directories
    New-Item -ItemType Directory -Force -Path "$DeployPath\certs" | Out-Null
    Set-Location $DeployPath

    # Stop existing container
    Write-Host "🛑 Stopping existing container..." -ForegroundColor Yellow
    docker stop http-search-production 2>$null | Out-Null
    docker rm http-search-production 2>$null | Out-Null

    # Create certificate for BOTH public and internal access
    Write-Host "🔐 Creating SSL certificate for proxy setup..." -ForegroundColor Yellow
    
    # Remove old certificates
    Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*base*" -or $_.Subject -like "*$PublicIP*" } | Remove-Item -Force -ErrorAction SilentlyContinue

    # Create certificate with ALL DNS names/IPs that will be used
    $dnsNames = @(
        "base",
        "localhost", 
        "127.0.0.1",
        $InternalIP,
        $PublicIP,
        "$PublicIP`:$PublicPort",
        "$InternalIP`:$InternalPort"
    )
    
    Write-Host "Creating certificate for these names:" -ForegroundColor Cyan
    $dnsNames | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }
    
    $cert = New-SelfSignedCertificate `
        -DnsName $dnsNames `
        -CertStoreLocation "cert:\LocalMachine\My" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddYears(1) `
        -Subject "CN=$PublicIP" `
        -FriendlyName "HTTP Search Proxy Certificate"
    
    # Export certificate for Docker application
    $pw = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    $pfxPath = "$DeployPath\certs\production.p12"
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pw -Force | Out-Null
    
    # Export public certificate for client trust
    $publicCertPath = "$DeployPath\certs\proxy-ca.cer"
    Export-Certificate -Cert $cert -FilePath $publicCertPath -Force | Out-Null
    
    Write-Host "✓ Certificate created successfully" -ForegroundColor Green
    Write-Host "✓ Public certificate: $publicCertPath" -ForegroundColor Green

    # Install certificate as trusted on this server
    Write-Host "🔒 Installing certificate as trusted..." -ForegroundColor Yellow
    Import-Certificate -FilePath $publicCertPath -CertStoreLocation "cert:\LocalMachine\Root" -Force | Out-Null
    Write-Host "✓ Certificate installed as trusted" -ForegroundColor Green

    # Start container with new certificate
    Write-Host "🚀 Starting HTTP Search container..." -ForegroundColor Yellow
    
    $dockerArgs = @(
        "run", "-d",
        "--name", "http-search-production",
        "--restart", "unless-stopped",
        "-p", "80:8080",
        "-p", "$InternalPort`:8443",
        "-e", "NODE_ENV=production",
        "-e", "PFX_PATH=/app/certs/production.p12",
        "-e", "SSL_PASSPHRASE=$CertPassword",
        "-e", "NODE_OPTIONS=--openssl-legacy-provider",
        "-v", "$DeployPath\certs:/app/certs:ro",
        "-v", "$DeployPath\logs:/app/logs",
        "ghcr.io/mikeb007/http-search:latest"
    )
    
    docker pull ghcr.io/mikeb007/http-search:latest
    & docker @dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container started successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start container" -ForegroundColor Red
        exit 1
    }

    # Wait for startup
    Write-Host "⏳ Waiting for application to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    # Test internal access
    Write-Host "🧪 Testing internal access..." -ForegroundColor Yellow
    try {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
        $response = Invoke-WebRequest -Uri "https://$InternalIP`:$InternalPort" -TimeoutSec 10 -UseBasicParsing
        Write-Host "✅ Internal access working: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Internal test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "🎉 Proxy SSL Certificate Setup Complete!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Application URLs:" -ForegroundColor Cyan
    Write-Host "  • Internal: https://$InternalIP`:$InternalPort" -ForegroundColor White
    Write-Host "  • Public: https://$PublicIP`:$PublicPort (via proxy)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔒 Certificate Files:" -ForegroundColor Cyan
    Write-Host "  • Application cert: $pfxPath" -ForegroundColor White
    Write-Host "  • Public cert for trust: $publicCertPath" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Next Steps for Proxy Server:" -ForegroundColor Cyan
    Write-Host "1. Copy $publicCertPath to your proxy server" -ForegroundColor Yellow
    Write-Host "2. Install it as trusted root CA on proxy server" -ForegroundColor Yellow
    Write-Host "3. Configure proxy to use the same certificate" -ForegroundColor Yellow
    Write-Host "4. Distribute certificate to client computers" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 Client Computer Setup:" -ForegroundColor Cyan
    Write-Host "Run this on each client computer (as Administrator):" -ForegroundColor White
    Write-Host "Import-Certificate -FilePath 'proxy-ca.cer' -CertStoreLocation 'cert:\LocalMachine\Root'" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Setup failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"