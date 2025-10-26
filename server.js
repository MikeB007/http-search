const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');
const app = express();
const bodyParser = require("body-parser");

// Ports - avoid conflict with API server on 443
const httpPort = 8080;
const httpsPort = 8443;

const users = [];

app.use(bodyParser.json());

// Serve static files from assets directory
app.use('/assets', express.static(path.join(__dirname, 'src/assets')));

// Serve Angular build files
app.use(express.static(path.join(__dirname, 'dist/news-search')));

// Handle Angular routing - send all requests to index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'src/index.html'));
});

// SSL Certificate options (you need to provide these files)
// SSL Certificate loading: support either a PKCS#12 keystore (.p12/.pfx) or
// separate PEM key+cert files. Prefer environment variables so you can run
// different environments without editing this file.
//
// Environment variables accepted:
// - PFX_PATH: path to a .p12 or .pfx file (if present, this is used)
// - SSL_PASSPHRASE: optional passphrase for the PFX
// - KEY_PATH: path to PEM private key file (fallback)
// - CERT_PATH: path to PEM certificate file (fallback)
// - CA_PATH: optional path to PEM CA bundle
// Example (PowerShell):
// $env:PFX_PATH = 'G:\path\to\keystore.p12'; $env:SSL_PASSPHRASE = 'mypw'; node .\server.js

let httpsOptions;
try {
  if (process.env.PFX_PATH && fs.existsSync(process.env.PFX_PATH)) {
    // Use PKCS#12 (PFX) directly
    console.log('Using PFX keystore:', process.env.PFX_PATH);
    httpsOptions = {
      pfx: fs.readFileSync(process.env.PFX_PATH),
    };
    if (process.env.SSL_PASSPHRASE) {
      httpsOptions.passphrase = process.env.SSL_PASSPHRASE;
    }
  } else {
    // Fallback to PEM key/cert
    const keyPath = process.env.KEY_PATH || 'path/to/your/private-key.pem';
    const certPath = process.env.CERT_PATH || 'path/to/your/certificate.pem';
    console.log('Using PEM files. KEY_PATH=%s CERT_PATH=%s', keyPath, certPath);
    httpsOptions = {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(certPath),
    };
    if (process.env.CA_PATH) {
      httpsOptions.ca = fs.readFileSync(process.env.CA_PATH);
    }
  }
} catch (err) {
  console.error('Failed to load SSL files for HTTPS server:', err.message);
  console.error('Make sure PFX_PATH or KEY_PATH/CERT_PATH point to valid files.');
  process.exit(1);
}

// Create HTTPS server
https.createServer(httpsOptions, app).listen(httpsPort, () => {
  console.log(`HTTPS Server listening on port ${httpsPort}`);
});

// Optional: Redirect HTTP to HTTPS
const http = require('http');
http.createServer((req, res) => {
  res.writeHead(301, { "Location": "https://" + req.headers['host'] + req.url });
  res.end();
}).listen(httpPort, () => {
  console.log(`HTTP Server redirecting from port ${httpPort} to HTTPS`);
});