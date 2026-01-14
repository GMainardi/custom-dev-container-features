#!/bin/bash
set -e

source dev-container-features-test-lib

check "gcloud version" gcloud --version
check "architecture is arm64" bash -c "uname -m | grep -E 'aarch64|arm64'"

reportResults
