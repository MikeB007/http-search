# 🌐 Reverse Proxy SSL Setup Guide

## 📚 Your Setup
- **Internal Server**: `https://192.168.86.40:8443` (your base server)
- **Public Proxy**: `https://147.194.240.208:9090` (internet-facing)
- **Goal**: Make `https://147.194.240.208:9090` show as secure/trusted

## 🎯 The Problem
Your certificate is for `192.168.86.40` but users access `147.194.240.208:9090`, causing "Not Secure" warnings.

## ✅ Solution: Two-Step Process

### **Step 1: Update Internal Server Certificate**
Run this on your **internal server (192.168.86.40)**:

```powershell
# Download and run the proxy certificate setup
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/setup-proxy-certificate.ps1" -OutFile "setup-proxy.ps1"
.\setup-proxy.ps1 -PublicIP "147.194.240.208" -PublicPort "9090" -InternalIP "192.168.86.40" -InternalPort "8443"
```

This creates a certificate that's valid for **both** IPs:
- ✅ `192.168.86.40:8443` (internal)
- ✅ `147.194.240.208:9090` (public)

### **Step 2: Configure Your Proxy Server**

#### **Option A: Use Same Certificate on Proxy (Recommended)**

**Copy the certificate to your proxy server:**
```bash
# Copy from internal server to proxy server
scp root@192.168.86.40:/opt/http-search/certs/proxy-ca.cer /etc/ssl/certs/
scp root@192.168.86.40:/opt/http-search/certs/production.p12 /etc/ssl/private/
```

**Configure your proxy (Nginx example):**
```nginx
server {
    listen 9090 ssl;
    server_name 147.194.240.208;
    
    # Use the same certificate as internal server
    ssl_certificate /etc/ssl/certs/proxy-ca.cer;
    ssl_certificate_key /etc/ssl/private/production.p12;
    
    location / {
        proxy_pass https://192.168.86.40:8443;
        proxy_ssl_verify off;  # Since we trust our internal server
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### **Option B: Apache Proxy Configuration**
```apache
<VirtualHost *:9090>
    ServerName 147.194.240.208
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/proxy-ca.cer
    SSLCertificateKeyFile /etc/ssl/private/production.key
    
    ProxyPreserveHost On
    ProxyPass / https://192.168.86.40:8443/
    ProxyPassReverse / https://192.168.86.40:8443/
    
    # Don't verify internal SSL since we control it
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off
</VirtualHost>
```

#### **Option C: Simple HAProxy Configuration**
```
backend internal_server
    server internal 192.168.86.40:8443 check ssl verify none

frontend public_frontend
    bind *:9090 ssl crt /etc/ssl/private/production.pem
    default_backend internal_server
```

### **Step 3: Install Certificate on Client Computers**

**For each computer that will access the public URL:**

```powershell
# Download and install the certificate as trusted
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/install-trusted-certificate.ps1" -OutFile "install-cert.ps1"
.\install-cert.ps1 -ServerIP "147.194.240.208"
```

**Or manually:**
```powershell
# Copy proxy-ca.cer to client computer, then:
Import-Certificate -FilePath "proxy-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"
```

---

## 🚀 **Quick Setup Commands**

### **On Internal Server (192.168.86.40):**
```powershell
# Create certificate for both internal and public access
$cert = New-SelfSignedCertificate -DnsName "192.168.86.40","147.194.240.208","base","localhost" -CertStoreLocation "cert:\LocalMachine\My" -Subject "CN=147.194.240.208"

# Export for application
$pw = ConvertTo-SecureString -String "production123" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "C:\opt\http-search\certs\production.p12" -Password $pw -Force

# Export for proxy and clients
Export-Certificate -Cert $cert -FilePath "C:\opt\http-search\certs\proxy-ca.cer" -Force

# Install as trusted locally
Import-Certificate -FilePath "C:\opt\http-search\certs\proxy-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"

# Restart container
docker restart http-search-production
```

### **On Proxy Server:**
```bash
# Install the certificate (Linux example)
sudo cp proxy-ca.cer /usr/local/share/ca-certificates/http-search.crt
sudo update-ca-certificates

# Configure your web server to use the certificate
# See examples above for Nginx/Apache/HAProxy
```

### **On Client Computers:**
```powershell
# Windows clients
Import-Certificate -FilePath "proxy-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"
```

---

## 🧪 **Testing the Setup**

1. **Test internal access:**
   ```powershell
   Invoke-WebRequest -Uri "https://192.168.86.40:8443" -UseBasicParsing
   ```

2. **Test public access:**
   ```powershell
   Invoke-WebRequest -Uri "https://147.194.240.208:9090" -UseBasicParsing
   ```

3. **Browser test:**
   - Open browser
   - Go to `https://147.194.240.208:9090`
   - Should show **secure lock icon**
   - No certificate warnings

---

## 🔧 **Troubleshooting**

### **Still seeing "Not Secure"?**

1. **Check certificate includes public IP:**
   ```powershell
   # On internal server
   $cert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*147.194.240.208*" }
   $cert.DnsNameList
   ```

2. **Verify proxy is using correct certificate**
3. **Clear browser cache completely**
4. **Try incognito/private browsing**
5. **Check proxy server logs**

### **Certificate Not Working?**

1. **Ensure certificate includes all needed names:**
   - `147.194.240.208`
   - `192.168.86.40`
   - Any domain names used

2. **Check proxy configuration:**
   - Using correct certificate file
   - Proxy SSL settings correct
   - Backend connection working

---

## ✅ **Expected Result**

After setup:
- ✅ `https://147.194.240.208:9090` shows as **secure**
- ✅ Green lock icon in browser
- ✅ No certificate warnings
- ✅ Users can access your app through the public proxy

The key is that **both the internal server and proxy use the same certificate** that includes both IP addresses! 🎉