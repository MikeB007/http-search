# 🔰 Complete Beginner's Guide to Deploying HTTP Search App

## 📚 What We're Doing
We're going to install and run your HTTP Search web application on your "base" server using Docker. Think of Docker as a way to package your entire application (like a zip file) that can run anywhere.

## 🎯 End Goal
After following this guide, you'll have:
- Your HTTP Search application running on your server
- Accessible via web browser at `https://base` or `https://your-server-ip`
- Automatically starts when server reboots
- Professional HTTPS security

---

## 🪟 **Windows Server? Use This Instead!**

**If your "base" server is Windows**, use the Windows-specific guide:
- **📖 [Windows Server Deployment Guide](WINDOWS-SERVER-DEPLOYMENT.md)**
- **🚀 Quick Deploy Script**: `scripts\deploy-windows-server.ps1`

The guide below is for **Linux servers only**.

---

## 📋 Prerequisites (Do This First!)

### Step 1: Connect to Your Base Server
```bash
# Replace 'admin' with your actual username
# Replace 'base' with your server's IP address if needed
ssh admin@base
```

**What this does:** Opens a secure connection to your server so you can run commands on it.

### Step 2: Install Docker (One-Time Setup)
```bash
# Update the server's software list
sudo apt update

# Install Docker (the container runtime)
sudo apt install -y docker.io docker-compose-plugin

# Start Docker service
sudo systemctl start docker

# Make Docker start automatically when server reboots
sudo systemctl enable docker

# Add your user to the docker group (so you don't need 'sudo' for docker commands)
sudo usermod -aG docker $USER

# Apply the group change (you'll need to reconnect after this)
newgrp docker
```

**What this does:** Installs Docker on your server. Docker is like a virtual machine but much lighter - it lets you run applications in isolated containers.

### Step 3: Test Docker Installation
```bash
# Test if Docker is working
docker --version

# Run a simple test container
docker run hello-world
```

**What this does:** Verifies Docker is installed correctly. The `hello-world` command downloads a tiny test application and runs it.

---

## 🚀 Deploy Your Application (The Main Event!)

### Step 4: Create a Directory for Your App
```bash
# Create a directory to store your application files
sudo mkdir -p /opt/http-search/{certs,logs,config}

# Change ownership so your user can access it
sudo chown $USER:$USER /opt/http-search -R

# Go into this directory
cd /opt/http-search
```

**What this does:** 
- Creates folders to organize your application files
- `/opt/http-search/certs` - will store SSL certificates (for HTTPS)
- `/opt/http-search/logs` - will store application log files
- `/opt/http-search/config` - will store configuration files

### Step 5: Download the Configuration File
```bash
# Download the Docker Compose configuration file from GitHub
wget https://raw.githubusercontent.com/MikeB007/http-search/master/docker-compose.prod.yml
```

**What this does:**
- `wget` is a command to download files from the internet
- `https://raw.githubusercontent.com/...` is the direct link to your configuration file
- `docker-compose.prod.yml` is the file that tells Docker how to run your application

**The file contains instructions like:**
- Which Docker image to use (your pre-built application)
- Which ports to open (80 for HTTP, 443 for HTTPS)
- Where to store files
- Environment settings

### Step 6: Create an SSL Certificate (For HTTPS Security)
```bash
# Generate a self-signed SSL certificate for your server
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout server.key -out server.crt \
  -subj "/CN=base" \
  -addext "subjectAltName=DNS:base,DNS:base.local,IP:$(hostname -I | awk '{print $1}')"

# Convert it to the format your application expects
openssl pkcs12 -export \
  -out ./certs/production.p12 \
  -inkey server.key \
  -in server.crt \
  -passout pass:production123

# Clean up temporary files
rm server.key server.crt
```

**What this does:**
- Creates an SSL certificate so your website can use HTTPS (secure connection)
- The certificate is valid for 365 days
- `production123` is the password for the certificate (you can change this)
- Self-signed means it's not from a official authority, so browsers will show a warning (but it's still encrypted)

