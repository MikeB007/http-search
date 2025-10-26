# HTTP Search - Deployment Guide

A secure HTTPS-enabled Angular application with Node.js backend, packaged for easy deployment using Docker and CI/CD pipelines.

## 🏗️ Architecture

- **Frontend**: Angular 12 application
- **Backend**: Node.js/Express server with HTTPS support
- **Security**: SSL/TLS encryption with PKCS#12 certificate support
- **Containerization**: Docker with multi-stage builds
- **CI/CD**: GitHub Actions workflow

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ (recommended)
- Docker and Docker Compose
- Git

### 1. Clone and Setup

```bash
git clone <repository-url>
cd http-search
npm install
```

### 2. Setup SSL Certificates

```bash
# Automated certificate setup
npm run setup:certs

# Or create manually (see Certificate Management section)
```

### 3. Development Mode

```bash
# Option 1: Local development
npm run serve:https

# Option 2: Docker development with hot reload
npm run docker:dev

# Option 3: Traditional Angular dev server (HTTP only)
npm start
```

### 4. Production Deployment

```bash
# Option 1: Docker Compose (recommended)
npm run docker:run

# Option 2: Automated build script (Linux/macOS)
./scripts/deploy.sh

# Option 3: Automated build script (Windows)
scripts\deploy.bat

# Option 4: Manual Docker build
npm run docker:build
docker run -d --name http-search-server -p 8080:8080 -p 8443:8443 -v ./certs:/app/certs:ro http-search
```

## 📦 Deployment Options

### Docker Compose (Recommended)

```yaml
# Production deployment
docker-compose up -d

# Development with hot reload
docker-compose -f docker-compose.dev.yml up
```

### Kubernetes

```bash
# Apply Kubernetes manifests (create these based on your cluster)
kubectl apply -f k8s/
```

### Traditional Server

```bash
# Build the application
npm run build:prod

# Start the HTTPS server
PFX_PATH=./certs/localhost.p12 SSL_PASSPHRASE=dev123 npm run serve:https
```

## 🔐 Certificate Management

### Development Certificates

The application automatically creates self-signed certificates for local development:

```bash
npm run setup:certs
```

This creates:
- `./certs/localhost.p12` - PKCS#12 certificate bundle
- Password: `dev123`
- Valid for: `localhost`, `127.0.0.1`

### Production Certificates

For production, replace the development certificate with a CA-signed certificate:

1. **Let's Encrypt (recommended for public deployment)**:
   ```bash
   certbot certonly --standalone -d yourdomain.com
   openssl pkcs12 -export -out ./certs/production.p12 \
     -inkey /etc/letsencrypt/live/yourdomain.com/privkey.pem \
     -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem
   ```

2. **Commercial CA Certificate**:
   - Convert your certificate to PKCS#12 format
   - Place in `./certs/` directory
   - Update environment variables

3. **Environment Variables**:
   ```bash
   export PFX_PATH=/app/certs/production.p12
   export SSL_PASSPHRASE=your-secure-password
   ```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PFX_PATH` | Path to PKCS#12 certificate | `./certs/localhost.p12` |
| `SSL_PASSPHRASE` | Certificate password | `dev123` |
| `KEY_PATH` | Path to PEM private key (alternative to PFX) | - |
| `CERT_PATH` | Path to PEM certificate (alternative to PFX) | - |
| `CA_PATH` | Path to CA bundle (optional) | - |
| `NODE_ENV` | Environment mode | `production` |
| `HTTP_PORT` | HTTP port (redirects to HTTPS) | `8080` |
| `HTTPS_PORT` | HTTPS port | `8443` |

### Docker Configuration

Create a `.env` file for Docker Compose:

```env
PFX_PATH=./certs/localhost.p12
SSL_PASSPHRASE=dev123
NODE_ENV=production
```

## 🏃‍♂️ CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Test**: Run linting and unit tests
2. **Build**: Compile Angular application and create Docker image
3. **Push**: Upload image to GitHub Container Registry
4. **Deploy**: Deploy to production environment

### Setup GitHub Actions

1. Enable GitHub Packages in your repository
2. Set up deployment secrets (if deploying to remote server):
   ```
   HOST: your-server-ip
   USERNAME: deployment-user
   KEY: ssh-private-key
   ```

### Manual Deployment Trigger

```bash
# Trigger deployment manually
gh workflow run ci-cd.yml
```

## 📊 Monitoring and Logs

### Docker Logs

```bash
# View application logs
docker logs http-search-server -f

