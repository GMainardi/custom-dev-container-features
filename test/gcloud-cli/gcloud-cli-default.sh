#!/bin/bash
set -e

source dev-container-features-test-lib

# This tests the 'default' scenario in scenarios.json
check "gcloud version" gcloud --version

reportResults

