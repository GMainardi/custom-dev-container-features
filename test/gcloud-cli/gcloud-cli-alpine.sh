#!/bin/bash
set -e

source dev-container-features-test-lib

# This tests the 'alpine' scenario in scenarios.json
check "gcloud version" gcloud --version
check "python3 version" python3 --version

reportResults

