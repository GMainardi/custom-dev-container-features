#!/bin/sh
set -e

echo "Activating feature 'gcloud-cli'"

VERSION=${VERSION:-"latest"}
PROJECT_ID=${PROJECTID:-""}
QUOTA_PROJECT_ID=${QUOTAPROJECTID:-""}

# Helper to install dependencies based on package manager
install_dependencies() {
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu - install dependencies for tarball installation
        echo "Installing dependencies for Debian/Ubuntu..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update || true
        apt-get install -y --no-install-recommends python3 curl ca-certificates tar
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        echo "Installing dependencies for Alpine..."
        apk add --no-cache python3 bash libc6-compat
        apk add --no-cache --virtual .gcloud-build-deps curl tar
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL 8+
        echo "Installing dependencies for Fedora/RHEL..."
        dnf install -y python3 curl tar
    elif command -v yum >/dev/null 2>&1; then
        # RHEL 7/CentOS
        echo "Installing dependencies for RHEL/CentOS..."
        yum install -y python3 curl tar
    else
        echo "Warning: Could not detect package manager. Assuming dependencies (python3, curl, tar) are present."
    fi
}

install_via_apt() {
    export DEBIAN_FRONTEND=noninteractive

    # Fix bad proxy issues
    echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom
    echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom
    echo "Acquire::BrokenProxy true;" >> /etc/apt/apt.conf.d/99custom

    rm -rf /var/lib/apt/lists/*

    # Install dependencies
    apt-get update || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }
    apt-get install -y apt-transport-https ca-certificates gnupg curl lsb-release || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }

    # Import the Google Cloud public key
    # Use a temporary keyring location to avoid permission issues or conflicts
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }

    # Add the gcloud CLI distribution URI as a package source
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # Update and install the gcloud CLI
    apt-get update || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }

    if [ "$VERSION" = "latest" ]; then
        echo "Installing latest version of google-cloud-cli..."
        apt-get install -y google-cloud-cli || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }
    else
        echo "Installing version ${VERSION} of google-cloud-cli..."
        apt-get install -y "google-cloud-cli=${VERSION}-*" || apt-get install -y "google-cloud-cli=${VERSION}" || { rm -f /etc/apt/apt.conf.d/99custom; return 1; }
    fi
    
    # Clean up
    rm -f /etc/apt/apt.conf.d/99custom
    return 0
}

install_via_tarball() {
    # Detect Architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            GCLOUD_ARCH="x86_64"
            ;;
        aarch64)
            GCLOUD_ARCH="arm" 
            ;;
        *)
            echo "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    echo "Installing gcloud via tarball for architecture: ${GCLOUD_ARCH}..."

    # Prepare install directory
    INSTALL_DIR="/usr/local/gcloud"
    mkdir -p "$INSTALL_DIR"

    if [ "$VERSION" = "latest" ]; then
        DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${GCLOUD_ARCH}.tar.gz"
    else
        DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${VERSION}-linux-${GCLOUD_ARCH}.tar.gz"
    fi

    echo "Downloading gcloud from ${DOWNLOAD_URL}..."
    curl -L "${DOWNLOAD_URL}" | tar xz -C "$INSTALL_DIR" --strip-components=1

    # Remove installation scripts and docs from the extracted directory
    rm -f "$INSTALL_DIR/install.sh" "$INSTALL_DIR/install.bat" "$INSTALL_DIR/README" "$INSTALL_DIR/RELEASE_NOTES"

    # Run install script to setup path and completion? 
    # Actually, manual symlinking is cleaner for a feature.
    # gcloud's install.sh modifies .bashrc which we might not want to rely on exclusively.
    
    # Symlink binaries
    ln -s "${INSTALL_DIR}/bin/gcloud" /usr/local/bin/gcloud
    ln -s "${INSTALL_DIR}/bin/gsutil" /usr/local/bin/gsutil
    ln -s "${INSTALL_DIR}/bin/bq" /usr/local/bin/bq
    
    # Run gcloud --version to verify and initialize (it might install components)
    # Note: gcloud requires python3.
}

cleanup() {
    echo "Cleaning up..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk del .gcloud-build-deps 2>/dev/null || true
        apk cache clean
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum clean all
    fi
}

# Main Logic
# Try apt installation first on Debian/Ubuntu, fall back to tarball if it fails
# (e.g., due to Python version requirements - gcloud-cli requires Python 3.9+)
if command -v apt-get >/dev/null 2>&1; then
    if install_via_apt; then
        echo "Successfully installed gcloud via apt."
    else
        echo "apt installation failed, falling back to tarball installation..."
        install_dependencies
        install_via_tarball
    fi
else
    install_dependencies
    install_via_tarball
fi

cleanup

# Configure gcloud if project ID or Quota Project ID is provided
if [ -n "$PROJECT_ID" ] || [ -n "$QUOTA_PROJECT_ID" ]; then
    echo "Configuring gcloud defaults..."
    
    # Better approach for dev containers: Set CLOUDSDK_* env vars in a profile script
    # This effectively sets the defaults for all shells.
    
    echo "# gcloud configuration" > /etc/profile.d/gcloud-config.sh
    
    if [ -n "$PROJECT_ID" ]; then
        echo "Setting default project to ${PROJECT_ID}..."
        echo "export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}" >> /etc/profile.d/gcloud-config.sh
    fi
    
    if [ -n "$QUOTA_PROJECT_ID" ]; then
        echo "Setting quota project to ${QUOTA_PROJECT_ID}..."
        echo "export CLOUDSDK_BILLING_QUOTA_PROJECT=${QUOTA_PROJECT_ID}" >> /etc/profile.d/gcloud-config.sh
    fi

    chmod 644 /etc/profile.d/gcloud-config.sh
fi

echo "Done!"
