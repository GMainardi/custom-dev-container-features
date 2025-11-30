#!/bin/sh
set -e

echo "Activating feature 'uv'"

VERSION=${VERSION:-"latest"}

# Helper to install dependencies based on package manager
install_dependencies() {
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        export DEBIAN_FRONTEND=noninteractive
        
        # Fix bad proxy issues
        echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom
        echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom
        echo "Acquire::BrokenProxy true;" >> /etc/apt/apt.conf.d/99custom

        rm -rf /var/lib/apt/lists/*
        
        apt-get update || true
        apt-get install -y --no-install-recommends curl ca-certificates

        # Clean up temporary config
        rm -f /etc/apt/apt.conf.d/99custom
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        apk add --no-cache curl ca-certificates libc6-compat bash
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL 8+
        dnf install -y curl
    elif command -v yum >/dev/null 2>&1; then
        # RHEL 7/CentOS
        yum install -y curl
    else
        echo "Warning: Could not detect package manager. Assuming dependencies are present."
    fi
}

install_uv() {
    echo "Installing uv..."
    
    # Set up env vars for the installer
    export UV_INSTALL_DIR="/usr/local/bin"
    
    if [ "$VERSION" != "latest" ]; then
        export UV_VERSION="$VERSION"
    fi

    # Run the official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

cleanup() {
    echo "Cleaning up..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk cache clean
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum clean all
    fi
}

install_dependencies
install_uv
cleanup

echo "Done!"

