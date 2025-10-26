# Remote deployment script for HTTP Search application (Windows PowerShell)
# Usage: .\deploy-remote.ps1 -Server "base" -User "admin" -Password "production123"

param(
    [string]$Server = "base",
    [string]$User = "admin", 
    [string]$Password = "production123",
    [switch]$Help
)

# Configuration
$ImageName = "ghcr.io/mikeb007/http-search:latest"
$DeployDir = "/opt/http-search"
$ContainerName = "http-search-production"

function Write-Step {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Header {
    Write-Host @"
╔══════════════════════════════════════════════════════╗
║          HTTP Search Remote Deployment              ║
╚══════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue
}

function Invoke-RemoteCommand {
    param([string]$Command)
    
    try {
        $result = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$User@$Server" $Command
        return $result
    }
    catch {
        throw "Failed to execute remote command: $Command"
    }
}

function Copy-ToRemote {
    param([string]$LocalPath, [string]$RemotePath)
    
    try {
        scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no $LocalPath "$User@${Server}:$RemotePath"
    }
    catch {
        throw "Failed to copy $LocalPath to $RemotePath"
    }
}

function Show-Usage {
    Write-Host @"
Usage: .\deploy-remote.ps1 [-Server <server>] [-User <user>] [-Password <password>] [-Help]

Parameters:
  -Server      Remote server hostname or IP (default: base)
  -User        SSH username (default: admin)
  -Password    SSL certificate password (default: production123)
  -Help        Show this help message

Examples:
  .\deploy-remote.ps1                                    # Deploy to base server with defaults
  .\deploy-remote.ps1 -Server "192.168.1.100"           # Deploy to specific IP
  .\deploy-remote.ps1 -Server "base" -User "ubuntu" -Password "mypassword"  # Custom settings

Prerequisites:
  • SSH client installed (OpenSSH or Git Bash)
  • SSH access to target server
  • Docker installed on target server
  • docker-compose.prod.yml in current directory
"@
}

function Start-Deployment {
    Write-Header
    
    Write-Info "Deploying to: $User@$Server"
    Write-Info "Target directory: $DeployDir"
    Write-Info "Container image: $ImageName"
    Write-Host ""
    
    try {
        # Step 1: Test connection
        Write-Info "Step 1: Testing connection to remote server..."
        $null = ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$Server" "exit" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Cannot connect to $Server as $User"
            Write-Info "Make sure:"
            Write-Info "1. Server is accessible: ping $Server"
            Write-Info "2. SSH is configured: ssh $User@$Server"
            Write-Info "3. SSH keys are set up for passwordless login"
            return $false
        }
        Write-Step "Connection successful"
        
        # Step 2: Check Docker installation
        Write-Info "Step 2: Checking Docker installation..."
        $dockerCheck = Invoke-RemoteCommand "command -v docker >/dev/null 2>&1; echo `$?"
        if ($dockerCheck -ne "0") {
            Write-Error "Docker is not installed on remote server"
            Write-Info "Please install Docker first:"
            Write-Info "curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
            return $false
        }
        Write-Step "Docker is installed"
        
        # Step 3: Create deployment directory
        Write-Info "Step 3: Creating deployment directory..."
        Invoke-RemoteCommand "sudo mkdir -p $DeployDir/{certs,logs,config} && sudo chown `$USER:`$USER $DeployDir -R"
        Write-Step "Deployment directory ready"
        
        # Step 4: Copy deployment files
        Write-Info "Step 4: Copying deployment files..."
        Copy-ToRemote "docker-compose.prod.yml" "$DeployDir/"
        
        # Copy certificate if it exists locally
        if (Test-Path ".\certs\localhost.p12") {
            Copy-ToRemote ".\certs\localhost.p12" "$DeployDir/certs/production.p12"
            Write-Step "Certificate copied (using development cert for testing)"
            Write-Warning "Replace with production certificate for live deployment"
        }
        else {
            Write-Warning "No certificate found - you'll need to generate one on the server"
        }
        
        Write-Step "Files copied successfully"
        
        # Step 5: Pull Docker image
        Write-Info "Step 5: Pulling Docker image..."
        Invoke-RemoteCommand "cd $DeployDir && docker pull $ImageName"
        Write-Step "Docker image pulled"
        
        # Step 6: Stop existing container
        Write-Info "Step 6: Stopping existing container..."
        Invoke-RemoteCommand "cd $DeployDir && docker-compose -f docker-compose.prod.yml down 2>/dev/null || true"
        Write-Step "Existing container stopped"
        
        # Step 7: Start new container
        Write-Info "Step 7: Starting new container..."
        Invoke-RemoteCommand "cd $DeployDir && SSL_PASSPHRASE='$Password' docker-compose -f docker-compose.prod.yml up -d"
        
        # Wait for container to start
        Start-Sleep -Seconds 10
        
        # Step 8: Verify deployment
        Write-Info "Step 8: Verifying deployment..."
        $containerCheck = Invoke-RemoteCommand "docker ps --filter name=$ContainerName --filter status=running | grep -q $ContainerName; echo `$?"
        if ($containerCheck -eq "0") {
            Write-Step "Container is running"
            
            # Test health check
            try {
                $healthCheck = Invoke-RemoteCommand "docker exec $ContainerName node -e `"require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) process.exit(0); else process.exit(1); }).on('error', () => process.exit(1));`""
                Write-Step "Health check passed"
            }
            catch {
                Write-Warning "Health check failed - check application logs"
            }
        }
        else {
            Write-Error "Container failed to start"
            Invoke-RemoteCommand "cd $DeployDir && docker-compose -f docker-compose.prod.yml logs"
            return $false
        }
        
        # Step 9: Show deployment info
        Write-Info "Step 9: Deployment complete!"
        Write-Host ""
        Write-Host "🎉 Deployment Summary:" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        Write-Host "Server: https://$Server"
        Write-Host "HTTP:   http://$Server (redirects to HTTPS)"
        Write-Host "Container: $ContainerName"
        Write-Host "Image: $ImageName"
        Write-Host ""
        Write-Host "Management commands:"
        Write-Host "• View logs:    ssh $User@$Server 'cd $DeployDir && docker-compose -f docker-compose.prod.yml logs -f'"
        Write-Host "• Stop app:     ssh $User@$Server 'cd $DeployDir && docker-compose -f docker-compose.prod.yml down'"
        Write-Host "• Restart app:  ssh $User@$Server 'cd $DeployDir && docker-compose -f docker-compose.prod.yml restart'"
        Write-Host "• Update app:   .\deploy-remote.ps1 -Server $Server -User $User"
        Write-Host ""
        
        # Show container status
        Write-Info "Current container status:"
        $containerStatus = Invoke-RemoteCommand "docker ps --filter name=$ContainerName --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        Write-Host $containerStatus
        
        return $true
    }
    catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
if ($Help) {
    Show-Usage
    exit 0
}

$success = Start-Deployment

if ($success) {
    Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
    exit 1
}