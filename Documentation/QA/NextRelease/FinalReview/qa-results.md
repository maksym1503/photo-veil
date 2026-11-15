# QA execution and evidence — 2026-11-15

Actual configured role `qa` (`.codex/agents/qa.toml`, gpt-6-luna/medium), existing
`/root/qa` thread. Read the established workflow and CI strategy; root implemented
the bounded changes, QA executed/classified native evidence. No new provider,
paid credits, signed build, production account or device-farm upload.

## Native results

| Scope | Actual outcome | Evidence / revision scope |
| --- | --- | --- |
| Full VeilPR |100/100 passed;93 core+7 UI; no failures/skips/expected failures; strict inventory verified | `/tmp/vail-final-pr.xcresult`, `/tmp/vail-final-pr.log`, [summary](results/pr.json). Current strict preview policy; before contained CTA label correction. |
| Focused PR premium-preview flow after CTA fix |1/1 passed | `/tmp/vail-final-pr-accessibility.xcresult`, `.log`, [summary](results/pr-accessibility.json). This is not another full100-case run. |
| Final native Light capture |1/1 passed | `/tmp/vail-final-capture-light-fixed.xcresult`, `.log`, [summary](results/capture-light-fixed.json). Actual Vision, Documents gesture/Undo/cache assertions, photo flows, successful exhaustion, paywall/Restore availability and dismissal. |
| Final native Dark capture |1/1 passed | `/tmp/vail-final-capture-dark-fixed.xcresult`, `.log`, [summary](results/capture-dark-fixed.json). Explicit simctl Dark; actual dark chrome inspected. Same assertions and150.33×58pt hittable CTA. |
| Full VeilCommerce |27/27 passed;14core+8hosted StoreKit+5UI; no failures/skips/expected failures; strict inventory verified | `/tmp/vail-final-commerce.xcresult`, `/tmp/vail-final-commerce.log`, [summary](results/commerce.json). Built separately on iOS26.1 using local StoreKit. |

PR and photographic captures used iPhone17Pro iOS26.5 simulator, destination
`995A38B2-A510-4791-93C3-6630BB588FDC`; native Commerce used iOS26.1 destination
`A9690442-69A8-4117-998B-0F31278091C7` (see native result device metadata for the
authoritative identifier). Build logs: `/tmp/vail-final-build-policy.log`,
`/tmp/vail-final-build-capture.log`, `/tmp/vail-final-build-accessibility.log`,
`/tmp/vail-final-commerce-build.log`. UI sessions were serialized.

## Focused core and Release validation

- `swift test --filter '.*(CommerceTests|PrivacyImageRendererTests|WatermarkTests).*'`:
  **41/41 passed**, Commerce14, renderer18, watermark9; [retained log](focused-core.log),
  original `/tmp/vail-final-core.log`. No failures or skips in the XCTest suites.
- `xcodebuild -project PhotoVeil.xcodeproj -scheme PhotoVeil -configuration Release
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/vail-refine-release
  CODE_SIGNING_ALLOWED=NO build`: **BUILD SUCCEEDED**, run2026-11-15.
  QA reused the prior local Release output/log path; current log is preserved as
  `/tmp/vail-final-release.log` to distinguish this checkpoint from historical runs.
- Existing guard `python3 scripts/ci/check_release.py
  /tmp/vail-refine-release/Build/Products/Release-iphonesimulator/PhotoVeil.app`:
  **passed**. [Retained guard output](release-guard.txt). No fixture analyzer, debug
  photos, local StoreKit fixture, commerce launch overrides or StoreKitTest linkage;
  privacy manifest/configuration check passed. This is an unsigned Simulator build,
  not a signed physical-device archive or distribution acceptance.
- `python3 scripts/ci/validate.py`:159-method inventory complete; PR excludes real
  Vision/system UI; legacy Integration retained. `git diff --check` passed.
- AppKit asset audit: all five candidates1320×2868 RGB JPEG, no alpha; fictional
  coast source has a GPS metadata field without logging its values. See marketing
  `asset-audit.json`. Final screenshot artwork and source/provenance are hashed.

## Protected behavior exercised

- Deterministic PR automatic Faces/Plates/Documents move/resize, normalized mapping,
  zoom/pan, independent regions/layers, scoped Undo, Documents details/whole
  coverage, cache re-entry, preview/export pixels and local save/gallery paths.
  Real Vision photographic captures additionally demonstrate detected Faces,
  Plates and actual automatic Documents manipulation; no fixture analyzer or
  Manual fallback in those capture cases.
- Premium-preview PR flow crosses modes/effects, zoom/pan, Undo, Done, foreground
  and relaunch; processed export fingerprints remain independent of marks.
- Commerce UI verifies actual successful allowance exhaustion, blocked subsequent
  editor/gallery clean exports, persistence, cancelled editor/gallery Shares,
  completed Share accounting and largest-text paywall presentation.
- Native trial/purchase test verifies marks and unlock CTA disappear after verified
  Pro; third/fourth saves succeed, restart retains entitlement. No post-Pro clean
  screenshot was attached, so Pro cleanliness here is asserted UI evidence rather
  than a fabricated photographic capture.
- Hosted native StoreKit covers trial duration, purchase/restart, cancellation,
  pending/failure/unverified transactions, Restore/shared trial eligibility,
  renewal/cancellation/expiration/refund/revocation and billing grace/retry.
  Pure Commerce covers successful-only accounting, failure/cancellation rollback,
  concurrent reservations, duplicate completion, persisted history, dirty-ledger
  read-only behavior and all preview-state/epoch branches.

## Original failures retained and corrected

1. `/tmp/vail-final-build.log`: test-only compile error converting CGFloat to
   String for AX evidence; corrected via Double conversion. Corrected builds pass.
2. `/tmp/vail-final-captures.xcresult`, `.log`: initial Light/Dark capture attempt
   failed both CTA minimum-height assertions (28.33pt). Actual UI accessibility
   defect, not infrastructure. Label min44 correction produced58pt targets and
   both final cases pass. [Original summary](results/captures.json).
3. Independent image inspection found initial Dark-labeled evidence was light UI;
   the launch argument did not change native appearance. QA explicitly booted,
   set simctl appearance before separate invocations, and confirmed actual dark
   pixels. First simctl setter against a shut-down destination failed before any
   test; QA booted it, then set appearance. No failed test was retried for timing.
   Light restored afterward; preboot getter returned unknown, so exact restoration
   of an unobservable initial setting is not claimed.

Original captured artifacts remain in marketing `InitialCapture/`; corrected
`captures/light/` and `captures/dark/` have xcresult attachment provenance. Initial
source hashes and task-start baseline preserve revision scope. Two corrected raw
light Before frames caught a label crossfade; they are supporting evidence only,
not the polished listing UI. Reviewer found final listing artwork unaffected.

No arbitrary sleep, timeout inflation, skipped requirement or retry-until-green.
Full Integration, macOS profiles, physical device/VoiceOver/system Photos/Share
acceptance and final owner approval remain separate release gates.
