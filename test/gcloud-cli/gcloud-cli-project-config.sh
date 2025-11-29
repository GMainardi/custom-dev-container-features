#!/bin/bash
set -e

source dev-container-features-test-lib

check "gcloud version" gcloud --version
check "project id env var" bash -c "echo $CLOUDSDK_CORE_PROJECT | grep 'my-test-project'"
check "quota project id env var" bash -c "echo $CLOUDSDK_BILLING_QUOTA_PROJECT | grep 'my-quota-project'"

reportResults
