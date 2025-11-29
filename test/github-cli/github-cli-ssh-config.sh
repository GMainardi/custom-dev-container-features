#!/bin/bash
set -e

source dev-container-features-test-lib

check "gh version" gh --version

# Simulate login shell behavior to trigger profile script
# Since we are running non-interactively, we manually source the profile script
if [ -f /etc/profile.d/gh-config-ssh.sh ]; then
    . /etc/profile.d/gh-config-ssh.sh
fi

# Check if config has been set
check "git protocol is ssh" grep -q "git_protocol: ssh" $HOME/.config/gh/config.yml

reportResults

