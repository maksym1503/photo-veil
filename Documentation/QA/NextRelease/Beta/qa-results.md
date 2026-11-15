# Vail1.1 final-source QA

Code commit: `2e4d3ee4d01d89796ef34279f977f0343b63ed49`.
Configured `qa` (gpt-6-luna/medium), `/root/beta_qa`, executed final suites after
independent Reviewer fixes/rechecks. Root ran the earlier candidate PR during the
QA usage limit; that older run is not substituted for this fresh final-source run.
QA performed no source or documentation edits. Native UI sessions were serial.

| Scope | Result | Evidence |
| --- | --- | --- |
| Full VeilPR |102/102,95core+7UI; strict exact inventory; zero failures/skips/expected | `results/final-pr.json`; `/tmp/vail11-beta-qa/final/pr.xcresult`, `pr-tests.log`, `pr-build.log` |
| Full local Integration compatibility matrix |153/153 unique:144on26.5+9on26.1; exact one-run IDs/runtimes, zero failures/skips/expected; same source/build before/after | `matrix-result.json`, four fingerprint JSONs, `results/integration-*.json`; native logs/bundles under `/tmp/vail11-beta-qa/final/matrix/` |
| Full VeilCommerce |31/31 =16core+8hosted StoreKit+7UI; strict verifier, no failures/skips/expected | `results/commerce.json`; `/tmp/vail11-beta-qa/final/commerce.xcresult`, `commerce-tests.log`, `commerce-build.log` |
| Explicit actual-Dark capture |1/1; simctl Dark verified, screenshot pixels inspected, restored/verified Light; CTA frame minimum asserted | `results/dark-capture.json`, `captures/dark-preview.png`, capture provenance |
| Default SwiftPM |97discovered:95passed,2documented opt-in skips;0failures | `swiftpm-default.log` |
| Explicit macOS profiles |2/2 opt-in methods executed/pass;97unique package methods therefore passed across separate invocations | `swiftpm-optin-profiles.log`; `VEIL_RUN_DETECTION_BENCHMARK=1 swift test --filter DetectionBenchmarkTests` |
| Unsigned generic Simulator Release |BUILD SUCCEEDED; resources/privacy guard PASS | `/tmp/vail11-beta-qa/final/release-build.log`, `/tmp/vail11-beta-dd-final-release`; retained `release-guard.log` |

The matrix is the CTO-approved local runtime compatibility workflow, **not** a
single-runtime full Integration pass. Native StoreKit uses26.1 because26.5 rejects
its test configuration; actual Vision remains on26.5. No cases were deleted,
quarantined or retried to obtain green. PR/Commerce/SwiftPM suites overlap.

## Required behaviors actually exercised

- Automatic Faces/Plates/Documents detection; body moves/corner resize, independent
  regions, normalized transforms, zoom/pan, scoped Undo, cache re-entry and Details/
  Entire Document distinction. Real Vision Documents photographic manipulation
  asserts move-only/resize-only dimensions, Undo geometry/pixels and single analysis.
- Composed mixed effects, background/manual layers, custom watermark, source
  replacement, rapid state changes, preview/full-resolution export fingerprints,
  image quality, metadata Remove/Keep and protected persisted gallery flows.
- New absent record limit1: first successful Veil save, cancelled Share free,
  second editor Save/Photos/Share blocked, relaunch and gallery paths blocked.
- Legacy0 preserves two successes; legacy1 preserves its remaining successful
  Share then blocks Save and remains exhausted after relaunch. Core decodes legacy
  counts0/1/2, v2 roundtrip, malformed/boolean/unknown data, failed migration probe,
  dirty success/retry, duplicate callbacks, concurrent reservation and Pro bypass.
- Native Photos denial and cancelled editor/gallery Shares do not consume usage.
  Completed Share consumes one shared use. Trial purchase removes marks/CTA, allows
  further clean exports and survives restart. Hosted signed lifecycle tests include
  monthly/annual, Restore, shared trial eligibility, expiry/refund/revocation, grace
  and billing retry, cancellation/pending/failure/unverified transactions.
- Quiet Lattice persists across modes/effects, zoom/pan, Undo, Done, relaunch and
  foreground transitions; Pro is clean. Overlay is outside exported pixels.
  Actual fresh Light gallery and Dark redacted editor captures were inspected;
  source photo examples are synthetic, not customer photographs.

## Preserved original failures / limitations

The first pre-fix26.5 run failed V43Composed's second export admission because an
old test assumed two uses without a legacy record. Source/log establish a fixture
regression: product correctly blocked Share after Save. SIGINT left its native
bundle incomplete; no failure-image inspection is claimed. Raw log/bundle retained
in `/tmp/vail11-beta-qa/matrix/`; `initial-matrix-failure.json` records exact scope.
Reviewer audited all multi-output paths and rechecked three targeted legacy0
fixtures with assertions retained. Fresh complete153case run above passes all.
An aggregate verifier was also invoked before the26.1 result existed; it correctly
reported incomplete inputs. Final aggregation after both shards passes strictly.

Hosted GitHub Apple checks ended at their20minute job budget with incomplete
coverage; no assertion failure was recorded. They are not green and cause of
remote slowness is unproven. Final code repository-security/backend checks pass.
CTO accepted internal beta upload against strict local results; merge/public
acceptance remains blocked pending owner review and required CI qualification.
No timeout inflation, old-job retry or provider activation. See `ci-history.json`.

Physical iPhone installation, Apple server Sandbox, VoiceOver/gesture feel, Photos/
Share extensions and12–48MP device memory/color/performance remain owner beta
checks. The one physical inventory case is not claimed executed on a Simulator.
Signed archive/export validation is recorded separately after this QA checkpoint.
