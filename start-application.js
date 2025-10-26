#!/usr/bin/env node

/**
 * HTTP Search Application Launcher
 * Automatically sets up certificates and starts the application
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Banner
console.log('');
console.log('🚀 HTTP Search Application Launcher');
console.log('===================================');
console.log('');

// Configuration
const isDocker = fs.existsSync('/.dockerenv');
const isWindows = process.platform === 'win32';
const hasDockerCompose = fs.existsSync('./DOCKER/docker-compose.yml');

// Environment detection
console.log('📋 Environment Detection:');
console.log(`   Platform: ${isWindows ? 'Windows' : 'Unix/Linux'}`);
console.log(`   Docker: ${isDocker ? 'Container' : 'Host'}`);
console.log(`   Docker Compose: ${hasDockerCompose ? 'Available' : 'Not found'}`);
console.log('');

// Check for existing certificates
function checkCertificates() {
  const certsDir = path.join(__dirname, 'certs');
  const certFiles = ['production.p12', 'localhost.p12'];
  
  for (const certFile of certFiles) {
    const certPath = path.join(certsDir, certFile);
    if (fs.existsSync(certPath)) {
      console.log(`✓ Found certificate: ${certFile}`);
      return true;
    }
  }
  
  console.log('⚠️  No certificates found - will auto-generate');
  return false;
}

// Setup certificates
function setupCertificates() {
  console.log('🔐 Setting up SSL certificates...');
  
  try {
    // Run certificate setup script
    const setupScript = path.join(__dirname, 'scripts', 'setup-certificates.js');
    
    if (fs.existsSync(setupScript)) {
      execSync(`node "${setupScript}"`, { stdio: 'inherit' });
      console.log('✓ Certificate setup completed');
    } else {
      console.log('❌ Certificate setup script not found');
      console.log('💡 Please run: npm run setup:certs');
    }
  } catch (error) {
    console.error('❌ Certificate setup failed:', error.message);
    console.log('💡 You may need to run as administrator or install OpenSSL');
  }
  
  console.log('');
}

// Start application based on environment
function startApplication() {
  console.log('🌟 Starting HTTP Search Application...');
  console.log('');
  
  try {
    if (isDocker) {
      // Inside Docker container - just start the server
      console.log('📦 Running in Docker container');
      execSync('node server.js', { stdio: 'inherit' });
      
    } else if (hasDockerCompose) {
      // Host with Docker Compose available
      console.log('🐳 Starting with Docker Compose...');
      
      // Set environment variables for production IPs
      process.env.PUBLIC_IP = process.env.PUBLIC_IP || '147.194.240.208';
      process.env.INTERNAL_IP = process.env.INTERNAL_IP || '192.168.86.40';
      process.env.SSL_PASSPHRASE = process.env.SSL_PASSPHRASE || 'production123';
      
      console.log(`   Public IP: ${process.env.PUBLIC_IP}`);
      console.log(`   Internal IP: ${process.env.INTERNAL_IP}`);
      console.log('');
      
      // Start with Docker Compose
      execSync('docker-compose -f DOCKER/docker-compose.yml up --build', { stdio: 'inherit' });
      
    } else {
      // Direct Node.js execution
      console.log('⚡ Running directly with Node.js...');
      
      // Set environment variables
      process.env.NODE_ENV = process.env.NODE_ENV || 'production';
      process.env.PFX_PATH = process.env.PFX_PATH || './certs/production.p12';
      process.env.SSL_PASSPHRASE = process.env.SSL_PASSPHRASE || 'production123';
      
      execSync('node server.js', { stdio: 'inherit' });
    }
    
  } catch (error) {
    console.error('❌ Failed to start application:', error.message);
    console.log('');
    console.log('💡 Troubleshooting options:');
    console.log('   1. Check if certificates exist: npm run setup:certs');
    console.log('   2. Try Docker mode: npm run docker:run');
    console.log('   3. Check logs for detailed error information');
    console.log('   4. Verify ports 8080 and 8443 are available');
  }
}

// Show access information
function showAccessInfo() {
  console.log('');
  console.log('🌐 Application Access URLs:');
  console.log('===========================');
  console.log('');
  console.log('Local Development:');
  console.log('  HTTPS: https://localhost:8443');
  console.log('  HTTP:  http://localhost:8080 (redirects to HTTPS)');
  console.log('');
  
  if (process.env.INTERNAL_IP) {
    console.log('Internal Network:');
    console.log(`  HTTPS: https://${process.env.INTERNAL_IP}:8443`);
    console.log(`  HTTP:  http://${process.env.INTERNAL_IP}:8080`);
    console.log('');
  }
  
  if (process.env.PUBLIC_IP) {
    console.log('Public Access (via Router):');
    console.log(`  HTTPS: https://${process.env.PUBLIC_IP}:9090`);
    console.log('  (Router forwards :9090 → :8443)');
    console.log('');
  }
  
  console.log('🔒 Certificate Information:');
  console.log('  Auto-generated self-signed certificates');
  console.log('  Valid for: localhost, 127.0.0.1, and configured IPs');
  console.log('  Password: production123');
  console.log('');
  console.log('⚠️  Browser Security Notice:');
  console.log('  Self-signed certificates will show "Not Secure" warning');
  console.log('  This is normal for development/internal use');
  console.log('  Click "Advanced" → "Proceed to localhost" to continue');
  console.log('');
}

// Main execution
async function main() {
  // Check and setup certificates if needed
  const hasCerts = checkCertificates();
  if (!hasCerts && !isDocker) {
    setupCertificates();
  }
  
  // Show access information
  showAccessInfo();
  
  // Start the application
  startApplication();
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('');
  console.log('🛑 Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('');
  console.log('🛑 Received termination signal...');
  process.exit(0);
});

// Run the launcher
if (require.main === module) {
  main().catch(error => {
    console.error('💥 Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = { main, setupCertificates, checkCertificates };