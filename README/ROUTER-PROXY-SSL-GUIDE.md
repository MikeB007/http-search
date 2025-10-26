# 🌐 Router Proxy SSL Solutions

## 📚 Your Setup (Router-Based Proxy)
- **Internal Server**: `https://192.168.86.40:8443` (your base server)
- **Router Public IP**: `147.194.240.208:9090` 
- **Router forwards**: Port 9090 → Internal 192.168.86.40:8443
- **Problem**: Router can't use custom SSL certificates

## 🎯 Solutions (Router Limitations)

### **Solution 1: Use HTTP on Router, HTTPS Internally (Recommended)**

**Router Configuration:**
- Router forwards: `http://147.194.240.208:9090` → `https://192.168.86.40:8443`
- Users access: `http://147.194.240.208:9090` (no SSL on router)
- Internal traffic: Still encrypted `https://192.168.86.40:8443`

**Pros:**
- ✅ No certificate issues on router
- ✅ Internal traffic still encrypted
- ✅ Simple router configuration

**Cons:**
- ❌ External traffic not encrypted (HTTP)
- ❌ Browsers show "Not Secure" for different reason

### **Solution 2: Direct HTTPS Port Forward (Best Option)**

**Router Configuration:**
```
Port Forward Rule:
External: 147.194.240.208:8443 → Internal: 192.168.86.40:8443
Protocol: TCP
```

**Certificate Setup on Internal Server:**
```powershell
# Create certificate for public IP
$cert = New-SelfSignedCertificate -DnsName "147.194.240.208","192.168.86.40","localhost" -CertStoreLocation "cert:\LocalMachine\My" -Subject "CN=147.194.240.208"

# Export for application
$pw = ConvertTo-SecureString -String "production123" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "C:\opt\http-search\certs\production.p12" -Password $pw -Force

# Export for client trust
Export-Certificate -Cert $cert -FilePath "C:\opt\http-search\certs\public-ca.cer" -Force

# Restart container
docker restart http-search-production
```

**Access URLs:**
- **Public**: `https://147.194.240.208:8443`
- **Internal**: `https://192.168.86.40:8443`

### **Solution 3: Use Dynamic DNS with Custom Domain**

**Setup a domain name:**
1. **Get free domain**: Use services like DuckDNS, No-IP, or FreeDNS
2. **Point domain to your IP**: `myapp.duckdns.org` → `147.194.240.208`
3. **Create certificate for domain**:

```powershell
# Create certificate for domain name
$cert = New-SelfSignedCertificate -DnsName "myapp.duckdns.org","147.194.240.208","192.168.86.40" -CertStoreLocation "cert:\LocalMachine\My" -Subject "CN=myapp.duckdns.org"
```

**Router forwards:** 
- `https://myapp.duckdns.org:8443` → `192.168.86.40:8443`

### **Solution 4: Accept "Not Secure" and Train Users**

**Simplest approach:**
- Keep current setup
- Tell users to click "Advanced" → "Continue to site"
- Create user guide with screenshots

**Create user instruction guide:**
```
1. Go to: https://147.194.240.208:9090
2. Click "Advanced" or "Show details"
3. Click "Continue to 147.194.240.208 (unsafe)"
4. Bookmark the page for future use
```

---

## 🚀 **Recommended Quick Setup (Solution 2)**

**Step 1: Configure Router Port Forward**
```
Router Admin Panel:
- Port Forwarding / Virtual Server
- External Port: 8443
- Internal IP: 192.168.86.40
- Internal Port: 8443
- Protocol: TCP
- Enable: Yes
```

**Step 2: Update Certificate on Internal Server**
```powershell
# Run this on 192.168.86.40
$publicIP = "147.194.240.208"
$cert = New-SelfSignedCertificate -DnsName $publicIP,"192.168.86.40","localhost","base" -CertStoreLocation "cert:\LocalMachine\My" -Subject "CN=$publicIP" -NotAfter (Get-Date).AddYears(1)

# Export for Docker
$pw = ConvertTo-SecureString -String "production123" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "C:\opt\http-search\certs\production.p12" -Password $pw -Force

# Export for client trust
Export-Certificate -Cert $cert -FilePath "C:\opt\http-search\certs\public-ca.cer" -Force

# Install locally as trusted
Import-Certificate -FilePath "C:\opt\http-search\certs\public-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"

# Restart container
docker restart http-search-production

Write-Host "✅ Certificate updated for public IP: $publicIP"
Write-Host "✅ Users should access: https://$publicIP`:8443"
Write-Host "✅ Certificate file for clients: C:\opt\http-search\certs\public-ca.cer"
```

**Step 3: Distribute Certificate to Client Computers**
```powershell
# On each client computer (as Administrator):
Import-Certificate -FilePath "public-ca.cer" -CertStoreLocation "cert:\LocalMachine\Root"
```

**Step 4: Test Access**
- **Public URL**: `https://147.194.240.208:8443`
- **Should show**: Secure lock icon (after certificate installation)

---

## 🔧 **Router Configuration Examples**

### **Common Router Interfaces:**

**Linksys/Belkin:**
```
Advanced → Port Range Forwarding
External Port: 8443-8443
Internal Port: 8443-8443 
IP Address: 192.168.86.40
Protocol: TCP
```

**Netgear:**
```
Dynamic DNS → Port Forwarding/Port Triggering
Service Name: HTTP-Search
External Port: 8443
Internal Port: 8443
Internal IP: 192.168.86.40
```

**TP-Link:**
```
Advanced → NAT Forwarding → Virtual Servers
Service Port: 8443
Internal Port: 8443
IP Address: 192.168.86.40
Protocol: TCP
```

**ASUS:**
```
Adaptive QoS → Port Forwarding
Source Target: ALL
Port Range: 8443
Local IP: 192.168.86.40
Local Port: 8443
Protocol: TCP
```

---

## ✅ **Expected Result**

After setup:
- ✅ Router forwards `https://147.194.240.208:8443` directly to your internal server
- ✅ Certificate includes public IP `147.194.240.208`
- ✅ Client computers trust the certificate
- ✅ Users see secure lock icon at `https://147.194.240.208:8443`

**No router SSL configuration needed** - the router just forwards the encrypted traffic through! 🎉

Which solution would you like to try? Solution 2 (direct port forward) is usually the best for router setups.