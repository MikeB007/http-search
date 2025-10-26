# Install Self-Signed Certificate as Trusted Root CA
# Run this script on each computer that needs to trust the certificate

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP = "192.168.86.40",
    
    [Parameter(Mandatory=$false)]
    [string]$CertPath = "\\192.168.86.40\c$\opt\http-search\certs\base-ca.cer"
)

Write-Host "🔒 Installing Self-Signed Certificate as Trusted" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

try {
    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "❌ Run PowerShell as Administrator" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Method 1: Download certificate from server
    if (-not (Test-Path $CertPath)) {
        Write-Host "📥 Downloading certificate from server..." -ForegroundColor Yellow
        
        try {
            # Try to download the certificate via HTTPS
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
                param($sender, $certificate, $chain, $sslPolicyErrors)
                
                # Save the certificate to local file
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)
                $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                [System.IO.File]::WriteAllBytes("$env:TEMP\server-cert.cer", $certBytes)
                
                Write-Host "✓ Certificate downloaded from server" -ForegroundColor Green
                return $true  # Accept the certificate for this download
            }
            
            # Make a request to get the certificate
            Invoke-WebRequest -Uri "https://$ServerIP`:8443" -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
            $CertPath = "$env:TEMP\server-cert.cer"
            
        } catch {
            Write-Host "⚠️ Could not download certificate automatically" -ForegroundColor Yellow
        }
    }

    # Method 2: Check if certificate file exists
    if (Test-Path $CertPath) {
        Write-Host "📜 Installing certificate from: $CertPath" -ForegroundColor Yellow
        
        # Import the certificate into Trusted Root store
        Import-Certificate -FilePath $CertPath -CertStoreLocation "cert:\LocalMachine\Root" | Out-Null
        
        Write-Host "✅ Certificate installed successfully!" -ForegroundColor Green
        Write-Host "The certificate is now trusted by this computer." -ForegroundColor Green
        
    } else {
        Write-Host "❌ Certificate file not found: $CertPath" -ForegroundColor Red
        Write-Host ""
        Write-Host "🔧 Manual steps:" -ForegroundColor Yellow
        Write-Host "1. Copy the certificate file from the server" -ForegroundColor White
        Write-Host "2. Run: Import-Certificate -FilePath 'path\to\cert.cer' -CertStoreLocation 'cert:\LocalMachine\Root'" -ForegroundColor Cyan
    }

    # Test the connection
    Write-Host ""
    Write-Host "🧪 Testing HTTPS connection..." -ForegroundColor Yellow
    
    try {
        # Reset the certificate validation callback
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
        
        $response = Invoke-WebRequest -Uri "https://$ServerIP`:8443" -TimeoutSec 10 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ SUCCESS! HTTPS connection is now trusted" -ForegroundColor Green
            Write-Host "You can now access https://$ServerIP`:8443 without certificate warnings" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "⚠️ Connection test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "The certificate may be installed but the server might not be running" -ForegroundColor Yellow
    }

} catch {
    Write-Host "❌ Failed to install certificate: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Verification:" -ForegroundColor Cyan
Write-Host "• Open browser and go to: https://$ServerIP`:8443" -ForegroundColor White
Write-Host "• You should NOT see any certificate warnings" -ForegroundColor White
Write-Host "• The address bar should show a lock icon" -ForegroundColor White

Read-Host "Press Enter to exit"