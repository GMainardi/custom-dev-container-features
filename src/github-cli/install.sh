#!/bin/sh
set -e

echo "Activating feature 'github-cli'"

VERSION=${VERSION:-"latest"}
AUTH_SSH=${AUTHSSH:-"false"}

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
        
        apt-get update
        apt-get install -y curl ca-certificates gnupg dirmngr

        # Clean up temporary config
        rm -f /etc/apt/apt.conf.d/99custom
    elif command -v apk >/dev/null 2>&1; then
        # Alpine
        echo "Installing dependencies for Alpine..."
        apk add --no-cache curl libc6-compat bash
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora/RHEL 8+
        echo "Installing dependencies for Fedora/RHEL..."
        dnf install -y curl
    elif command -v yum >/dev/null 2>&1; then
        # RHEL 7/CentOS
        echo "Installing dependencies for RHEL/CentOS..."
        yum install -y curl
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

install_ssh_client() {
    # However, we can install `openssh-client` (ssh) to ensure the agent can be used.
    if command -v apt-get >/dev/null 2>&1; then
        apt-get install -y openssh-client
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache openssh-client
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y openssh-clients
    elif command -v yum >/dev/null 2>&1; then
        yum install -y openssh-clients
    fi

    # Configure gh to use ssh protocol if requested
    if [ "$AUTH_SSH" = "true" ]; then
        echo "Configuring gh to use SSH protocol..."
        # 'gh config set git_protocol ssh' usually writes to ~/.config/gh/config.yml.
        # Since we are root during install, we need to configure this for the user.
        # We can effectively set this by setting the GH_CONFIG_DIR to a shared location 
        # or by creating a profile script that sets an alias or similar, but gh doesn't have an env var for protocol.
        
        # Best effort: Create a global config file if possible or use a post-create script mechanism.
        # Since we can't easily run as the remote user here without knowing who they are (often 'vscode' or 'node'),
        # and 'gh' doesn't look at a system-wide config file for this setting typically.
        
        # Workaround: We can add a script to /etc/profile.d/ that attempts to set the config 
        # IF the config file doesn't exist yet or just warns.
        # A cleaner way is to use the 'gh config set -h' but that's host specific.
        
        # Actually, we can just tell the user to run it, OR we can create a one-time init script.
        # Let's create a script that runs on login to ensure the preference is set if not already set.
        
        cat << 'EOF' > /etc/profile.d/gh-config-ssh.sh
#!/bin/sh
# Check if gh is installed and if we haven't configured this yet
if command -v gh >/dev/null 2>&1; then
    # Check if config exists
    if [ ! -f "$HOME/.config/gh/config.yml" ] || ! grep -q "git_protocol: ssh" "$HOME/.config/gh/config.yml"; then
        # We don't want to overwrite existing user config silently on every shell, 
        # but for a fresh container this helps.
        # Just run it silently. If it fails, ignore.
        mkdir -p "$HOME/.config/gh"
        gh config set git_protocol ssh >> /dev/null 2>&1 || true
    fi
fi
EOF
        chmod 755 /etc/profile.d/gh-config-ssh.sh
    fi
}

install_dependencies
install_gh
install_ssh_client
cleanup

echo "Done!"

