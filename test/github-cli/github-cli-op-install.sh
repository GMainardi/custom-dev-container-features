#!/bin/bash
set -e

source dev-container-features-test-lib

check "gh version" gh --version
check "op version" op --version
check "socat installed" command -v socat

reportResults

