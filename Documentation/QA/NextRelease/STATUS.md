# Vail 1.1 — historical development checkpoints

> Current authorized internal beta: [Beta status](Beta/STATUS.md). Maksym approved
> all five Editorial Calm designs, Quiet Lattice and the new1/legacy2 policy.
> Migration is implemented in ADR-014; the older pending-gate notes below are
> historical. Internal TestFlight upload is authorized; public release/merge are not.

> Latest checkpoint: [2026-11-15 final-review evidence](FinalReview/STATUS.md)
> includes targeted Editorial Calm refinements, genuine light/dark app captures,
> independent configured Reviewer/CTO findings and current QA. The specifically
> requested dedicated Design Agent configuration is unavailable. One-export
> migration, final asset approval and release acceptance remain owner gates.
> Historical implementation and baseline assessment below remain revision-scoped.

Date: 2026-11-14. Branch: `feature/vail-1-1`. Not release/merge acceptance.
Existing dirty production preparation and signing/team settings were preserved.
No production credentials, providers, App Store Connect changes or uploads were used.

## Architecture assessment

Production baseline is behaviorally reconciled, not independently binary-reproduced.
The owner identifies production as 1.0(7). Retained Release-1.0 candidate hashes match
current `CommercePolicy.swift`, its tests and the canvas baseline. Later build7
records preserve two free successful exports and `vail.pro.monthly` /
`vail.pro.annual` with the existing introductory-trial eligibility checks. Older
WAITING_FOR_REVIEW documentation predates the owner's current production statement.
The retained archive in `/tmp` is no longer present. There is no conflicting quota
implementation that needs replacement.

| Concern | Existing component / 1.1 approach |
| --- | --- |
| Detection | `PrivacyAnalysis`, `FaceDetection`, `DocumentDetection`, `DetectedPrivacySelection`; cached analysis is unchanged. |
| Geometry and gestures | `ImageGeometryMapper`, `ZoomablePhotoCanvas`; same top-left normalized rectangles, UIKit image-content space, two-finger navigation. |
| Composition | `PrivacyImageRenderer`, `PrivacyPreviewRenderer`, Home `renderLayers`; one layer snapshot resolves adjustments for preview and full-resolution export. |
| Undo | Home `EditSnapshot` and `ScopedUndoHistory`; category adjustment maps added to scoped snapshots, separate whole-document map. |
| Export | `PhotoExport`, `MetadataSafeJPEG`, `PhotosSaver`, gallery store and Share completion; destination success contracts unchanged. |
| Commerce | `VeilExportAccess`, `ExportAllowance`, device-only Keychain `free-exports-v1`, verified `VeilSubscriptionStore`; untouched pending migration decision. |
| Persistence | No editable recipe, schema/backend/format migration. Geometry is session-only; existing saved flattened files remain unchanged. |

[ADR-013](../../Engineering/Decisions/013-adjustable-detections-premium-preview.md)
records accepted geometry and proposed commerce/presentation contracts. No second
renderer, new dependency, provider or screenshot-blocking API was introduced.

## Implemented so far

Selected automatic Faces, Plates and Documents can be moved and resized. Taps
still toggle regions. Body and corner gestures are distinct; changes commit once
and cancellation discards the draft. Separate normalized override maps preserve
cached analysis and document Details / Entire Document identity. Re-entry retains
adjustments; scoped Undo restores only the affected category, and Reset/Undo
include geometry. Native accessibility actions move and resize active detections.

[Marketing review](../../Marketing/AppStore/NextRelease/README.md) contains three
directions, two representative screenshots each, contact sheets, reproducible
layout source, synthetic photo provenance and two premium-preview concepts.
Final-set production stops for Maksym's direction selection.

## Owner decision holding commerce work

Build7 allowed two exports. Proposed uniform limit one makes historical count1
exhausted and removes that user's unused second export. The CTO identified this
as an owner product decision; root asked explicitly. Pending that response,
quota, StoreKit, export authorization and commerce preview presentation remain
unchanged. The next release's one-free-export policy and watermark are **not yet
implemented**. This checkpoint must not ship as fulfillment of those requirements.

Recommendation: apply limit one uniformly, preserve historical count0/1/2 and the
same Keychain record without rewriting usage. Alternative: grandfather prior
remaining allowance, requiring an explicit eligibility policy. New non-Pro users
must receive exactly one in the completed release either way. Keep subscription
verification, Restore and actual introductory-offer eligibility unchanged.

## Validation and review

- `swift test --filter ImageGeometryMapperTests`: 3/3 passed, no failures.
- Native build initially failed on canvas API/enum syntax; corrected builds passed.
  Original `/tmp/vail11-build.log`, corrected `/tmp/vail11-build-corrected.log`,
  latest reviewed `/tmp/vail11-build-reviewed.log` are retained.
