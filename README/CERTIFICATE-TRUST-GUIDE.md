# 🔒 Making Self-Signed Certificates Trusted - Complete Guide

## 📚 Overview
By default, browsers show security warnings for self-signed certificates. This guide shows how to make your HTTP Search certificate trusted so users won't see those warnings.

## 🎯 Three Methods to Trust the Certificate

### **Method 1: Automatic (During Deployment)**
The deployment script automatically installs the certificate as trusted on the server itself.

### **Method 2: Manual Installation on Each Computer**

#### **Step 1: Get the Certificate File**
The certificate is automatically created at: `C:\opt\http-search\certs\base-ca.cer`

#### **Step 2: Copy to Client Computers**
Copy `base-ca.cer` to each computer that needs to access the server.

#### **Step 3: Install as Trusted Root CA**
On each client computer, run PowerShell as Administrator:

```powershell
# Install the certificate as trusted
Import-Certificate -FilePath "C:\path\to\base-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"
```

### **Method 3: GUI Installation (Windows)**

#### **On Each Client Computer:**

1. **Double-click the `base-ca.cer` file**
2. **Click "Install Certificate..."**
3. **Choose "Local Machine"** → Click "Next"
4. **Select "Place all certificates in the following store"**
5. **Click "Browse..."** → Select **"Trusted Root Certification Authorities"**
6. **Click "Next"** → **"Finish"**
7. **Click "Yes"** to the security warning

---

## 🚀 **Automated Script for Client Computers**

Use this script to automatically install the certificate on client computers:

### **Download and Run:**
```powershell
# Download the trust installation script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MikeB007/http-search/master/scripts/install-trusted-certificate.ps1" -OutFile "install-cert.ps1"

# Run it (replace with your server IP)
.\install-cert.ps1 -ServerIP "192.168.86.40"
```

### **Or Manual Commands:**
```powershell
# Download certificate from server and install as trusted
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
    param($sender, $certificate, $chain, $sslPolicyErrors)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)
    $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    [System.IO.File]::WriteAllBytes("$env:TEMP\server-cert.cer", $certBytes)
    return $true
}

# Make request to get certificate
Invoke-WebRequest -Uri "https://192.168.86.40:8443" -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null

# Install as trusted
Import-Certificate -FilePath "$env:TEMP\server-cert.cer" -CertStoreLocation "cert:\LocalMachine\Root"

Write-Host "✅ Certificate installed as trusted!"
```

---

## 🔍 **Verification Steps**

### **After Installing Certificate:**

1. **Open web browser**
2. **Go to:** `https://192.168.86.40:8443`
3. **Check for:**
   - ✅ **No security warnings**
   - ✅ **Lock icon in address bar**
   - ✅ **"Secure" or "Connection is secure" message**

### **If Still Seeing Warnings:**

#### **Check Certificate Installation:**
```powershell
# Verify certificate is in Trusted Root store
Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Subject -like "*base*" }
```

#### **Clear Browser Cache:**
- **Chrome:** Settings → Privacy → Clear browsing data
- **Edge:** Settings → Reset and cleanup → Clear browsing data
- **Firefox:** Options → Privacy → Clear Data

#### **Restart Browser:**
Close and reopen your browser completely.

---

## 🌐 **Network-Wide Trust (Domain Environment)**

### **If you have Active Directory:**

1. **Copy `base-ca.cer` to Domain Controller**
2. **Open Group Policy Management**
3. **Edit Default Domain Policy**
4. **Navigate to:** 
   ```
   Computer Configuration 
   → Policies 
   → Windows Settings 
   → Security Settings 
   → Public Key Policies 
   → Trusted Root Certification Authorities
   ```
5. **Right-click → Import** → Select `base-ca.cer`
6. **Run `gpupdate /force` on client computers**

---

## 🎯 **Summary of Access URLs After Trust Installation**

Once the certificate is trusted, users can access without warnings:

- ✅ `https://192.168.86.40:8443` - Direct IP access
- ✅ `https://base:8443` - If DNS configured  
- ✅ `https://localhost:8443` - From server itself
- ✅ `http://192.168.86.40` - Redirects to HTTPS

---

## 🔧 **Troubleshooting**

### **Still Getting Certificate Warnings?**

1. **Check certificate subject matches URL:**
   ```powershell
   # View certificate details
   Get-ChildItem -Path "cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*base*" } | Format-List Subject, DnsNameList
   ```

2. **Recreate certificate with correct DNS names:**
   ```powershell
   # Recreate with all needed names
   $cert = New-SelfSignedCertificate -DnsName "base","localhost","192.168.86.40","server.local" -CertStoreLocation "cert:\LocalMachine\My"
   ```

3. **Check certificate is not expired:**
   ```powershell
   # Check expiration
   Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Subject -like "*base*" } | Select-Object NotAfter
   ```

### **Certificate Not Installing?**

- ✅ **Run PowerShell as Administrator**
- ✅ **Check Windows Updates are current**
- ✅ **Temporarily disable antivirus**
- ✅ **Use GUI method instead of PowerShell**

---

## ⚡ **Quick Commands Reference**

```powershell
# Install certificate as trusted
Import-Certificate -FilePath "base-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"

# Verify installation
Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Subject -like "*base*" }

# Test HTTPS connection
Invoke-WebRequest -Uri "https://192.168.86.40:8443" -UseBasicParsing

# Remove certificate (if needed)
Get-ChildItem -Path "cert:\LocalMachine\Root" | Where-Object { $_.Subject -like "*base*" } | Remove-Item
```

---

🎉 **After following these steps, your HTTP Search application will be accessible via HTTPS without any browser security warnings!**