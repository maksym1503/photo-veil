#!/bin/bash
# One build-for-testing, then reuse its products. No implicit retries.
set -euo pipefail
plan=${1:-VeilPR}
case "$plan" in VeilPR|VeilIntegration|VeilDevice) ;; *) echo 'Unknown test plan' >&2; exit 2;; esac
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
output=${VEIL_CI_OUTPUT:-$(mktemp -d "/tmp/veil-ci-${plan}.XXXXXX")}
mkdir -p "$output"
exec > >(tee "$output/pipeline.log") 2>&1
start=$(date +%s)
phase=setup
finish() {
  status=$?
  python3 scripts/ci/summarize_results.py "$output/Tests.xcresult" "$output" "$start" "$status" "$phase" || true
  exit "$status"
}
trap finish EXIT
python3 scripts/ci/validate.py
xcodebuild -version
if [ -z "${VEIL_DESTINATION:-}" ]; then
  device=$(xcrun simctl list devices available --json | python3 -c 'import json,sys; ds=json.load(sys.stdin)["devices"]; print(next(d["udid"] for group in ds.values() for d in group if d["name"]=="iPhone 17 Pro"))')
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" -b
  VEIL_DESTINATION="platform=iOS Simulator,id=$device"
fi
args=(-project PhotoVeil.xcodeproj -scheme PhotoVeil -testPlan "$plan" -destination "$VEIL_DESTINATION" -derivedDataPath "${VEIL_DERIVED_DATA:-$output/DerivedData}" CODE_SIGNING_ALLOWED=NO)
phase=compilation
printf 'PHASE: compilation, plan=%s\n' "$plan"
xcodebuild "${args[@]}" build-for-testing > "$output/build.log" 2>&1
build_end=$(date +%s)
printf '{"build_and_setup_seconds":%s}\n' "$((build_end-start))" > "$output/phases.json"
phase=test-execution
printf 'PHASE: %s tests\n' "$plan"
# Plan controls isolation/parallelism. Do not force all legacy system-UI cases parallel.
xcodebuild "${args[@]}" test-without-building -resultBundlePath "$output/Tests.xcresult" \
  -parallel-testing-enabled YES -maximum-concurrent-test-simulator-destinations 2 \
  -maximum-parallel-testing-workers 2 > "$output/tests.log" 2>&1
printf 'PHASE: tests passed\n'
