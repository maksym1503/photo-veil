#!/bin/bash
set -euo pipefail
cd "${CI_PRIMARY_REPOSITORY_PATH:?}"
python3 scripts/ci/validate.py
# Xcode Cloud resolves committed Package.resolved and executes the workflow's selected plan.
# Never launch another xcodebuild here or touch an owner's local signing settings.
