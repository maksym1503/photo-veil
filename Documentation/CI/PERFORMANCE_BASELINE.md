# CI performance baseline

Measured on 2026-10-08. Raw native result bundles and CI timestamps are authoritative. Local Intel Mac / Xcode 26.6 / iOS 26.5 timings are not predictions of Xcode Cloud or Apple Silicon hosted performance. Queue time, build time and test execution are separate.

| Pipeline / run | Wall / execution | Outcome / bottleneck |
|---|---|---|
| Old hosted Intel monolith, GitHub run 37637398123 | job ~62 min; UI 2,907 s (48.45 min) | 34/35 UI passed; cold Documents analysis exceeded readiness bound |
| Old hosted Intel monolith, run 37680655201, df3f288 | job 93m47s (20:17:17–21:51:04 UTC); UI 4,860.425 s (81.01 min) | Documents passed in 124.170 s; six unrelated timing-sensitive UI failures; backend passed |
| Previous complete local suite | UI 1,267.446 s (21.12 min), plus core/build | all 35 UI passed; shows hosted slowdown without proving every hosted timeout is infrastructure |
| Initial new local PR plan, serial pilot | native build log elapsed ~62 s; test session 160.75 s; UI 108.529 s | 52/52 passed, 0 skipped. Build + execution ~223 s, excluding idle between manual commands; not an end-to-end script measurement |
| New local full Integration plan | native execution **1,382.129 s (23m02s)**; all legacy UI aggregate **1,301.018 s (21m41s)**; setup/build + execution ~24m27s | **85/85 passed, zero skipped**. Real Documents core 9.283 s; real faces/tiled core 4.163 s. A separate local UI pilot overlapped part of this run and was cancelled; this is correctness evidence, not an isolated speed comparison. |

| Final standalone local PR plan, iPhone 13 mini / Dark | **232.51 s (3m52.5s) end-to-end**, setup/incremental build 25 s; native session 200.033 s; four UI cases aggregate 115.098 s | **52/52 passed, zero skipped**, two native workers; no overlapping UI invocation. Reused build products are explicit; cold pilot build is recorded above. |

## Architecture changes being measured

Old PR: SwiftPM core then one `xcodebuild test` building/running all legacy UI serially on Intel; push + PR duplicated/cancelled runs. No distinction between UI state, real model startup and OS service timing.

New PR: 48 native deterministic core + four bounded deterministic UI smokes; one build-for-testing then test-without-building. PR core and UI execute serially to avoid virtual-GPU contention; Integration core permits two workers, UI is serial/isolated; no automatic retries. New fallback uses macos-26 ARM64 and pinned Xcode 26.6. All 35 old UI tests move intact to Integration with real Vision. Integration contains 85 native cases plus two macOS-only profiles. Device acceptance is one focused method, manual/approved.

The finalized local script measurement is recorded above. Hosted measurements are retained in workflow artifacts and the final PR handoff. Xcode Cloud and real-device provider runtime cannot be measured before owner activation; do not claim their performance from local results.

## Remaining nondeterminism

Real Vision recall/model availability and cold startup; Simulator OS permission/Photos/Share scheduling; native accessibility queries; animation phase timing; headless font/GPU performance; provider resets and re-signing. These stay visible in Integration/device acceptance. Deterministic render pixel semantics, state/history and persistence are required in the PR gate. A faster gate does not imply a release candidate passed real integration.

## Measurement integrity

A compact-device PR pilot was cancelled (exit 143) because it overlapped the full local integration invocation. Its ~315 s partial wall time is not a completed PR result and is excluded from speed claims. The full integration native bundle is green; the shell wrapper was edited during that long-running pilot and printed an end-of-file parse diagnostic after xcodebuild had already succeeded. Native 85/85 results are authoritative. The finalized wrapper is syntax-checked and validated separately by the standalone PR run; scripts must not be edited while executing in future measurements.

Hosted gate durations are exported automatically in `timing.json`/`phases.json`, with native per-test durations in `tests.json`; the workflow run and final PR handoff document the measured hosted result. Xcode Cloud / vendor performance remains unmeasured pending owner setup.

macOS full core + two opt-in real-Vision/performance methods: **50 passed, zero skipped, 10.163 s** test execution. Five-layer render + JPEG: 0.081 s at 1440×1800, 0.282 s at 4032×3024, 1.215 s at 8064×6048 on the local Intel Mac. See VALIDATION.md for all evidence paths and release/archive results.

## First hosted layered pilot (not accepted)

Run 37738927381, d4bcf56: backend and repository-security passed; native PR **51/52 passed**, job 15m17s, measured script wall 890.06 s, setup/cold build 470 s. The failed composed UI case timed out at the first Faces render, after deterministic analysis had completed. The native activity trace and recording show render pending, not a Vision or state assertion failure. Core and UI workers overlapped on the same hosted virtual GPU. Contention is a hypothesis, not a proven product diagnosis. The next experiment serializes the small PR plan (without changing waits, assertions, production renderer or coverage) and streams build/test output for progress diagnostics. This red pilot is retained; it is not merge evidence.

Serial PR validation: iPhone 17 Pro / Light, **52/52 passed, zero skipped**, **287.10 s end-to-end**, setup/cold package + build 125 s, native 157.045 s, four UI methods 105.472 s. Evidence `/tmp/veil-layered-pr-serial/`. This is not a speed comparison with the warm compact-device run. No wait or execution allowance changed. The hosted action log confirms core and UI runner lifetimes overlapped during the first Background scenario; it does not prove concurrent graphics caused the later first-Faces timeout. The serial run is a scheduling experiment with identical assertions, not a claimed diagnosis of a renderer bug.
