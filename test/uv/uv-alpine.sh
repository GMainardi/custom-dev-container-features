#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv version" uv --version

reportResults

