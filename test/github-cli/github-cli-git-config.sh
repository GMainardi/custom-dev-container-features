#!/bin/bash
set -e

source dev-container-features-test-lib

check "gh version" gh --version

# Simulate env vars that would be passed from host
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"

# Simulate login shell behavior to trigger profile script
if [ -f /etc/profile.d/git-config-check.sh ]; then
    . /etc/profile.d/git-config-check.sh
fi

check "git user.name configured" bash -c "git config --global user.name | grep 'Test User'"
check "git user.email configured" bash -c "git config --global user.email | grep 'test@example.com'"

reportResults

