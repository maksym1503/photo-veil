#!/bin/bash
set -euo pipefail
cd "${CI_PRIMARY_REPOSITORY_PATH:?}"
# This hook is also invoked after failures; native xcresult is retained by Xcode Cloud.
if [ -n "${CI_RESULT_BUNDLE_PATH:-}" ] && [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
  xcrun xcresulttool get test-results summary --path "$CI_RESULT_BUNDLE_PATH" || true
fi
if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" = 0 ]; then
  case "${CI_XCODEBUILD_ACTION:-}" in
    archive)
      python3 scripts/ci/check_release.py "${CI_ARCHIVE_PATH:?}/Products/Applications/PhotoVeil.app"
      ;;
    build)
      case "${CI_WORKFLOW:-}" in
        'Veil Apple Integration')
          python3 scripts/ci/check_release.py "${CI_DERIVED_DATA_PATH:?}/Build/Products/Release-iphoneos/PhotoVeil.app"
          VEIL_RUN_DETECTION_BENCHMARK=1 swift test --filter DetectionBenchmarkTests
          python3 - <<'PY'
from pathlib import Path
for name in ['measurements.json', 'v43-composition.json']:
    print(name, Path('/tmp/veil-v4-diagnostics', name).read_text())
PY
          ;;
      esac
      ;;
  esac
fi
