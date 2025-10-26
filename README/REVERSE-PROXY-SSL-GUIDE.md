# 🌐 Reverse Proxy SSL Setup Guide

## 📚 Your Setup
- **Internal Server**: `https://[INTERNAL-IP]:8443` (your base server)
- **Public Proxy**: `https://[PUBLIC-IP]:9090` (internet-facing)
- **Goal**: Make `https://[PUBLIC-IP]:9090` show as secure/trusted

## 🎯 The Problem
Your certificate is for `[INTERNAL-IP]` but users access `[PUBLIC-IP]:9090`, causing "Not Secure" warnings.

## ✅ Solution: Two-Step Process

### **Step 1: Update Internal Server Certificate**
Run this on your **internal server ([INTERNAL-IP])**:

```powershell
# Download and run the proxy certificate setup
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/setup-proxy-certificate.ps1" -OutFile "setup-proxy.ps1"
.\setup-proxy.ps1 -PublicIP "[PUBLIC-IP]" -PublicPort "9090" -InternalIP "[INTERNAL-IP]" -InternalPort "8443"
```

This creates a certificate that's valid for **both** IPs:
- ✅ `[INTERNAL-IP]:8443` (internal)
- ✅ `[PUBLIC-IP]:9090` (public)

### **Step 2: Configure Your Proxy Server**

#### **Option A: Use Same Certificate on Proxy (Recommended)**

**Copy the certificate to your proxy server:**
```bash
# Copy from internal server to proxy server
scp root@[INTERNAL-IP]:/opt/http-search/certs/proxy-ca.cer /etc/ssl/certs/
scp root@[INTERNAL-IP]:/opt/http-search/certs/production.p12 /etc/ssl/private/
```

**Configure your proxy (Nginx example):**
```nginx
server {
    listen 9090 ssl;
    server_name [PUBLIC-IP];
    
    # Use the same certificate as internal server
    ssl_certificate /etc/ssl/certs/proxy-ca.cer;
    ssl_certificate_key /etc/ssl/private/production.p12;
    
    location / {
        proxy_pass https://[INTERNAL-IP]:8443;
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
    ServerName [PUBLIC-IP]
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/proxy-ca.cer
    SSLCertificateKeyFile /etc/ssl/private/production.key
    
    ProxyPreserveHost On
    ProxyPass / https://[INTERNAL-IP]:8443/
    ProxyPassReverse / https://[INTERNAL-IP]:8443/
    
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
    server internal [INTERNAL-IP]:8443 check ssl verify none

frontend public_frontend
    bind *:9090 ssl crt /etc/ssl/private/production.pem
    default_backend internal_server
```

### **Step 3: Install Certificate on Client Computers**

**For each computer that will access the public URL:**

```powershell
# Download and install the certificate as trusted
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/install-trusted-certificate.ps1" -OutFile "install-cert.ps1"
.\install-cert.ps1 -ServerIP "[PUBLIC-IP]"
```

**Or manually:**
```powershell
# Copy proxy-ca.cer to client computer, then:
Import-Certificate -FilePath "proxy-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"
```

---

## 🚀 **Quick Setup Commands**

### **On Internal Server ([INTERNAL-IP]):**
```powershell
# Create certificate for both internal and public access
$cert = New-SelfSignedCertificate -DnsName "[INTERNAL-IP]","[PUBLIC-IP]","base","localhost" -CertStoreLocation "cert:\LocalMachine\My" -Subject "CN=[PUBLIC-IP]"

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
   Invoke-WebRequest -Uri "https://[INTERNAL-IP]:8443" -UseBasicParsing
   ```

2. **Test public access:**
   ```powershell
   Invoke-WebRequest -Uri "https://[PUBLIC-IP]:9090" -UseBasicParsing
   ```

3. **Browser test:**
   - Open browser
   - Go to `https://[PUBLIC-IP]:9090`
   - Should show **secure lock icon**
   - No certificate warnings

---

## 🔧 **Troubleshooting**

### **Still seeing "Not Secure"?**

1. **Check certificate includes public IP:**
   ```powershell
   # On internal server
   $cert = Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*[PUBLIC-IP]*" }
   $cert.DnsNameList
   ```

2. **Verify proxy is using correct certificate**
3. **Clear browser cache completely**
4. **Try incognito/private browsing**
5. **Check proxy server logs**

### **Certificate Not Working?**

1. **Ensure certificate includes all needed names:**
   - `[PUBLIC-IP]`
   - `[INTERNAL-IP]`
   - Any domain names used

2. **Check proxy configuration:**
   - Using correct certificate file
   - Proxy SSL settings correct
   - Backend connection working

---

## ✅ **Expected Result**

After setup:
- ✅ `https://[PUBLIC-IP]:9090` shows as **secure**
- ✅ Green lock icon in browser
- ✅ No certificate warnings
- ✅ Users can access your app through the public proxy

The key is that **both the internal server and proxy use the same certificate** that includes both IP addresses! 🎉