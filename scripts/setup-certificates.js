const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * Automatic SSL Certificate Setup for HTTP Search
 * Creates self-signed certificates for development and production
 */

// Configuration
const CERT_DIR = process.env.CERT_DIR || path.join(__dirname, '..', 'certs');
const CERT_PASSWORD = process.env.SSL_PASSPHRASE || 'production123';
const isProduction = process.env.NODE_ENV === 'production';
const isWindows = process.platform === 'win32';
const isDocker = fs.existsSync('/.dockerenv');

console.log('🔐 HTTP Search - SSL Certificate Setup');
console.log('=====================================');
console.log(`Environment: ${isProduction ? 'Production' : 'Development'}`);
console.log(`Platform: ${isWindows ? 'Windows' : 'Unix/Linux'}`);
console.log(`Docker: ${isDocker ? 'Yes' : 'No'}`);

function ensureCertsDirectory() {
  if (!fs.existsSync(CERT_DIR)) {
    fs.mkdirSync(CERT_DIR, { recursive: true });
    console.log(`✓ Created certificate directory: ${CERT_DIR}`);
  }
}

function getCertificateHosts() {
  const hosts = ['localhost', '127.0.0.1', 'base'];
  
  // Add environment-specific hosts
  if (process.env.PUBLIC_IP) {
    hosts.push(process.env.PUBLIC_IP);
  }
  
  if (process.env.INTERNAL_IP && process.env.INTERNAL_IP !== process.env.PUBLIC_IP) {
    hosts.push(process.env.INTERNAL_IP);
  }
  
  // Add container hostname if in Docker
  if (isDocker) {
    try {
      const hostname = execSync('hostname', { encoding: 'utf8' }).trim();
      if (hostname && !hosts.includes(hostname)) {
        hosts.push(hostname);
      }
    } catch (e) {
      // Ignore hostname detection errors
    }
  }
  
  return hosts;
}

function createCertificateWithOpenSSL() {
  const hosts = getCertificateHosts();
  const certPath = path.join(CERT_DIR, 'production.p12');
  const keyPath = path.join(CERT_DIR, 'private-key.pem');
  const certPemPath = path.join(CERT_DIR, 'certificate.pem');
  const configPath = path.join(CERT_DIR, 'openssl.conf');
  
  if (fs.existsSync(certPath)) {
    console.log(`✓ Certificate already exists: ${certPath}`);
    return certPath;
  }

  console.log('📝 Creating SSL certificate...');
  console.log(`Valid for hosts: ${hosts.join(', ')}`);
  
  // Create OpenSSL config
  const dnsEntries = hosts.filter(h => !h.match(/^\d+\.\d+\.\d+\.\d+$/)).map((h, i) => `DNS.${i + 1} = ${h}`).join('\n');
  const ipEntries = hosts.filter(h => h.match(/^\d+\.\d+\.\d+\.\d+$/)).map((h, i) => `IP.${i + 1} = ${h}`).join('\n');
  
  const opensslConfig = `
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${hosts[0]}
O = HTTP Search Application
OU = Development Team

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
${dnsEntries}
${ipEntries}
`;

  try {
    // Write OpenSSL config
    fs.writeFileSync(configPath, opensslConfig);
    
    // Generate private key and certificate
    execSync(`openssl req -x509 -newkey rsa:2048 -keyout "${keyPath}" -out "${certPemPath}" -days 365 -nodes -config "${configPath}"`, { stdio: 'pipe' });
    
    // Create PKCS#12 bundle
    execSync(`openssl pkcs12 -export -out "${certPath}" -inkey "${keyPath}" -in "${certPemPath}" -passout pass:${CERT_PASSWORD}`, { stdio: 'pipe' });
    
    // Clean up temporary files
    fs.unlinkSync(keyPath);
    fs.unlinkSync(certPemPath);
    fs.unlinkSync(configPath);
    
    console.log(`✓ SSL certificate created: ${certPath}`);
    console.log(`✓ Certificate password: ${CERT_PASSWORD}`);
    
    return certPath;
    
  } catch (error) {
    console.error('❌ OpenSSL certificate creation failed:', error.message);
    throw error;
  }
}

function createCertificateWithPowerShell() {
  const hosts = getCertificateHosts();
  const certPath = path.join(CERT_DIR, 'production.p12');
  
  if (fs.existsSync(certPath)) {
    console.log(`✓ Certificate already exists: ${certPath}`);
    return certPath;
  }

  console.log('📝 Creating SSL certificate with PowerShell...');
  console.log(`Valid for hosts: ${hosts.join(', ')}`);
  
  const dnsNames = hosts.map(h => `"${h}"`).join(',');
  const certLocation = isProduction ? 'LocalMachine' : 'CurrentUser';
  
  const psScript = `
    $dnsNames = @(${dnsNames})
    $cert = New-SelfSignedCertificate -DnsName $dnsNames -CertStoreLocation "cert:\\${certLocation}\\My" -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1) -Subject "CN=${hosts[0]}" -FriendlyName "HTTP Search Certificate"
    $pw = ConvertTo-SecureString -String "${CERT_PASSWORD}" -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath "${certPath.replace(/\\/g, '\\\\')}" -Password $pw | Out-Null
    Write-Host "Certificate created successfully"
  `;
  
  try {
    execSync(`powershell -Command "${psScript}"`, { stdio: 'pipe' });
    console.log(`✓ SSL certificate created: ${certPath}`);
    console.log(`✓ Certificate password: ${CERT_PASSWORD}`);
    return certPath;
  } catch (error) {
    console.error('❌ PowerShell certificate creation failed:', error.message);
    throw error;
  }
}