# View all container logs
npm run docker:logs
```

### Health Checks

The application includes built-in health checks:

- **Docker**: Automatic container health monitoring
- **Endpoint**: `https://localhost:8443` returns 200 OK when healthy

### Performance Monitoring

Monitor your application with:

```bash
# Container stats
docker stats http-search-server

# System resource usage
docker exec http-search-server top
```

## 🛠️ Development

### Project Structure

```
http-search/
├── src/                    # Angular application source
├── server.js              # Node.js HTTPS server
├── Dockerfile             # Multi-stage Docker build
├── docker-compose.yml     # Production deployment
├── docker-compose.dev.yml # Development with hot reload
├── scripts/               # Build and deployment scripts
├── certs/                 # SSL certificates
└── .github/workflows/     # CI/CD pipeline
```

### Available Scripts

| Script | Description |
|--------|-------------|
| `npm start` | Angular dev server (HTTP) |
| `npm run build` | Build Angular app |
| `npm run build:prod` | Production build |
| `npm run serve:https` | Start HTTPS server |
| `npm run docker:build` | Build Docker image |
| `npm run docker:run` | Run production container |
| `npm run docker:dev` | Run development container |
| `npm run setup:certs` | Setup SSL certificates |

### Local Development with HTTPS

1. Setup certificates: `npm run setup:certs`
2. Start HTTPS server: `npm run serve:https`
3. Access: `https://localhost:8443`

## 🔍 Troubleshooting

### Common Issues

1. **Certificate Errors**:
   - Ensure certificates exist in `./certs/` directory
   - Check certificate password in environment variables
   - Verify certificate is not expired

2. **Port Already in Use**:
   ```bash
   # Check what's using the port
   netstat -tulpn | grep :8443
   
   # Stop existing containers
   docker stop http-search-server
   ```

3. **Build Failures**:
   - Clear npm cache: `npm cache clean --force`
   - Remove node_modules: `rm -rf node_modules && npm install`
   - Check Node.js version compatibility

4. **Docker Issues**:
   ```bash
   # Rebuild without cache
   docker build --no-cache -t http-search .
   
   # Clean up Docker system
   docker system prune -a
   ```

### Logs and Debugging

```bash
# Application logs
docker logs http-search-server

# Debug mode
NODE_ENV=development npm run serve:https

# Container shell access
docker exec -it http-search-server sh
```

## 🚀 Deployment Targets

### Local Server
- Use Docker Compose for easy setup
- Suitable for development and small-scale production

### Cloud Platforms
- **AWS**: ECS, EKS, or EC2 with Docker
- **Azure**: Container Instances or AKS
- **GCP**: Cloud Run or GKE
- **DigitalOcean**: App Platform or Droplets

### Kubernetes
- Create appropriate manifests for your cluster
- Use Helm charts for complex deployments
- Configure ingress for SSL termination

## 📋 Security Considerations

1. **Certificates**:
   - Use CA-signed certificates in production
   - Regularly rotate certificates
   - Store private keys securely

2. **Secrets Management**:
   - Use environment variables for sensitive data
   - Consider using Docker secrets or Kubernetes secrets
   - Never commit certificates or passwords to version control

3. **Network Security**:
   - Configure firewalls appropriately
   - Use reverse proxy (nginx/Apache) for additional security
   - Implement rate limiting and DDoS protection

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review application logs
3. Create an issue in the repository
4. Consult the Angular and Node.js documentation

---

**Note**: This setup is configured for HTTPS-first deployment with automatic HTTP to HTTPS redirection for enhanced security.