- Initial VeilPR: **94/95 passed**, 0 skipped (89 core passed, five UI passed).
  New geometry UI test failed the plate corner resize assertion after successful
  face manipulation, plate body change, Undo and tap checks. Classification:
  product UI gesture arbitration; no timeout/infrastructure diagnosis claimed.
  `/tmp/vail11-pr.xcresult`, `/tmp/vail11-pr.log`, attachments and initial source
  hashes are retained. This run is not green.
- Fix: native one-touch pan and tap-requires-pan-failure for automatic regions;
  proportional corner hit area preserves small-region body dragging. Tests now
  separately assert origin/size changes, not merely any rectangle change.
- First corrected native UI execution: the original unchanged-rectangle failure
  is fixed; the stronger corner-origin assertion exposed move-vs-resize
  misclassification on the plate. Native pan initiation reconstructed the initial
  point instead of preserving touch-down. Reviewer recommends capturing the
  first touch inside the recognizer and using that exact point. This run is
  preserved separately in `/tmp/vail11-pr-ui-corrected.xcresult`: **5/6 UI
  passed**, 0 skipped. It is not green. Root implemented the reviewer's native
  recognizer subclass, retaining exact touch-down until reset; context/layout
  changes cancel both possible and active pans. The Reviewer rechecked: no findings.
  `/tmp/vail11-build-touch-origin.log` passed.
- Final corrected affected UI workflow: **1/1 passed**, 0 skipped, native exit0;
  `/tmp/vail11-geometry-final.xcresult` and `/tmp/vail11-geometry-final.log`.
  It reached all three region types, separate body/corner invariants, second-region
  independence, tap selection, scoped Undo, document coverage, zoom and actual
  adjusted Save-to-Veil export fingerprint parity. This is a targeted pass, not
  a rerun of all95 PR cases on the final source. Core89 and the other five UI
  cases have their earlier scoped passing evidence; full release acceptance remains.
- Real-Vision marketing capture: **1/1 passed**, 0 skipped, native exit0.
  `/tmp/vail11-marketing.xcresult`, `/tmp/vail11-marketing.log`; before/after
  captures retained in the marketing folder. Both actual faces were found and
  masked. This is one synthetic scene, not a general detector-accuracy guarantee.
  No substituted detector geometry was used for marketing.
- QA visually inspected the final contact sheets and preview concepts: no blocking
  findings, six correctly sized1320 ×2868 mockups, readable type and matching C
  Before/After sources. C's AFTER label is close to the device edge but visible.
  The preview watermark artwork remains a concept, not implemented app behavior.
- Root verified the whole project file byte-for-byte against the pre-task copy:
  identical, including existing signing/team settings. QA made no project changes.
  `git diff --check` and inventory validation (152 assigned tests) pass.
- Independent Reviewer inspected the actual task diff against the preserved
  pre-task source ([task source diff](task-source.patch.gz)), found and rechecked fixes for short-drag selection/double undo,
  stale document-coverage gestures, drag recognition and stale accessibility
  geometry. Latest recognizer re-review: **no findings**. Reviewer made no edits
  and ran no tests. Native execution remains distinct evidence.
- Inventory validation: all tests assigned to existing layers; new PR method plus
  one real-Vision Integration marketing-capture method. No provider, timeout,
  retry policy, quarantine or test architecture change.

## Roles actually used

Root Engineering Lead integrated Home state, tests, documentation and concepts.
Read-only CTO (`gpt-6-astra`) audited contracts/lineage and identified the migration
gate. Developer (`gpt-6-luna`) implemented the bounded canvas change; root corrected
compile and runtime interaction findings. Independent Reviewer (`gpt-6.1-sol`)
reviewed actual diffs and fixes. QA (`gpt-6-luna`) ran native tests and classified
the original failure. At most two children were active; no nested agents.
The daemon restarted after initial implementation; the Reviewer/QA were fresh
threads after recovery. No independence is claimed for the root's own review.

## Remaining acceptance work

Owner migration decision → implement exactly-one policy, observable preview state,
preview-only pattern and contextual existing-paywall CTA → independent review,
commerce/preview regressions and QA. Confirm historical counts, success/failure/
cancellation/concurrency, relaunch, Pro/restore/expiration/trials and transition
coverage. Neither preview concepts nor historical commerce tests prove that work.

Physical VoiceOver, adding a second finger during a drag, detector recall,
large-photo performance and full exact-candidate release Integration are still
required. No new detection-accuracy claim is made from substituted PR geometry.
Prepare version/build and reviewable PR after integration; do not sweep unrelated
uncommitted production/signing work into a commit. No commit, PR, protected merge,
build upload, release or App Store screenshot publication has occurred in this task.
README's V4 owner/backend acceptance gate remains. Final App Store screenshots
require direction approval; publishing requires separate explicit owner approval.
