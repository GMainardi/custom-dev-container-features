#!/bin/bash
set -e

source dev-container-features-test-lib

check "docker version" docker --version
check "architecture is arm64" bash -c "uname -m | grep -E 'aarch64|arm64'"

reportResults