function createDefaultCertificate() {
  console.log('🔧 Attempting certificate creation...');
  
  try {
    // Try OpenSSL first (works on most platforms)
    return createCertificateWithOpenSSL();
  } catch (opensslError) {
    if (isWindows) {
      try {
        // Fallback to PowerShell on Windows
        console.log('🔄 Trying PowerShell fallback...');
        return createCertificateWithPowerShell();
      } catch (psError) {
        console.error('❌ Both OpenSSL and PowerShell failed');
        throw new Error('Certificate creation failed on all available methods');
      }
    } else {
      throw opensslError;
    }
  }
}

function createEnvironmentFile() {
  const envPath = path.join(__dirname, '..', '.env.example');
  const hosts = getCertificateHosts();
  
  // Skip .env.example creation in Docker container or if we don't have write permissions
  if (isDocker) {
    console.log('🐳 Skipping .env.example creation in Docker container');
    return;
  }
  
  try {
    const envContent = `# HTTP Search Application Configuration

# SSL Certificate Settings
PFX_PATH=./certs/production.p12
SSL_PASSPHRASE=${CERT_PASSWORD}

# Server Configuration  
NODE_ENV=${isProduction ? 'production' : 'development'}
HTTP_PORT=8080
HTTPS_PORT=8443

# Certificate Hosts (automatically detected)
PUBLIC_IP=${process.env.PUBLIC_IP || ''}
INTERNAL_IP=${process.env.INTERNAL_IP || ''}

# Valid certificate hosts: ${hosts.join(', ')}
`;

    fs.writeFileSync(envPath, envContent);
    console.log('✓ Created .env.example file');
  } catch (error) {
    console.log('⚠️  Could not create .env.example file (may not have write permissions)');
  }
}

function showCompletionMessage() {
  const hosts = getCertificateHosts();
  
  console.log('');
  console.log('🎉 Certificate Setup Complete!');
  console.log('==============================');
  console.log('');
  console.log('📁 Certificate Location:');
  console.log(`   ${path.join(CERT_DIR, 'production.p12')}`);
  console.log('');
  console.log('🔑 Certificate Details:');
  console.log(`   Password: ${CERT_PASSWORD}`);
  console.log(`   Valid for: ${hosts.join(', ')}`);
  console.log('   Expires: 1 year from creation');
  console.log('');
  console.log('🌐 Application URLs:');
  console.log('   HTTPS: https://localhost:8443');
  console.log('   HTTP:  http://localhost:8080 (redirects to HTTPS)');
  
  if (process.env.PUBLIC_IP) {
    console.log(`   Public: https://${process.env.PUBLIC_IP}:8443`);
  }
  
  if (process.env.INTERNAL_IP) {
    console.log(`   Internal: https://${process.env.INTERNAL_IP}:8443`);
  }
  
  console.log('');
  console.log('🚀 Ready to start the application!');
}

// Main execution
async function main() {
  try {
    ensureCertsDirectory();
    createDefaultCertificate();
    createEnvironmentFile();
    
    if (!isDocker) {
      showCompletionMessage();
    } else {
      console.log('✓ Certificate setup completed for Docker container');
      console.log(`✓ Certificate: ${path.join(CERT_DIR, 'production.p12')}`);
      console.log(`✓ Password: ${CERT_PASSWORD}`);
    }
    
    // Exit successfully
    process.exit(0);
    
  } catch (error) {
    console.error('');
    console.error('❌ Certificate setup failed:');
    console.error(error.message);
    
    if (!isDocker) {
      console.error('');
      console.error('💡 Troubleshooting steps:');
      console.error('1. Ensure OpenSSL is installed');
      console.error('2. On Windows, try running as administrator');
      console.error('3. Check certificate directory permissions');
      console.error('4. Verify environment variables are set correctly');
      console.error('');
    }
    
    // In Docker, don't fail the build if certificate generation fails
    // The server can still start with existing certificates or without HTTPS
    process.exit(isDocker ? 0 : 1);
  }
}

// Run only if called directly
if (require.main === module) {
  main();
}

module.exports = {
  ensureCertsDirectory,
  createDefaultCertificate,
  createEnvironmentFile,
  getCertificateHosts
};