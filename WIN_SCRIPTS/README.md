# Windows PowerShell Scripts

This folder contains Windows-specific PowerShell scripts for HTTP Search application management, deployment, and troubleshooting.

## 📁 Script Categories

### 🔧 **Deployment & Setup**
- **`local-deploy-windows.ps1`** - Local Windows deployment script
- **`quick-deploy-windows.ps1`** - Quick Windows deployment helper
- **`fix-ssl-deployment.ps1`** - SSL deployment fixes and corrections

### 🔐 **Certificate Management**
- **`install-trusted-certificate.ps1`** - Install certificates in Windows trust store
- **`setup-proxy-certificate.ps1`** - Configure proxy certificates for router access
- **`troubleshoot-certificate.ps1`** - Diagnose and fix certificate issues

## 🚀 **Usage Instructions**

### Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges (for certificate operations)
- Docker Desktop (for containerized deployments)

### Running Scripts
```powershell
# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run a script
.\WIN_SCRIPTS\local-deploy-windows.ps1

# Or with parameters
.\WIN_SCRIPTS\install-trusted-certificate.ps1 -CertPath ".\certs\production.p12"
```

## 📋 **Script Details**

### Local Deployment
```powershell
# Complete local setup and deployment
.\WIN_SCRIPTS\local-deploy-windows.ps1
```
- Generates SSL certificates
- Builds Docker containers
- Starts services
- Configures Windows firewall

### Certificate Installation
```powershell
# Install certificate in Windows trust store
.\WIN_SCRIPTS\install-trusted-certificate.ps1
```
- Installs certificate for "Not Secure" warning elimination
- Configures browser trust
- Sets up automatic certificate validation

### Troubleshooting
```powershell
# Diagnose common issues
.\WIN_SCRIPTS\troubleshoot-certificate.ps1
```
- Checks certificate validity
- Tests HTTPS connectivity
- Diagnoses common SSL/TLS issues
- Provides fix recommendations

### Proxy Setup
```powershell
# Configure for router proxy access
.\WIN_SCRIPTS\setup-proxy-certificate.ps1
```
- Sets up certificates for public IP access (147.194.240.208)
- Configures router proxy compatibility
- Tests external connectivity

## 🎯 **Common Use Cases**

### First-Time Setup
1. Run `local-deploy-windows.ps1` for complete setup
2. Use `install-trusted-certificate.ps1` to eliminate browser warnings
3. Test with `troubleshoot-certificate.ps1` if issues occur

### Production Deployment
1. Use main deployment scripts in `./scripts/` folder
2. Run `fix-ssl-deployment.ps1` if SSL issues occur
3. Configure proxy with `setup-proxy-certificate.ps1` for external access

### Development
1. Use `quick-deploy-windows.ps1` for rapid testing
2. Use `troubleshoot-certificate.ps1` for debugging

## 🔗 **Related Files**

- **Main Scripts**: `./scripts/` - Cross-platform deployment scripts
- **Certificates**: `./certs/` - SSL certificate storage
- **Documentation**: `./README/` - Detailed deployment guides
- **Docker**: `./docker-compose.yml` - Container configurations

## 💡 **Tips**

- **Run as Administrator**: Most certificate operations require elevated privileges
- **Firewall**: Scripts may prompt to allow firewall exceptions
- **Browser Trust**: Use `install-trusted-certificate.ps1` to avoid "Not Secure" warnings
- **Port Conflicts**: Scripts check for port availability (8080, 8443)

## 🆘 **Troubleshooting**

If scripts fail to run:
1. Check execution policy: `Get-ExecutionPolicy`
2. Enable script execution: `Set-ExecutionPolicy RemoteSigned`
3. Run PowerShell as Administrator
4. Check Windows Defender/antivirus settings

## 📞 **Support**

For issues with these scripts:
- Check the main `README-QUICKSTART.md` for general setup
- Review `./README/` folder for detailed guides
- Use `troubleshoot-certificate.ps1` for automated diagnostics

---

*These scripts are designed for Windows environments and complement the cross-platform scripts in the main `./scripts/` folder.*