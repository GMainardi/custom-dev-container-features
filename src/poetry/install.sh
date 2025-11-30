#!/bin/sh
set -e

echo "Activating feature 'poetry'"

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
        apt-get install -y --no-install-recommends curl python3 python3-pip ca-certificates

        # Clean up temporary config
        rm -f /etc/apt/apt.conf.d/99custom
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        apk add --no-cache curl python3 py3-pip ca-certificates bash
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL 8+
        dnf install -y curl python3 python3-pip
    elif command -v yum >/dev/null 2>&1; then
        # RHEL 7/CentOS
        yum install -y curl python3 python3-pip
    else
        echo "Warning: Could not detect package manager. Assuming dependencies are present."
    fi
}

install_poetry() {
    echo "Installing Poetry..."
    
    # If version is 'latest', we don't pass --version to the installer script (it defaults to latest)
    # If version is specific, we pass --version <version>
    
    POETRY_HOME="/usr/local/poetry"
    
    if [ "$VERSION" = "latest" ]; then
        curl -sSL https://install.python-poetry.org | POETRY_HOME=$POETRY_HOME python3 -
    else
        curl -sSL https://install.python-poetry.org | POETRY_HOME=$POETRY_HOME python3 - --version "$VERSION"
    fi

    # Symlink poetry to /usr/local/bin so it's in PATH for all users
    ln -sf "$POETRY_HOME/bin/poetry" /usr/local/bin/poetry
    
    # Verify installation
    poetry --version
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
install_poetry
cleanup

echo "Done!"

