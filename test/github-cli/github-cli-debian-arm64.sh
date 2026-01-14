#!/bin/bash
set -e

source dev-container-features-test-lib

check "gh version" gh --version
check "git version" git --version
check "ssh client installed" command -v ssh
check "socat installed" command -v socat
check "architecture is arm64" bash -c "uname -m | grep -E 'aarch64|arm64'"

reportResults
