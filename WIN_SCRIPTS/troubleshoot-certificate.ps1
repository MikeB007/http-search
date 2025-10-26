# Troubleshoot Certificate Trust Issues
# Run these commands to diagnose and fix certificate trust problems

Write-Host "🔍 Certificate Trust Troubleshooting" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Step 1: Check if certificate exists in Personal store
Write-Host "1. Checking certificates in Personal store..." -ForegroundColor Yellow
$personalCerts = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*base*" -or $_.Subject -like "*192.168.86.40*" }
if ($personalCerts) {
    Write-Host "✓ Found certificates in Personal store:" -ForegroundColor Green
    $personalCerts | ForEach-Object {
        Write-Host "  Subject: $($_.Subject)" -ForegroundColor White
        Write-Host "  DNS Names: $($_.DnsNameList -join ', ')" -ForegroundColor White
        Write-Host "  Thumbprint: $($_.Thumbprint)" -ForegroundColor White
        Write-Host "  Valid Until: $($_.NotAfter)" -ForegroundColor White
        Write-Host ""
    }
    $cert = $personalCerts[0]
} else {
    Write-Host "❌ No certificates found in Personal store" -ForegroundColor Red
    Write-Host "Need to recreate the certificate first" -ForegroundColor Yellow
    exit 1
}

# Step 2: Check if certificate exists in Trusted Root store
Write-Host "2. Checking certificates in Trusted Root store..." -ForegroundColor Yellow
$trustedCerts = Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
if ($trustedCerts) {
    Write-Host "✓ Certificate found in Trusted Root store" -ForegroundColor Green
} else {
    Write-Host "❌ Certificate NOT found in Trusted Root store" -ForegroundColor Red
    Write-Host "Installing it now..." -ForegroundColor Yellow
    
    # Export and import the certificate
    $certPath = "C:\opt\http-search\certs\base-ca.cer"
    Export-Certificate -Cert $cert -FilePath $certPath -Force | Out-Null
    Import-Certificate -FilePath $certPath -CertStoreLocation "cert:\LocalMachine\Root" | Out-Null
    Write-Host "✓ Certificate installed in Trusted Root store" -ForegroundColor Green
}

# Step 3: Check certificate DNS names
Write-Host "3. Checking certificate DNS names..." -ForegroundColor Yellow
$dnsNames = $cert.DnsNameList.Unicode
Write-Host "Certificate is valid for these names:" -ForegroundColor Cyan
$dnsNames | ForEach-Object { Write-Host "  • $_" -ForegroundColor White }

$serverIP = "192.168.86.40"
if ($dnsNames -contains $serverIP) {
    Write-Host "✓ Certificate includes server IP: $serverIP" -ForegroundColor Green
} else {
    Write-Host "❌ Certificate does NOT include server IP: $serverIP" -ForegroundColor Red
    Write-Host "Need to recreate certificate with correct DNS names" -ForegroundColor Yellow
    
    # Recreate certificate with correct DNS names
    Write-Host "Creating new certificate with correct DNS names..." -ForegroundColor Yellow
    $newCert = New-SelfSignedCertificate -DnsName "base","localhost","127.0.0.1",$serverIP -CertStoreLocation "cert:\LocalMachine\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1) -Subject "CN=base"
    
    # Export for application
    $pw = ConvertTo-SecureString -String "production123" -Force -AsPlainText
    Export-PfxCertificate -Cert $newCert -FilePath "C:\opt\http-search\certs\production.p12" -Password $pw -Force | Out-Null
    
    # Export and install as trusted
    Export-Certificate -Cert $newCert -FilePath "C:\opt\http-search\certs\base-ca.cer" -Force | Out-Null
    Import-Certificate -FilePath "C:\opt\http-search\certs\base-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root" -Force | Out-Null
    
    Write-Host "✓ New certificate created and installed" -ForegroundColor Green
    
    # Restart container to use new certificate
    Write-Host "Restarting container to use new certificate..." -ForegroundColor Yellow
    docker restart http-search-production
    Start-Sleep 5
}

# Step 4: Test certificate validation
Write-Host "4. Testing certificate validation..." -ForegroundColor Yellow

# Reset certificate validation callback
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

try {
    $response = Invoke-WebRequest -Uri "https://$serverIP`:8443" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ HTTPS connection successful without certificate override!" -ForegroundColor Green
        Write-Host "Certificate should now be trusted" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ HTTPS connection failed: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*certificate*" -or $_.Exception.Message -like "*SSL*") {
        Write-Host "This is still a certificate trust issue" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🔧 Additional steps to try:" -ForegroundColor Cyan
        Write-Host "1. Close ALL browser windows completely" -ForegroundColor White
        Write-Host "2. Clear browser cache and cookies" -ForegroundColor White
        Write-Host "3. Restart the browser" -ForegroundColor White
        Write-Host "4. Try incognito/private browsing mode" -ForegroundColor White
        Write-Host "5. Try a different browser" -ForegroundColor White
        Write-Host ""
        Write-Host "6. If using Chrome, type: chrome://restart in address bar" -ForegroundColor White
        Write-Host "7. If using Edge, restart completely and try again" -ForegroundColor White
    }
}

# Step 5: Browser-specific instructions
Write-Host ""
Write-Host "📱 Browser-Specific Instructions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔷 Chrome:" -ForegroundColor Blue
Write-Host "  1. Type chrome://settings/certificates in address bar" -ForegroundColor White
Write-Host "  2. Click 'Manage certificates'" -ForegroundColor White
Write-Host "  3. Go to 'Trusted Root Certification Authorities' tab" -ForegroundColor White
Write-Host "  4. Look for your certificate (Subject: CN=base)" -ForegroundColor White
Write-Host "  5. If not there, import C:\opt\http-search\certs\base-ca.cer" -ForegroundColor White
Write-Host ""
Write-Host "🔷 Edge:" -ForegroundColor Blue
Write-Host "  1. Type edge://settings/privacy in address bar" -ForegroundColor White
Write-Host "  2. Click 'Manage certificates'" -ForegroundColor White
Write-Host "  3. Same steps as Chrome above" -ForegroundColor White
Write-Host ""
Write-Host "🔷 Firefox:" -ForegroundColor Blue
Write-Host "  1. Type about:preferences#privacy in address bar" -ForegroundColor White
Write-Host "  2. Scroll to 'Certificates' section" -ForegroundColor White
Write-Host "  3. Click 'View Certificates'" -ForegroundColor White
Write-Host "  4. Go to 'Authorities' tab" -ForegroundColor White
Write-Host "  5. Click 'Import' and select base-ca.cer" -ForegroundColor White

# Step 6: Final verification
Write-Host ""
Write-Host "🧪 Final Test URLs:" -ForegroundColor Cyan
Write-Host "Try accessing these URLs in your browser:" -ForegroundColor White
Write-Host "  • https://$serverIP`:8443" -ForegroundColor Yellow
Write-Host "  • https://localhost:8443 (if testing from server)" -ForegroundColor Yellow
Write-Host "  • https://base:8443 (if DNS configured)" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Success indicators:" -ForegroundColor Green
Write-Host "  • Lock icon in address bar" -ForegroundColor White
Write-Host "  • No security warnings" -ForegroundColor White
Write-Host "  • 'Secure' or 'Connection is secure' message" -ForegroundColor White

Write-Host ""
Read-Host "Press Enter to exit"