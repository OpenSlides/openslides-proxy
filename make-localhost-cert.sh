#!/bin/bash

set -e
cd "$(dirname "$0")"

# Ensure certs directory exists
mkdir -p certs

if [[ -f "certs/key.pem" ]] || [[ -f "certs/cert.pem" ]]; then
    echo "Certificate already exists."
    exit 0
fi

echo "Creating certificates..."

# Check if mkcert is available
if type mkcert >/dev/null 2>&1; then
    echo "Using mkcert to generate trusted certificates..."

    # Install local CA if not already installed
    mkcert -install >/dev/null 2>&1 || true

    # Generate certificate for localhost and common local addresses
    mkcert -cert-file certs/cert.pem -key-file certs/key.pem \
        localhost 127.0.0.1 ::1 \
        "*.localhost" \
        "localhost.localdomain" \
        "*.localhost.localdomain"

    echo "Certificates created with mkcert (automatically trusted in browsers)"

elif type openssl >/dev/null 2>&1; then
    echo "mkcert not found, falling back to openssl..."
    echo "You will need to accept a security exception for the"
    echo "generated certificate in your browser manually."

    openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
            -subj "/C=DE/O=Selfsigned Test/CN=localhost" \
            -keyout certs/key.pem -out certs/cert.pem

    echo "Self-signed certificate created with openssl"

else
    echo >&2 "Error: Neither mkcert nor openssl found!"
    echo >&2 "Please install either mkcert (recommended) or openssl."
    echo >&2 ""
    echo >&2 "To install mkcert:"
    echo >&2 "  - macOS: brew install mkcert"
    echo >&2 "  - Linux: Check https://github.com/FiloSottile/mkcert#installation"
    echo >&2 "  - Windows: choco install mkcert or scoop install mkcert"
    exit 1
fi

echo "done"
