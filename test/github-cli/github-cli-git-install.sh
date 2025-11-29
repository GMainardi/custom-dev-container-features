#!/bin/bash
set -e

source dev-container-features-test-lib

check "gh version" gh --version
check "git version" git --version

reportResults

