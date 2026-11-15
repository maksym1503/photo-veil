#!/bin/bash
# One build-for-testing, then reuse its products. No implicit retries.
set -euo pipefail
plan=${1:-VeilPR}
case "$plan" in VeilPR|VeilIntegration|VeilDevice|VeilCommerce) ;; *) echo 'Unknown test plan' >&2; exit 2;; esac
if [ "$plan" = VeilDevice ] && [[ ",${VEIL_DESTINATION:-}," != *",platform=iOS,"* ]]; then
  echo 'VeilDevice requires an explicit physical destination: VEIL_DESTINATION=platform=iOS,id=<device-id>. Simulator acceptance is not physical-device evidence.' >&2
  exit 2
fi
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
  # StoreKitTest configuration activation fails on installed iOS 26.5 (23F77).
  # Preserve latest-runtime coverage for PR; never silently drop native tests.
  device=$(xcrun simctl list devices available --json | python3 -c '
import json,re,sys
plan=sys.argv[1]; groups=json.load(sys.stdin)["devices"]
def version(runtime): return tuple(map(int,re.findall(r"[0-9]+",runtime)))
if plan in ("VeilCommerce","VeilIntegration"):
    candidates=groups.get("com.apple.CoreSimulator.SimRuntime.iOS-26-1",[])
    candidates=sorted(candidates,key=lambda d: d["name"]!="Veil-CommerceNative-261")
else:
    candidates=[d for runtime in sorted(groups,key=version,reverse=True) for d in groups[runtime] if ".iOS-" in runtime]
chosen=next((d for d in candidates if d["name"] in ("iPhone 17 Pro","Veil-CommerceNative-261")),None)
if chosen is None:
    sys.exit("No supported simulator. StoreKit plans require iOS 26.1: install with xcodebuild -downloadPlatform iOS -buildVersion 26.1 -architectureVariant universal; create an iPhone simulator or set VEIL_DESTINATION explicitly.")
print(chosen["udid"])
' "$plan")
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" -b
  VEIL_DESTINATION="platform=iOS Simulator,id=$device"
fi
args=(-project PhotoVeil.xcodeproj -scheme PhotoVeil -testPlan "$plan" -destination "$VEIL_DESTINATION" -derivedDataPath "${VEIL_DERIVED_DATA:-$output/DerivedData}")
phase=compilation
printf 'PHASE: compilation, plan=%s\n' "$plan"
xcodebuild "${args[@]}" build-for-testing 2>&1 | tee "$output/build.log"
build_end=$(date +%s)
printf '{"build_and_setup_seconds":%s}\n' "$((build_end-start))" > "$output/phases.json"
phase=test-execution
# Keep graphics-heavy PR workers and app-hosted StoreKit/system UI isolated.
# The mixed Integration run stalled in XCTest and missed accelerated StoreKit
# transitions. Its exact native-service cause is unresolved; do not overlap hosts.
parallel=YES
if [ "$plan" = VeilPR ] || [ "$plan" = VeilCommerce ] || [ "$plan" = VeilIntegration ]; then parallel=NO; fi
printf 'PHASE: %s tests\n' "$plan"
# Plan controls isolation/parallelism. Do not force all legacy system-UI cases parallel.
xcodebuild "${args[@]}" test-without-building -resultBundlePath "$output/Tests.xcresult" \
  -parallel-testing-enabled "$parallel" -maximum-concurrent-test-simulator-destinations 2 \
  -maximum-parallel-testing-workers 2 2>&1 | tee "$output/tests.log"
phase=execution-inventory
python3 scripts/ci/verify_execution.py "$plan" "$output/Tests.xcresult"
printf 'PHASE: tests passed\n'
