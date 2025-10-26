# Deploy HTTP Search to Windows Base Server
# Run this from your development machine to deploy to the Windows base server

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$CertPassword = "production123"
)

Write-Host "🚀 HTTP Search - Remote Windows Deployment" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Function to create credentials
function Get-Credentials {
    param($Username, $Password, $ServerName)
    
    if ($Password) {
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        return New-Object System.Management.Automation.PSCredential ($Username, $securePassword)
    } else {
        return Get-Credential -UserName $Username -Message "Enter password for $ServerName"
    }
}

try {
    Write-Host "🔐 Setting up credentials for $ServerName..." -ForegroundColor Yellow
    
    $credential = Get-Credentials -Username $Username -Password $Password -ServerName $ServerName
    
    # Test connection
    Write-Host "🔍 Testing connection to $ServerName..." -ForegroundColor Yellow
    
    $testResult = Test-NetConnection -ComputerName $ServerName -Port 5985 -InformationLevel Quiet
    if (-not $testResult) {
        Write-Host "❌ Cannot connect to $ServerName on port 5985 (WinRM)" -ForegroundColor Red
        Write-Host "Ensure WinRM is enabled on the target server:" -ForegroundColor Yellow
        Write-Host "  Enable-PSRemoting -Force" -ForegroundColor Cyan
        exit 1
    }
    
    Write-Host "✓ Connection successful" -ForegroundColor Green
    
    # Create deployment script content
    $deploymentScript = @"
# Set error action preference
`$ErrorActionPreference = "Stop"

# Import the deployment function
function Deploy-HttpSearch {
    param(
        [string]`$CertPassword = "$CertPassword"
    )
    
    Write-Host "🚀 Starting HTTP Search deployment on Windows..." -ForegroundColor Cyan
    
    # Check if running as administrator
    `$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not `$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script must be run as Administrator"
    }
    
    # Download and execute the deployment script
    `$scriptUrl = "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/deploy-windows-server.ps1"
    `$tempScript = "`$env:TEMP\deploy-http-search.ps1"
    
    Write-Host "⬇️ Downloading deployment script..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri `$scriptUrl -OutFile `$tempScript -UseBasicParsing
    
    Write-Host "🚀 Executing deployment..." -ForegroundColor Yellow
    & `$tempScript -ServerName "$ServerName" -CertPassword `$CertPassword
    
    # Clean up
    Remove-Item `$tempScript -Force -ErrorAction SilentlyContinue
    
    Write-Host "✅ Deployment completed!" -ForegroundColor Green
}

# Execute deployment
Deploy-HttpSearch -CertPassword "$CertPassword"
"@

    Write-Host "🚀 Executing deployment on $ServerName..." -ForegroundColor Yellow
    
    # Execute the deployment script on remote server
    $result = Invoke-Command -ComputerName $ServerName -Credential $credential -ScriptBlock {
        param($script)
        Invoke-Expression $script
    } -ArgumentList $deploymentScript
    
    Write-Host "✅ Remote deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Your application should now be accessible at:" -ForegroundColor Cyan
    Write-Host "  • https://$ServerName" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 To manage the application on $ServerName, use:" -ForegroundColor Cyan
    Write-Host "  • View logs:    Invoke-Command -ComputerName $ServerName -Credential `$cred -ScriptBlock { docker logs http-search-production }" -ForegroundColor White
    Write-Host "  • Restart:      Invoke-Command -ComputerName $ServerName -Credential `$cred -ScriptBlock { Set-Location C:\opt\http-search; docker-compose -f docker-compose.windows.yml restart }" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "❌ Remote deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure WinRM is enabled on $ServerName" -ForegroundColor White
    Write-Host "     Run on target server: Enable-PSRemoting -Force" -ForegroundColor Cyan
    Write-Host "  2. Check network connectivity to $ServerName" -ForegroundColor White
    Write-Host "  3. Verify credentials for $Username" -ForegroundColor White
    Write-Host "  4. Ensure target server has Docker Desktop installed" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Copy scripts\deploy-windows-server.ps1 to $ServerName and run it directly" -ForegroundColor Yellow
    
    exit 1
}

Write-Host ""
Read-Host "Press Enter to exit"