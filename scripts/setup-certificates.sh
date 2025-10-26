#!/bin/bash
# Automatic Certificate Setup Script for Docker
# This script creates SSL certificates automatically if they don't exist

set -e

CERT_DIR="/app/certs"
CERT_FILE="$CERT_DIR/production.p12"
CERT_PASSWORD="${SSL_PASSPHRASE:-production123}"

echo "🔐 HTTP Search - SSL Certificate Setup"
echo "====================================="

# Create certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if certificate already exists
if [ -f "$CERT_FILE" ]; then
    echo "✓ SSL certificate already exists: $CERT_FILE"
    exit 0
fi

echo "📝 Creating SSL certificate..."

# Get container hostname/IP for certificate
HOSTNAME="${CERT_HOSTNAME:-localhost}"
if [ ! -z "$PUBLIC_IP" ]; then
    HOSTNAME="$PUBLIC_IP"
fi

# Create self-signed certificate using OpenSSL
openssl req -x509 -newkey rsa:2048 -keyout "$CERT_DIR/private-key.pem" -out "$CERT_DIR/certificate.pem" -days 365 -nodes -subj "/CN=$HOSTNAME" -extensions v3_req -config <(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $HOSTNAME

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = base
IP.1 = 127.0.0.1
EOF
)

# Add additional names if specified
if [ ! -z "$PUBLIC_IP" ]; then
    echo "IP.2 = $PUBLIC_IP" >> /tmp/openssl.conf
fi

if [ ! -z "$INTERNAL_IP" ]; then
    echo "IP.3 = $INTERNAL_IP" >> /tmp/openssl.conf
fi

# Create PKCS#12 bundle for Node.js
openssl pkcs12 -export -out "$CERT_FILE" -inkey "$CERT_DIR/private-key.pem" -in "$CERT_DIR/certificate.pem" -passout pass:$CERT_PASSWORD

# Set proper permissions
chmod 600 "$CERT_DIR"/*.pem
chmod 600 "$CERT_FILE"

echo "✓ SSL certificate created successfully"
echo "  Certificate: $CERT_FILE"
echo "  Password: $CERT_PASSWORD"
echo "  Valid for: $HOSTNAME, localhost, 127.0.0.1"

# Clean up temporary files
rm -f "$CERT_DIR/private-key.pem" "$CERT_DIR/certificate.pem"

echo "🎉 Certificate setup complete!"