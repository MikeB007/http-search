const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * Certificate setup script for development and production
 */

const certsDir = path.join(__dirname, '..', 'certs');
const isWindows = process.platform === 'win32';

function ensureCertsDirectory() {
  if (!fs.existsSync(certsDir)) {
    fs.mkdirSync(certsDir, { recursive: true });
    console.log('✓ Created certs directory');
  }
}

function createSelfSignedCert() {
  const certPath = path.join(certsDir, 'localhost.p12');
  
  if (fs.existsSync(certPath)) {
    console.log('✓ Certificate already exists at:', certPath);
    return;
  }

  console.log('🔐 Creating self-signed certificate...');

  if (isWindows) {
    // Use PowerShell on Windows
    const psScript = `
      $cert = New-SelfSignedCertificate -DnsName "localhost", "127.0.0.1" -CertStoreLocation "cert:\\CurrentUser\\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1)
      $pw = ConvertTo-SecureString -String "dev123" -Force -AsPlainText
      Export-PfxCertificate -Cert $cert -FilePath "${certPath.replace(/\\/g, '\\\\')}" -Password $pw
    `;
    
    try {
      execSync(`powershell -Command "${psScript}"`, { stdio: 'inherit' });
      console.log('✓ Self-signed certificate created successfully');
    } catch (error) {
      console.error('❌ Failed to create certificate with PowerShell:', error.message);
      console.log('💡 Please run this script as administrator or create the certificate manually');
    }
  } else {
    // Use OpenSSL on Unix-like systems
    try {
      const keyPath = path.join(certsDir, 'localhost.key');
      const certPemPath = path.join(certsDir, 'localhost.crt');
      
      // Generate private key and certificate
      execSync(`openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes -keyout "${keyPath}" -out "${certPemPath}" -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"`, { stdio: 'inherit' });
      
      // Convert to PKCS#12
      execSync(`openssl pkcs12 -export -out "${certPath}" -inkey "${keyPath}" -in "${certPemPath}" -passout pass:dev123`, { stdio: 'inherit' });
      
      console.log('✓ Self-signed certificate created successfully');
    } catch (error) {
      console.error('❌ Failed to create certificate with OpenSSL:', error.message);
      console.log('💡 Please install OpenSSL or create the certificate manually');
    }
  }
}

function createDockerCertsSetup() {
  const dockerCertsPath = path.join(certsDir, 'localhost.p12');
  const envExamplePath = path.join(__dirname, '..', '.env.example');
  
  // Create .env.example file
  const envContent = `# SSL Certificate Configuration
PFX_PATH=./certs/localhost.p12
SSL_PASSPHRASE=dev123

# Development vs Production
NODE_ENV=development

# Server Configuration
HTTP_PORT=8080
HTTPS_PORT=8443
`;

  fs.writeFileSync(envExamplePath, envContent);
  console.log('✓ Created .env.example file');

  // Copy certificate to certs directory if it exists in root
  const rootCertPath = path.join(__dirname, '..', 'localhost.p12');
  if (fs.existsSync(rootCertPath) && !fs.existsSync(dockerCertsPath)) {
    fs.copyFileSync(rootCertPath, dockerCertsPath);
    console.log('✓ Copied certificate to certs directory');
  }
}

function showUsageInstructions() {
  console.log('\n📋 Usage Instructions:');
  console.log('');
  console.log('For local development:');
  console.log('  npm run serve:https');
  console.log('');
  console.log('For Docker development:');
  console.log('  npm run docker:dev');
  console.log('');
  console.log('For Docker production:');
  console.log('  npm run docker:run');
  console.log('');
  console.log('🌐 Your application will be available at:');
  console.log('  HTTPS: https://localhost:8443');
  console.log('  HTTP:  http://localhost:8080 (redirects to HTTPS)');
  console.log('');
  console.log('🔒 Certificate details:');
  console.log('  File: ./certs/localhost.p12');
  console.log('  Password: dev123');
  console.log('  Valid for: localhost, 127.0.0.1');
}

// Main execution
console.log('🚀 Setting up HTTP Search application certificates...');
console.log('');

ensureCertsDirectory();
createSelfSignedCert();
createDockerCertsSetup();
showUsageInstructions();