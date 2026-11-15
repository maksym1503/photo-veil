# Refined Editorial Calm and native Quiet Lattice — historical review checkpoint

Superseded by the [2026-11-15 final-review checkpoint](../FinalReview/STATUS.md).
The evidence and original scope below remain historical; dark photographs in this
round were in light application appearance. The later checkpoint adds verified
dark application appearance, stronger plate/Documents evidence, and CTA sizing.

Owner selected A/A for further development, with final production assets explicitly
unapproved. Work stays on `feature/vail-1-1`. No merge, upload, App Store Connect
change, live screenshot replacement or application publication.

## Implemented

- Native screen-space Quiet Lattice over the photograph's visible bounds in editor,
  final review and gallery thumbnails/detail, including zoom/pan/layout changes.
  Small lower-opacity white labels with a fine gray outline replace the heavier
  round-one treatment. One accessible label; no touch interception.
- Shared presentation policy uses read-only existing usage and verified current
  StoreKit preview entitlement. Pro is immediately clean, even with unavailable
  quota storage. Exhaustion is derived from the actual shared limit. Unknown
  entitlement with exhausted/unknown usage receives an opaque checking cover;
  verified-free storage errors use honest unavailable-access messaging.
- Synchronous native invalidation protects old frames before foreground privacy
  shield removal and before SwiftUI reconciliation. Epoch/revision guards reject
  obsolete StoreKit scans. This state is separate from advertising/catalog loading
  and does not change export authorization, subscriptions or trial eligibility.
- Preview Mode + Unlock Clean Exports use the existing native action style and
  paywall. Restore, actual product prices/offers and paywall dismissal remain.
- Five refined screenshot candidates use five distinct fictional photographic
  scenes, actual running-app UI, original-photo feature crops and restrained device
  depth. Light/dark watermark examples are actual redacted app previews, not added
  graphic overlays. Raw captures, source images, prompts and generation code retained.

The lattice never enters `PrivacyImageRenderer`, custom `PhotoWatermark`, exported
bytes, flattened gallery pixels, thumbnails or cloud data. It neither disables nor
claims to prevent screenshots. Original comparison remains explicitly unedited.

## Policy decision still pending

The allowance remains **two** successful free exports, matching production build7.
No usage record, Keychain identity, count or threshold is migrated/reset. Applying
one to historical count-one users removes their unused second export and remains
an owner decision. Preview is independently implemented now and follows the actual
limit; this refinement does not claim to finish the one-free-export release policy.

## Review and roles

Root was Engineering Lead/integrator and artwork implementer. Read-only CTO
`gpt-6-astra` approved the architecture and then independently reviewed actual
baseline diffs (it implemented nothing). The existing `gpt-6-luna` QA thread acted
as bounded Developer for only the UIKit lattice/canvas file, then switched to QA
execution, as permitted by the two-child workflow. That QA worker completed PR
and capture validation, then reached its session usage limit. Root continued the
remaining local StoreKit/Release validation without activating paid credits. QA is not claimed independent
of its own canvas implementation; independent critical review came from Astra.
No nested agents; at most two active children.

Critical review: no blocking findings. A root static follow-up identified the
clean wrapper's early-return initialization risk; explicit transparent background,
nonopaque backing and initial accessibility state were added. The Reviewer rechecked
that fix and the loaded-gallery capture: no findings. Native gallery screenshot
inspection confirmed actual visible processed pixels without an opaque backing or
marks while allowance remained. Independent CTO-thread visual review found no
blocking findings in both contact sheets or the clean gallery image; static-image
review is not transition/accessibility/device QA.

## Validation

- SwiftPM Commerce: **14/14 passed** (read-only/dirty ledger, unknown access, counts
  0/1/2, actual-limit behavior, Pro bypass and stale epoch protection included).
- Native full VeilPR before the final initialization correction: **100/100 passed**,
  93 core + seven UI, zero skips/failures/expected failures; strict inventory verifier
  passed. `/tmp/vail-refine-pr.xcresult`, `/tmp/vail-refine-pr.log`.
  New workflow covers actual successful exhaustion, all tools/effects, custom
  watermark/Undo, original comparison, final review, zoom/pan, background/foreground,
  relaunch and unchanged successful export fingerprints.
- Final initialization correction only makes the clean lattice transparent from
  creation; frozen source hashes are separate from the pre-correction PR snapshot.
  `final-source-hashes.json` additionally records the later test-only synchronization
  correction; all production source remained unchanged after the successful capture.
- Actual photographic capture journey on the final initialization correction:
  **1/1 passed**, 127.8s, zero failures/skips. `/tmp/vail-refine-capture.xcresult`
  and `/tmp/vail-refine-capture.log`;11 raw native PNG captures retained with
  provenance. Includes a real clean gallery and actual exhausted light/dark previews.
- Initial native Commerce on iOS26.1: **26/27 passed**, 0 skipped. The added
  immediate Restore-preview assertion observed `unknown` while a newer native
  listener scan owned publication. Independent CTO reassessment classified this
  as test synchronization, consistent with the protected checking-cover contract.
  Original `/tmp/vail-refine-commerce.xcresult` and log are retained as failed.
- Corrected native expectations observe verified Pro/free publications, assert
  presentation from the emitted value, preserve unloaded-catalog and signed
  expiry/revocation assertions, and use the existing single10-second bound.
  Production code is unchanged. **4/4 affected native cases passed**, zero skips:
  restore/yearly, monthly expiry, refund and billing retry. Result:
  `/tmp/vail-refine-commerce-focused.xcresult`. This is a targeted corrected pass,
  not a successful full27-case rerun. Native paid UI also verified marks disappear
  after Pro activation and unlimited exports remain available after restart.
- Unsigned universal Simulator Release build: **passed**, with the existing
  resource guard **passed**. All four added photo fixtures, fixture analyzer,
  local StoreKit configuration, commerce launch overrides and StoreKitTest linkage
  are absent. `/tmp/vail-refine-release.log`; [guard evidence](release-guard.txt).
  This is not a signed device archive, upload or production acceptance.
- Five JPEGs audited at1320×2868, RGB, no alpha; raw native light/dark and gallery
  captures visually inspected. Existing signing/build settings preserved except
  the approved Debug fixture references and matching Release exclusions. Inventory
  validation and `git diff --check` pass.

A verified current Pro publication maps directly to clean presentation without
waiting for catalog/status loading. A brief checking cover can appear while a
newer verification is pending; the test no longer assumes every overlapping
refresh has settled when a particular Restore call returns. No privacy policy
relaxation, repeated polling or retry-until-green was introduced.

Evidence preserves revision scope. No arbitrary sleep, timeout inflation, skipped
release requirement, provider activation or retry-until-green. Existing testing
layers/plans are retained; inventory/matrix include the new cases.

## Remaining acceptance

Final refined asset approval by Maksym; the one-export migration decision; full
exact-candidate release Integration and physical device/VoiceOver/gesture/performance
acceptance. Native screenshot/StoreKit tests do not constitute actual production
purchase or signed device acceptance. Signing/team and all existing build settings
are preserved; only Debug fixture resources and matching Release exclusions added.
README's V4 owner/backend gate remains. Production version/build unchanged pending
completion of the whole1.1 release; no release merge is authorized by test results.
