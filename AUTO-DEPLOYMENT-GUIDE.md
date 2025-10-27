# 🤖 **AUTO-DEPLOYMENT SETUP GUIDE**

## **🎯 Choose Your Auto-Deployment Method:**

### **Method 1: GitHub Actions SSH (Recommended)**
**✅ Best for: Secure, controlled deployments triggered by code changes**

#### Setup Steps:
1. **Generate SSH Key on your base server:**
   ```bash
   ssh-keygen -t ed25519 -C "github-actions-deploy"
   cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
   cat ~/.ssh/id_ed25519  # Copy this private key
   ```

2. **Add GitHub Secrets:**
   - Go to: GitHub → Settings → Secrets and variables → Actions
   - Add these secrets:
     ```
     SSH_PRIVATE_KEY: [Paste private key from step 1]
     SERVER_HOST: base  (or your server IP)
     SERVER_USER: admin (or your SSH username)
     SSL_PASSPHRASE: production123
     ```

3. **Deploy once manually to setup directory:**
   ```bash
   ./scripts/deploy-remote.sh base admin production123
   ```

4. **✅ Done!** Every push to master will auto-deploy

---

### **Method 2: Cron-Based Auto-Pull (Simple)**
**✅ Best for: Simple setups, periodic updates**

#### Setup on Base Server:
```bash
# Copy and run this on your base server
chmod +x /opt/http-search/scripts/auto-update-server.sh
/opt/http-search/scripts/auto-update-server.sh install
```

**Result:** Updates every 30 minutes automatically

---

### **Method 3: Webhook-Based (Instant)**
**✅ Best for: Instant updates triggered by GitHub**

#### Setup Steps:
1. **On base server:**
   ```bash
   /opt/http-search/scripts/auto-update-server.sh setup-webhook
   ```

2. **In GitHub:**
   - Go to: Repository → Settings → Webhooks
   - Add webhook: `http://[YOUR-SERVER-IP]:9999/deploy`
   - Trigger: Push events to master

**Result:** Instant deployment when code is pushed

---

## **🔧 Manual Commands:**

### **Update Docker Image Manually:**
```bash
# On base server:
cd /opt/http-search
docker pull ghcr.io/mikeb007/http-search:latest
docker-compose -f DOCKER/docker-compose.yml down
SSL_PASSPHRASE=production123 docker-compose -f DOCKER/docker-compose.yml up -d
```

### **Check Auto-Update Status:**
```bash
# Check cron jobs:
crontab -l

# Check webhook service:
sudo systemctl status http-search-webhook

# Check container status:
docker ps | grep http-search
```

---

## **🎯 Recommended Setup:**

### **For Production:**
- Use **Method 1 (GitHub Actions SSH)** for controlled deployments
- Add approval workflow for production branch
- Test deployments on staging first

### **For Development:**
- Use **Method 2 (Cron)** for simple auto-updates
- 30-minute intervals keep server current
- No complex setup required

### **For Real-time:**
- Use **Method 3 (Webhook)** for instant deployments
- Perfect for demo environments
- Updates within seconds of code push

---

## **🔒 Security Notes:**

- **SSH Keys**: Use dedicated keys for GitHub Actions
- **Firewall**: Limit webhook port (9999) access if using Method 3
- **SSL**: Always use HTTPS endpoints in production
- **Secrets**: Never commit SSH keys or passwords to repository

---

## **✅ Verification:**

After setup, verify auto-deployment works:

1. **Make a test commit:**
   ```bash
   echo "Auto-deploy test" >> README.md
   git add README.md && git commit -m "Test auto-deploy"
   git push origin master
   ```

2. **Check GitHub Actions** (Method 1)
3. **Wait 30 minutes** (Method 2) 
4. **Check immediately** (Method 3)

Your base server should automatically update with the latest Docker image! 🚀