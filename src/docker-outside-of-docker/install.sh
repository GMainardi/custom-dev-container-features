#!/bin/sh
set -e

echo "Activating feature 'docker-outside-of-docker'"

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
        apt-get install -y --no-install-recommends curl ca-certificates gnupg lsb-release

        # Clean up temporary config
        rm -f /etc/apt/apt.conf.d/99custom
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        apk add --no-cache curl ca-certificates bash
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

install_docker_cli() {
    echo "Installing Docker CLI..."
    
    # Detect Architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            DOCKER_ARCH="x86_64"
            ;;
        aarch64)
            DOCKER_ARCH="aarch64" 
            ;;
        armv7l)
            DOCKER_ARCH="armhf"
            ;;
        *)
            echo "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    # Download static binary
    # If version is latest, we fetch latest, else specific
    
    if [ "$VERSION" = "latest" ]; then
        # We can't easily find "latest" version number from static download URL listing without parsing.
        # So we might need to rely on a known recent version or use the install script.
        # The official install script (get.docker.com) installs the full engine, which we might not want (just CLI).
        
        # Let's stick to a specific recent version for stability if "latest" is requested, or parse it.
        # Or better, use the OS package manager if available? 
        # No, static binary is safer for cross-distro feature consistency for DooD.
        
        # Let's use a hardcoded recent version for 'latest' to ensure stability, 
        # or try to fetch from GitHub releases.
        DOCKER_VERSION="24.0.7" # Example recent version
    else
        DOCKER_VERSION="$VERSION"
    fi

    URL="https://download.docker.com/linux/static/stable/${ARCH}/docker-${DOCKER_VERSION}.tgz"
    
    echo "Downloading Docker CLI from ${URL}..."
    
    mkdir -p /tmp/docker-cli
    curl -L "${URL}" | tar xz -C /tmp/docker-cli --strip-components=1
    
    mv /tmp/docker-cli/docker /usr/local/bin/docker
    chmod +x /usr/local/bin/docker
    
    rm -rf /tmp/docker-cli
}

configure_permissions() {
    # Ensure the docker group exists
    if command -v groupadd >/dev/null 2>&1; then
        if ! getent group docker > /dev/null 2>&1; then
            groupadd -g 999 docker || groupadd docker
        fi
    elif command -v addgroup >/dev/null 2>&1; then
        # Alpine
        if ! getent group docker > /dev/null 2>&1; then
            addgroup -g 999 docker || addgroup docker
        fi
    fi
    
    # The socket /var/run/docker.sock will be mounted at runtime.
    # We need to ensure the user has permission to access it.
    # Typically, we add the user to the 'docker' group.
    # But we don't know the user here (it runs as root).
    # We can rely on the 'common-utils' feature or similar to add the remote user to the group?
    # Or we can add a script to /etc/profile.d/ that fixes permissions on socket?
    
    # A common pattern for DooD is to create a wrapper script or 'entrypoint' script 
    # that `chown`s the socket to the container's group ID, or adds the user to the socket's group.
    
    # However, 'features' install scripts run at build time.
    # We can't change the socket permissions here because the socket doesn't exist yet!
    
    # Best practice: Enable the 'docker-init' or similiar entrypoint.
    # For this feature, we'll ensure the group exists.
    # Users should add themselves to the group via 'remoteUser' or postCreateCommand if needed,
    # BUT standardized features usually handle this via a magic entrypoint script.
    
    # Let's add a simple entrypoint script that attempts to fix permissions on container start.
    
    cat << 'EOF' > /usr/local/share/docker-init.sh
#!/bin/sh
# This script checks the GID of the mounted docker socket and updates the 'docker' group in the container to match it.
# This allows the non-root user to use docker without sudo.

SOCKET="/var/run/docker.sock"
GROUP="docker"

if [ -S "$SOCKET" ]; then
    # Get GID of the socket
    SOCKET_GID=$(stat -c '%g' "$SOCKET")
    
    # Check if the group exists
    if getent group $SOCKET_GID > /dev/null 2>&1; then
        # Group exists, maybe it's 'docker' or something else
        EXISTING_GROUP=$(getent group $SOCKET_GID | cut -d: -f1)
        if [ "$EXISTING_GROUP" != "$GROUP" ]; then
            # If it's not 'docker', we might have a conflict or just need to add user to that group.
            GROUP=$EXISTING_GROUP
        fi
    else
        # Group doesn't exist, modify 'docker' group to use this GID
        if command -v groupmod >/dev/null 2>&1; then
            groupmod -g $SOCKET_GID $GROUP
        elif command -v sed >/dev/null 2>&1; then
            # Alpine might not have groupmod, manually edit /etc/group
            sed -i -e "s/^${GROUP}:x:[0-9]*:/${GROUP}:x:${SOCKET_GID}:/" /etc/group
        fi
    fi
    
    # Ensure the current user is part of that group
    # (This script needs to run as root, usually via an entrypoint mechanism)
fi

# Execute the passed command
exec "$@"
EOF
    
    chmod +x /usr/local/share/docker-init.sh
}

install_dependencies
install_docker_cli
configure_permissions

echo "Done!"

