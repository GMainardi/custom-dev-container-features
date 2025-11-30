#!/bin/sh
set -e

echo "Activating feature 'github-cli'"

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
        # Always install git, curl, ca-certificates, gnupg, openssh-client, socat
        apt-get install -y --no-install-recommends curl ca-certificates gnupg dirmngr git openssh-client socat

        # Clean up temporary config
        rm -f /etc/apt/apt.conf.d/99custom
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        echo "Installing dependencies for Alpine..."
        # Always install git, curl, libc6-compat, bash, openssh-client, socat
        apk add --no-cache curl libc6-compat bash git openssh-client socat
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL 8+
        echo "Installing dependencies for Fedora/RHEL..."
        dnf install -y curl git openssh-clients socat
    elif command -v yum >/dev/null 2>&1; then
        # RHEL 7/CentOS
        echo "Installing dependencies for RHEL/CentOS..."
        yum install -y curl git openssh-clients socat
    else
        echo "Warning: Could not detect package manager. Assuming dependencies are present."
    fi
}

install_gh() {
    # Detect Architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            GH_ARCH="amd64"
            ;;
        aarch64)
            GH_ARCH="arm64" 
            ;;
        armv7l)
            GH_ARCH="armv6"
            ;;
        *)
            echo "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    # Determine version
    if [ "$VERSION" = "latest" ]; then
        # Fetch latest release tag from GitHub API
        # If curl fails or jq isn't present, we might need a fallback or ensure they are installed.
        # For simplicity and robustness without jq, we can try to parse the redirect from releases/latest
        # OR just use the API and grep.
        VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    fi

    echo "Installing GitHub CLI version ${VERSION} for ${GH_ARCH}..."

    DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_${GH_ARCH}.tar.gz"
    
    echo "Downloading from ${DOWNLOAD_URL}..."
    
    mkdir -p /tmp/gh-cli
    curl -L "${DOWNLOAD_URL}" | tar xz -C /tmp/gh-cli --strip-components=1
    
    mv /tmp/gh-cli/bin/gh /usr/local/bin/
    mv /tmp/gh-cli/share/man/man1/* /usr/share/man/man1/ 2>/dev/null || true
    # Copy completions if needed?
    
    rm -rf /tmp/gh-cli
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
install_gh
cleanup

echo "Done!"