### Step 7: Start Your Application
```bash
# Set the certificate password and start the application
SSL_PASSPHRASE=production123 docker-compose -f docker-compose.prod.yml up -d
```

**Let's break this down:**

**`SSL_PASSPHRASE=production123`**
- Sets an environment variable with the password for your SSL certificate
- Must match the password you used when creating the certificate

**`docker-compose`**
- A tool that can start multiple Docker containers based on a configuration file
- Reads the `docker-compose.prod.yml` file to know what to do

**`-f docker-compose.prod.yml`**
- `-f` means "use this file"
- Tells docker-compose which configuration file to use

**`up -d`**
- `up` means "start the application"
- `-d` means "detached" - run in the background (you get your command prompt back)

---

## 🔍 Verify Everything is Working

### Step 8: Check if Your Application Started
```bash
# See all running Docker containers
docker ps

# Check the logs of your application
docker-compose -f docker-compose.prod.yml logs

# Check if the ports are open
sudo netstat -tulpn | grep :443
sudo netstat -tulpn | grep :80
```

**What to look for:**
- `docker ps` should show a container named `http-search-production` with status "Up"
- Logs should show "HTTPS Server listening on port 8443"
- `netstat` should show ports 80 and 443 are "LISTEN"ing

### Step 9: Test Your Application
```bash
# Test from the server itself
curl -k https://localhost:443

# Test the health check
docker exec http-search-production node -e "require('https').get('https://localhost:8443', {rejectUnauthorized: false}, (res) => { if (res.statusCode === 200) console.log('✓ App is healthy'); else console.log('❌ App has issues'); }).on('error', () => console.log('❌ Connection failed'));"
```

**What this does:**
- `curl -k https://localhost:443` tries to access your website from the server
- The health check verifies your application is responding correctly
- You should see "✓ App is healthy" if everything is working

---

## 🌐 Access Your Application

### From Your Web Browser
1. Open your web browser
2. Go to: `https://base` (or `https://your-server-ip-address`)
3. You'll see a security warning (because it's a self-signed certificate)
4. Click "Advanced" and "Proceed to base (unsafe)" or similar
5. You should see your HTTP Search application!

---

## 🛠️ Managing Your Application

### View Live Logs
```bash
# See what your application is doing in real-time
docker-compose -f docker-compose.prod.yml logs -f
# Press Ctrl+C to stop viewing logs
```

### Restart Your Application
```bash
# Restart the application
docker-compose -f docker-compose.prod.yml restart
```

### Stop Your Application
```bash
# Stop the application
docker-compose -f docker-compose.prod.yml down
```

### Update Your Application (When New Versions Are Available)
```bash
# Download the latest version and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🔧 Troubleshooting Common Issues

### "Permission denied" errors
```bash
# Fix file permissions
sudo chown $USER:$USER /opt/http-search -R
chmod 600 /opt/http-search/certs/*
```

### "Port already in use"
```bash
# See what's using port 443
sudo lsof -i :443

# If Apache or Nginx is running, stop it
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### "Cannot connect to Docker daemon"
```bash
# Start Docker service
sudo systemctl start docker

# Add your user to docker group again
sudo usermod -aG docker $USER
newgrp docker
```

### Container won't start
```bash
# Check detailed logs
docker-compose -f docker-compose.prod.yml logs
docker logs http-search-production
```

---

## 🔒 Security Notes

1. **Firewall**: Make sure ports 80 and 443 are open in your firewall
2. **SSL Certificate**: For production use, get a real SSL certificate from Let's Encrypt (free) or a commercial provider
3. **Passwords**: Change `production123` to a secure password
4. **Updates**: Regularly update your server and Docker images

---

## 📞 Quick Reference Commands

```bash
# Status check
docker ps
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart
docker-compose -f docker-compose.prod.yml restart

# Stop
docker-compose -f docker-compose.prod.yml down

# Update
docker-compose -f docker-compose.prod.yml pull && docker-compose -f docker-compose.prod.yml up -d
```

That's it! Your HTTP Search application should now be running on your base server and accessible via HTTPS! 🎉