> Final update2026-10-28: App Privacy published; app1.0(7), group and both subscriptions submitted and read back WAITING_FOR_REVIEW. MANUAL release retained; no public release. See [actual final submission](FINAL_SUBMISSION_STATUS.md). Earlier submission-authorization and App Privacy/contact blockers below are historical and resolved.

> Current release update — 2026-10-28: approved legal site is live and verified; Privacy/Support URLs are configured and read back in ASC and signed build1.0(7). Build7 is VALID and IN_BETA_TESTING in the existing internal group. See [build7 release report](LEGAL_RELEASE_BUILD7.md) for exact test outcomes, unsubmitted subscription draft and remaining owner gates. Historical missing-policy/build6 statements below no longer describe the current binary. No public App Review or release occurred.

> **Latest focused update — verified 2026-10-28:** build **1.0 (6)** is uploaded, processing **VALID**, and **IN_BETA_TESTING** in the existing internal acceptance group. Home animation/URL integration and dormant SDK-free contextual advertising preparation are implemented; live ads/public policy remain blocked on approved external setup. PR94, Commerce23 and focused UI checks passed. See [FINAL_IMPROVEMENTS_BUILD6.md](FINAL_IMPROVEMENTS_BUILD6.md); older checkpoints below are historical.

> **Final autonomous checkpoint — verified 2026-10-27:** corrected compatibility matrix **135/135 PASS**, plus **82 regular SwiftPM cases and two separately enabled host profiles PASS**. Signed build **1.0 (5)** uploaded and Apple processing **VALID**; TestFlight is **MISSING_EXPORT_COMPLIANCE**, not available for testing. Commercial App Review remains blocked by public legal URLs/final purchase-enabled build, owner declarations and physical/Sandbox acceptance. Earlier failures and checkpoint text below remain historical. See [the complete current handoff](AUTONOMOUS_RELEASE_HANDOFF.md).

<!-- autonomous-current-status -->
> **Current status — autonomous execution, 2026-10-26:** Current release verdict and per-gate statuses are in the handoff. Earlier pricing, unsigned-build and 22/23 summaries below describe previous checkpoints and are superseded, not erased. [AUTONOMOUS_RELEASE_HANDOFF.md](AUTONOMOUS_RELEASE_HANDOFF.md) is the authoritative current report.

---

# Current live ASC / annual reconciliation — 2026-10-26

**BLOCKED for TestFlight/AppReview.** [Current automated audit](ASC_AUTOMATION_2026-10-26.md) and [sanitized evidence](ASCPreparation/2026-10-26/README.md) supersede earlier catalog assumptions below. Canonical products are `vail.pro.monthly` / `vail.pro.annual` in Photo Privacy Pro; old cross-group yearly is untouched. Live app1.0 has no builds. Annual level1/group English draft localization were corrected; no prices/offers/availability changed. Poland monthly14.99 is above12.99 target; annual99.99 matches; no trials; annual availability missing.

Fresh annual revision: **nativeCommerce FAIL:22passed,1failed,0skips** (unchanged monthly paid-renewal expectation); all5UI and annual native purchase/restore/obsolete-SKU assertions passed. Cause unknown after preserved-log review; no unauthorized rerun/timeout change. **Unsigned arm64 iOS Release and test-isolation checks PASS**. App Debug/Release teams match the live certificate, but distribution signing/export, uploaded processed build, physical/Sandbox and owner legal/marketing approvals remain open. Historical135/135 matrix and previous full-run failures below describe prior revisions, not a fresh passing suite for this SKU change. No marketing/screenshot upload or review submission/publication occurred.

---

# Commercial 1.0 candidate — 2026-10-13

**BLOCKED — not yet ready for TestFlight or App Review.** The sections below “Historical preparation” retain earlier revisions and are not current acceptance evidence. Current verification is recorded in [FINAL_QA_REPORT.md](FINAL_QA_REPORT.md).

The owner-approved App Store title is **Blur, Watermark & Metadata**. Home Screen/in-app Veil branding and bundle `com.maksym1503.veil` remain intact. Marketing version is now **1.0**, local build **5** (provisional until existing App Store Connect uploads are checked). Signing team/identities are preserved. No upload, submission, purchase activation, provider registration or public deployment was performed.

## Candidate work

- Preserved the two-successful-export allowance, verified StoreKit access, monthly/yearly plans, Keep metadata default, rendering, watermark, originals and UI.
- Corrected the Apple test runner to use normal simulator signing for Keychain and the working iOS 26.1 runtime for StoreKit plans; retained newer-runtime PR coverage and explicit destination selection. See [ADR-008](../Engineering/Decisions/008-release-candidate-1-0.md).
- Aligned the local subscription group display name with **Photo Privacy Pro**. Local configuration remains test-only; production IDs are unchanged.
- Corrected paywall copy that advertised unavailable cloud sync; it now truthfully says no Veil account is required. No commerce or layout behavior changed.
- Prepared English listing, App Store Connect handoff, privacy/legal assessment and unpublished static legal pages with a publication validator that refuses unresolved owner information.
- Created real running-app 6.9-inch screenshots and reproducible native typography composition. Final asset validation and synthetic sample rights are tracked separately.
- Added a reproducible fictional-metadata test photo, screenshot journey and a real denied-Photos-save regression assertion. These changes affect tests, not production behavior.

Fresh completed local checks include SwiftPM, PR, native StoreKit, screenshot metadata auditing, backend-policy checks and Simulator Release validation; see [FINAL_QA_REPORT.md](FINAL_QA_REPORT.md) for exact revisions and artifacts. The approved split-runtime compatibility matrix passed **135/135 unique required cases**, with zero skips, failures or retries: 126 non-StoreKit cases on iOS 26.5 and eight native StoreKit plus one eligible-trial UI case on iOS 26.1. Exact inventories and source/build fingerprints were verified. This does not change the separate full serial Integration result: **125 passed, 10 failed** on iOS 26.1, all ten in native OCR UI. A standalone real-Vision reproduction outside Veil showed the same SIGBUS on iOS 26.1, while unchanged plate UI passed on iOS 26.5. This is a runtime-specific observed limitation; the compatibility matrix does not establish that the single-runtime 26.1 failures are globally fixed or convert that failed run into a pass.

## Files changed in this release-preparation pass

Existing dirty-tree feature work was preserved. The candidate-specific changes are: `PhotoVeil.xcodeproj/project.pbxproj` (1.0/build5 and Debug-only tagged fixture); `Configuration/VeilLocal.storekit` (group display name); `Sources/PhotoVeil/VeilSubscriptions.swift` (truthful account/cloud copy); `Tests/PhotoVeilUITests/PhotoVeilUITests.swift` and `VeilCommerceUITests.swift` (real screenshot journey and Photos-denial regression); the synthetic tagged fixture; `scripts/ci/run_apple.sh`, `check_release.py`, `local_release_matrix.py`, inventory/matrix tooling and CI documentation; ADR-008; the required App Store documents, local legal-site source, screenshot compositions and sanitized evidence. No production renderer, metadata, entitlement or export-counter behavior was changed by this pass.

## Required external gates

1. **NEEDS OWNER ACTION:** approved legal identity/contact, public HTTPS Privacy/Terms/Support pages and corresponding `VeilPublicLinks`. Nil links intentionally block production purchase; restoration and existing entitlements remain independent.
2. **NEEDS OWNER ACTION:** verify Paid Apps Agreement, tax/banking completion and DSA status; verify/create yearly product, both Polish prices, three-day introductory offers, group localization/equal service levels, availability and review association. Monthly record existence is owner-reported, not independently inspected.
3. **NOT VERIFIED:** physical-device native Apple Sandbox, restart/reinstall/cross-device purchases, VoiceOver, mobile 12–48 MP memory/color/performance. Local StoreKit transactions are not Apple Sandbox validation.
4. **BLOCKED:** App Store distribution export/upload acceptance and build-number uniqueness. A development-signed local archive passed; no distribution export/upload was attempted. No signing identities or provisioning were changed. The physical UI-test build exited 65 before test execution because test runners lack provisioning profiles. Provisioning updates were not authorized or attempted.
5. **NEEDS OWNER ACTION:** review subscription ongoing value under Apple guideline 3.1.2, legal/export-compliance/App Privacy/age-rating answers and marketing sample publishing rights.
6. **BLOCKED:** README's existing physical owner/configured-backend V4 acceptance gate remains. Backend is not configured in this local candidate; a local-only commercial scope cannot silently waive that gate.

[Exact owner handoff](APP_STORE_CONNECT_CHECKLIST.md), [listing](APP_STORE_METADATA.md), [privacy/legal assessment](PRIVACY_AND_LEGAL.md), [native subscription history](MONETIZATION_IMPLEMENTATION.md).

## Roles and decisions

Root acts as Engineering Lead and validation runner. Read-only CTO provided the architecture gate and independent source/document review. A bounded presentation developer wrote listing/legal material and was reused for read-only visual QA of root-created screenshots; it did not independently approve its own documents. No nested agents. No production runtime rewrite was warranted by the audit.

---

# Historical preparation — earlier revisions

# Veil App Store readiness — 2026-10-10

Status: preparation implemented; **not approved for App Store submission or V4 merge**. README's physical-owner/configured-backend gate remains intact. No production provider, billing product, paid service or distribution was activated. Existing local signing edits were preserved.

## Screenshot-led visual quality pass — 2026-10-11

The focused presentation pass refines the three-pillar hero, balances Metadata/Watermark within the retained panel, aligns comparison chrome with the fitted photo, makes Done a true export review, and compacts/centers gallery selection and deletion. Keep remains the new-session default; rendering, storage and privacy contracts are unchanged.

Native PR **77/77 passed**. All **10 distinct targeted Integration cases** passed across the documented corrected runs, with **2/2 additional light-appearance cases** passed. Independent before/after visual review accepted standard/largest-text, light/dark states. Full Integration111 and physical acceptance remain release gates. See [visual audit, comparisons, test scope and resolved failures](VISUAL_QUALITY_PASS.md); historical sections below describe prior revisions.

## Three-pillar privacy editor — 2026-10-11

Veil now presents **Redact, Metadata and Watermark** as distinct primary editing areas. Existing Background/Faces/Plates/Documents/Manual tools remain inside Redact. Home's animated portrait demonstrates concealment, metadata choice and a visible usage stamp; guide, About, Help, Privacy and listing/legal/support drafts use the same product language. Native pillar transitions preserve the photo transform and active edits. Selection remove/resize graphics now match their centered 44-point hit areas.

Watermark offers an explicit useful default, custom one-line text, purpose/date suggestions, Light/Dark/Stamp, direct image-space dragging, placement presets, repetition and focused size/opacity/rotation controls. Native accessibility controls and position actions supplement gestures. Watermark Undo is independent of visual redaction; global Reset/Undo includes both. Metadata Undo is disabled; its explicit Keep/Remove choice remains independent, with Keep the new-session default. Exact source metadata preservation after JPEG re-encoding remains unsupported as documented in [metadata limitations](METADATA_REMOVAL.md).

[ADR-006](../Engineering/Decisions/006-three-pillar-watermark.md) records the CTO-approved native Core Text/Core Image composition. The mark is applied after redactions in the existing single-materialization render graph, before metadata encoding. All destinations receive flattened pixels; gallery/cloud re-export cannot double-apply the mark. No new storage schema, external SDK, provider, dependency, tracking or billing activation. Invalid/failed active composition blocks export. Custom text and history are session-only; deliberate saved/shared output and thumbnails retain it visibly. Watermarked debug image evidence needs a separate synthetic-test opt-in. See [feature scope, limits and acceptance](WATERMARKS.md).

Roles: root Engineering Lead integrated UI/state/export/docs and validation; bounded Developer implemented native rendering/core regressions. The read-only CTO provided the architecture gate and independent review, resolving normalized full-resolution geometry and Metadata Undo findings. That thread's final review found no material issues. The implementation thread was reused explicitly for read-only QA/evidence; it is not described as independent code review. No nested agents or owner-gated operations.

Validation:

- SwiftPM: **72 passed**, two existing opt-in profiles skipped, zero failures; `/tmp/veil-watermark-swift-final.log`. Nine watermark core cases cover native pixels, composition order, geometry/rotation/repetition/clipping, Unicode/resource limits, cancellation, injected preview parity and flattened gallery re-export under both metadata choices.
- Native PR: **77/77 passed**, no skips/failures, exact required execution inventory verified; `/tmp/veil-watermark-pr-fixed.xcresult`. Five UI cases include direct positioning, scoped/global Undo, metadata defaults/choice, Save to Veil and fresh-session cleanup. Initial `/tmp/veil-watermark-pr.xcresult` retains two diagnosed failures: ambiguous Redact accessibility naming and Reset's stale debug fingerprint/cached completion state. Distinct “Redaction tools” naming and canonical Reset rerender fixed them before the corrected full gate. No test timeout/retry changes.
- Initial targeted Integration: **7/7 passed**; `/tmp/veil-watermark-integration.xcresult`. Screenshot review nevertheless caught largest-accessibility-size watermark labels/hint crowding the pillar bar. Text/style controls now stack at accessibility sizes, the redundant visual hint is omitted there (accessible movement actions remain), and the text sheet scrolls. The test now asserts stacking/viewport bounds and opens the text sheet. Final corrected Integration: **7/7 passed**, exact selected identifiers verified, no skips/failures; `/tmp/veil-watermark-integration-ax-fixed.xcresult`. Recaptured screenshots were independently reviewed: controls fit above the pillar bar, and the text editor scrolls without blocking actions. Real-system tests cover custom text, Stamp/repetition/placement/adjustment, gallery save/reopen/Photos/Share, manual gestures/export and home/guide/help at normal/largest text sizes. The PR gate above preceded this isolated presentation correction; rendering/state did not change.
- Synthetic **4032×3024** native macOS render probe: single watermark cold 0.403s / warm 0.110–0.119s; repeated 0.115–0.176s; repeated + solid redaction 0.136s warm / 0.387s first run. Maximum resident process size 265,809,920 bytes (~254 MiB), including source/output/CI/framework allocations. Default glyph raster 1567×257. `/tmp/veil-watermark-perf.log`, optimized standalone probe built from the current native renderer. This is a desktop synthetic baseline, not an iPhone latency/peak-memory or 48 MP acceptance result.
- Final unsigned universal Simulator **Release passed** (arm64/x86_64); fixture-exclusion check passed. `/tmp/veil-watermark-release-final.log`, `/tmp/veil-watermark-release-check-final.log`. No signed/device archive or distribution.
- Repository validation confirms **119 Swift test methods**, retaining the 85-case baseline. No test-layer/provider changes, arbitrary timeout increases or unchanged retry-until-green.

Source fingerprints and validation scope: [watermark evidence](Evidence/watermark-validation.json). Local `/tmp` bundles/logs are execution artifacts, not distributable builds.

Full **111-case Integration**, opt-in profiles, physical 12–48 MP memory/color/VoiceOver, signed archive, configured cloud acceptance and the existing legal/provider/commerce/V4 owner gates remain release-candidate requirements. No App Store submission or V4 merge approval is implied.

## Focused UI polish — 2026-10-11

New editor sessions visibly start with **Keep metadata**, as requested by the owner. Final-review supporting copy is shorter and duplicate status text is removed; both choices and the originals reminder remain. Saved copies, legacy policy defaults, encoding and export paths are unchanged. Single/multi deletion confirmations use reduced spacing and 220-point local / 240-point synced detents (previously 280), retaining destructive/cancel actions, 44-point targets, scroll access and the larger accessibility presentation. Gallery counts/selection status use plain text without the iOS 26 shared glass background; earlier iOS versions retain their native toolbar treatment.

Root implemented and performed QA; the independent read-only CTO thread was reused as reviewer under the STANDARD workflow and found no actionable issues. Prior optional-choice validation below refers to that earlier revision.

Validation: five distinct targeted native UI cases verified on dark iPhone 13 mini / iOS 26.5: PR local save/reopen/Keep persistence (1/1), Integration largest-text gallery selection/deletion, single-photo cancel/delete, and explicit Remove → gallery → Photos/share (3 passed in the initial 4-case run), then corrected largest-text metadata selection/non-overlap (1/1). Initial failure was a deterministic test selector collision between the now-selected Keep menu label and its menu option; the test now chooses Remove then Keep and asserts both explanations. No app workaround, timeout change or retry of unchanged code. Evidence: `/tmp/veil-ui-polish-pr.xcresult`, `/tmp/veil-ui-polish-integration.xcresult` (retains the failure), `/tmp/veil-ui-polish-largest-fixed.xcresult`. Screenshots of normal/selected counts, compact confirmation and largest-text metadata reviewed. Unsigned universal Simulator Release and fixture-exclusion check passed (`/tmp/veil-ui-polish-release.log`, `/tmp/veil-ui-polish-release-check.log`). Inventory remains 107; repository validator and `git diff --check` passed. Full core/Integration suite and physical VoiceOver acceptance were not repeated for this polish; existing release gates remain. No new owner decision or service activation.


## Optional metadata choice — 2026-10-10

After Done, the final review now offers native **Remove metadata / Keep metadata**. Keep is visibly selected for each new photo (owner-requested polish, 2026-10-11); the choice survives returning to editing within the session and is snapshotted with export. A supported source metadata snapshot is captured before normalization, held only in memory and cleared with the session. Save to Photos, Share, persisted gallery exports/thumbnails and future cloud upload/download honor the choice. Originals stay unchanged. See [feature scope and limitations](METADATA_REMOVAL.md) and CTO-reviewed [ADR-005](../Engineering/Decisions/005-optional-photo-metadata.md).

Keep preserves supported native photo fields, not exact source-file bytes. Original embedded previews, opaque MakerNotes/application data, unsupported source tags/JPEG comments and auxiliary images are excluded. Orientation/dimensions/color are regenerated for the edited JPEG; previously removed metadata cannot be recovered. Empty supported metadata is explained. Remove still fails closed; failed Keep serialization never silently falls back to Remove. Gallery entries with absent legacy policy use Remove. Prior stored/delivered copies are not rewritten.

The additive cloud policy migration is prepared locally and tested in a disposable database; it is **not deployed**. Configured sync requires that migration and compatible clients before activation. Home/guide/final-review/gallery, About/Privacy/Help and legal/store/support/architecture/physical-check documents describe the optional behavior. The historical always-on evidence below is not proof for this revision.

### Optional-choice validation

- SwiftPM: **63 passed**, zero failures; two existing opt-in profiles skipped. `/tmp/veil-optional-metadata-swift-verified.log`. Fifteen readiness cases include nine metadata/choice regressions; originals, both policies, all eight orientations, supported EXIF comments/serials and descriptive tags, previews, failures, gallery/cloud/destination contracts are exercised.
- Native PR: **67/67 passed**, no skips/failures, required execution inventory verified. `/tmp/veil-optional-metadata-pr-verified/Tests.xcresult`. Native UI toggles both choices, saves Keep and checks reopened gallery status. This run preceded the isolated expanded-text layout correction; core and normal-size behavior did not change afterward.
- Final dark compact Integration: **6/6 passed**, exact selected identifiers checked, no skips/failures. `/tmp/veil-optional-metadata-compact-fixed.xcresult`. Updated Help/Privacy, largest-text menu selection and non-overlap assertion, gallery/Photos/Share, manual gestures/export and landing/guide. Final screenshots reviewed: no metadata control/explanation overlap; long accessibility copy scrolls inside the retained control area without changing the canvas transform.
- Final unsigned universal Simulator Release: **passed**, arm64/x86_64; `check_release.py` found no debug fixture analyzer/photos. `/tmp/veil-optional-metadata-release-fixed.log`. No signed/device archive.
- Disposable PostgreSQL ownership/Vault checks and additive migration passed, including Remove default, Keep update, unknown and NULL rejection. `/tmp/veil-optional-metadata-sql.log`. Five CI contract tests passed. Inventory **107 Swift methods**, baseline85 preserved, plist/entitlements/project lint and `git diff --check` passed. No timeout inflation, quarantine, provider activation or test-layer redesign.

[Optional-choice revision fingerprint/results](Evidence/optional-metadata-validation.json), [Help](Evidence/optional-metadata-help-dark-compact.png), [guide](Evidence/optional-metadata-guide-dark-compact.png). Prior evidence remains historical. First native build was deliberately interrupted before tests to resolve a CTO review finding (missing Keep snapshot); logs retained under `/tmp/veil-optional-metadata-pr`. The first compact6/Release passed but visual review caught the largest-text native Picker label overlapping the explanation. A native Menu with a measured wrapping label fixed it; the final compact6/Release validate that change. The historical UIKitToolbar hosting warning remains in compact gallery logs, with no behavior failure and physical acceptance still required.

Roles: root Lead integrated UI/docs and fixes; bounded Developer implemented the metadata/persistence/cloud core and regressions. Read-only CTO supplied the architecture gate and independent final review; its findings (missing snapshot fallback, structural-only availability and vacuous legacy-row assertion) are resolved. The Developer thread was reused for disclosed read-only QA/evidence and visual checks; independence is supplied by CTO review.

Remaining release checks: full **100-case Integration** on the candidate, opt-in profiles, physical Photos Info/12–48MP memory/color/VoiceOver, configured compatible-client cloud acceptance after approved migration, and signed archive. Reconcile App Privacy declarations with optional Keep uploads, including retained GPS/camera/descriptive fields. Existing V4 owner/legal/provider/commerce gates remain; no credentials, signing, billing, service or distribution activation.

## Historical mandatory metadata-removal feature — superseded by optional choice

At that historical revision, source metadata removal was always on for new editor saves/shares, new gallery imports/downloads, outgoing legacy gallery copies and future cloud uploads. A typed native pixel-only encoder prevents accidental raw-source export, normalizes orientations, standardizes color and discards source metadata/previews. Originals, old history and previously delivered/cloud copies remain untouched; operational gallery/cloud dates and IDs remain. No schema/provider/dependency, paid feature gate or release activation.

Home, quick guide, final review, gallery export guidance, About, Help, privacy/support/terms/listing drafts, architecture/security and physical acceptance were updated together. [ADR-004](../Engineering/Decisions/004-source-metadata-removal.md) records the CTO-reviewed decision. Five deterministic metadata regressions join the existing test layer: inventory103, PR63 (59core+4UI), full Integration96. Earlier product-quality counts and fingerprints below refer to the preceding source; they do not validate this feature. Historical mandatory-removal evidence is retained in `Evidence/metadata-validation.json`; it does not validate the current optional choice.

### Metadata validation and acceptance

- SwiftPM: **59 passed**, zero failures; two documented opt-in performance profiles skipped. `/tmp/veil-metadata-swift-final.log`.
- Corrected native PR: **63/63 passed**, zero skips/failures, all required identifiers verified. `/tmp/veil-metadata-pr-fixed.xcresult` and `.log`.
- Targeted dark compact Integration, iPhone 13 mini / iOS26.5: **6/6 passed**, exact selected identifiers verified, no skips/failures. First use/About/Privacy/metadata Help, largest-text tools/home/guide, manual gestures/export, editor add-only Photos, and gallery save/relaunch/Photos/Share/delete. `/tmp/veil-metadata-compact.xcresult` and `.log`.
- Unsigned universal Simulator Release: **passed** for arm64/x86_64; fixture-exclusion check passed. `/tmp/veil-metadata-release.log`. No signed device archive or distribution.
- Inventory **103 Swift methods**, baseline85 retained, config/plist lint and `git diff --check` passed. Source fingerprint and scope: [metadata evidence](Evidence/metadata-validation.json). Safe UI captures: [home](Evidence/metadata-home-dark-compact.png), [guide](Evidence/metadata-guide-dark-compact.png), [metadata Help](Evidence/metadata-help-dark-compact.png).
- Initial native PR: **62 passed / 1 failed** at the unchanged180sec limit. The final-review container's accessibility ID replaced the visible metadata label's ID. Explicit containment/leaf accessible label fixed propagation; the corrected complete PR passed. Preserve `/tmp/veil-metadata-pr.xcresult`, `.log` and `-pr-failure-summary.json`. An initial build was deliberately interrupted after the validator caught duplicate core-test source membership; final membership follows the existing SwiftPM/native architecture.
- Early core test development exposed expected re-encoded-byte differences, generated structural EXIF, optional CFString compile handling, and a misleading ImageIO thumbnail probe. The final tests retain positive tagged/preview fixtures and inspect bounded JPEG structure instead of accepting a green but vacuous removal assertion. Intermediate `/tmp/veil-metadata-swift*.log` and native inspection are retained.

Root implemented the core/export/gallery integration and tests; CTO reviewed architecture and independently reviewed final code/AX fixes with no remaining findings. The bounded developer updated presentation/legal/store copy; the same thread performed disclosed QA/static/native-evidence review. No nested agents or activated service. Full **96-case** Integration, physical Photos Info, wide-gamut/12–48MP peak-memory/appearance, opt-in profiles and signed archive remain release-candidate checks. The canonical sRGB raster can add roughly192MB at48MP; this is a size estimate, not a measured peak. Existing legal/provider/commerce and V4 owner gates remain.

## Product-quality follow-up — 2026-10-10

End-to-end audit covered entry/onboarding, every editor category and final review, gallery, account/settings/information, native launch, core/store/session boundaries, tests, backend authorization/deletion, configuration and the release checklist. Competitor screenshots were not present in this session; no competitor design was copied.

| Priority / area | Finding and implemented outcome | Remaining acceptance |
|---|---|---|
| P1 consent/privacy | Failed sync-off persistence previously left runtime uploads enabled. Sync now stops before awaits; per-user in-memory suppression survives refresh, stale writes cannot enable another identity, dependent deletion aborts on failure. Error explains retry before closing because old persisted opt-in may survive a restart. | Real configured account/offline/file-lock/device consent acceptance |
| P2 identity lifecycle | Startup restore could overwrite newer sign-in/out. AccountSession generation guards reject obsolete success/error; credential/name results check identity. | Live provider callbacks, revocation and account deletion |
| P2 imports/exports | Cancelled/obsolete import results and stale export completions could affect a later photo. Added import generation/cancellation, single-flight export snapshots and session-checked completion. Accepted Photos/gallery writes can finish after closing; no false cancellation promise. | Physical picker/iCloud/large-photo and system Photos/Share |
| P2 persistence/failures | Save could race startup; failed opening looked empty; invalid JPEG could spin indefinitely; deletion failure left stale index visible. Saves await coalesced opening/retry, gallery distinguishes unavailable/empty, image decode terminates with retry, deletion reloads committed metadata and reports outcome. | Locked/full/corrupt filesystem and interrupted-save device acceptance |
| Home/first use | Decorative privacy demo lacked direct interaction and visual guidance. Tap takes control of blur with a soft outline glow and accessible action. Optional native guide communicates choose/cover/review without a persistent onboarding wall or new consent flag. | VoiceOver and motion preference physical acceptance |
| Editor | Ambiguous spinner and modal save alert. Detection/preview/export have distinct text, mode/effect changes provide native haptics, tool icons respond to state, selection has blue depth, original comparison is explicit, final review has safety guidance. Save confirmation is nonblocking, explicitly grouped for accessibility and cleared on return to editing. | Haptic feel and performance on hardware; renderer/canvas architecture unchanged |
| Gallery/account | Refined empty state, animated selection and haptics, duplicate detail actions blocked, honest failure/retry. Local-only account is an editorial composition with clear retention information; native provider controls retained when configured. | Multi-device/provider features remain inactive until configured/accepted |
| About/Privacy/Help | Long boxed rows became editorial scroll pages with readable spacing and brand headers. Help has native expandable questions; essential sharing/redaction warning stays visible. | Real public legal/support destinations and reviewed operator details |
| Startup/brand | Existing native launch mark/new icon reviewed and retained. Previous-session cleanup now runs concurrently with local opening; first content does not await either or optional account restoration. No fake launch delay. | Instruments physical cold/warm startup, older supported iOS, 12/48MP memory profiles |
| Monetization/compliance | Two successful free exports, Keychain usage, verified native monthly/yearly Pro and local StoreKit testing implemented. See [current evidence/gates](MONETIZATION_IMPLEMENTATION.md); historical preparation evidence below remains dated. | App Store Connect setup, real legal links, sandbox/device acceptance and final archive privacy report |

[ADR-003](../Engineering/Decisions/003-product-quality-lifecycle.md) records the approved local lifecycle decisions. Existing actors, format/schema, geometry, renderer, providers and test layers remain. No new service, tracking, ads, credentials, production configuration or distribution activation.

Current validation is recorded separately in `Evidence/product-quality-validation.json`; the 2026-10-09 results/screens below are historical preparation evidence, not a claim to validate this follow-up. Local quality-run logs use `/tmp/veil-quality-*`.

## Prior preparation audit and implementation — 2026-10-09

| Area | Finding | Result / acceptance boundary |
|---|---|---|
| About | Sparse feature description; prominent Version / Build row | Explains the privacy editor, tools, on-device processing, unchanged original and optional account; compact version footer retained for support |
| Account | Apple native token exchange, Google PKCE, Keychain, opt-in cloud and deletion already exist | Preserve architecture. Honest local-only screen; provider controls paired behind Apple capability; disabled DEBUG controls preview preserved. Real provider configuration/testing is still required |
| Monetization | No billing/usage layer; monthly price and one-photo limit tentative | Separate native StoreKit 2 preparation, allowlisted verified entitlements, transaction updates, localized monthly product, restore/manage, pending/cancel/error handling. No product/configuration bundled or quota enforced; DEBUG preview is non-purchasable |
| Privacy/legal | Policy/contact URLs absent; support draft falsely said no account/server gallery; terms said no purchase implementation | Corrected drafts and in-app text; distinguish local processing, optional cloud, source/OCR exclusion, backup/deletion limitations and independent Apple billing. No invented legal facts or published links |
| Home | Plain headline, simple floating face, redundant local-processing badge | Stable two-tone headline and cyan/blue/indigo accent, layered illustrated portrait, blur/reveal and selection outline, clear primary action, import progress and less copy; no cards or stock/personal photo |
| Icon | Fine gradients/glow and generous margins weakened small-size silhouette | Larger photographic frame and flowing folded veil, preserved charcoal/cyan/indigo identity, opaque 1024px asset and reproducible native drawing source |
| Launch | Empty native launch definition; synchronous file cleanup in App.init | Native adaptive-background launch mark; session-safe cleanup moved off main; local preparation signpost; no fake delay/splash or network requirement for editor |
| Gallery | Empty state could appear while library opening; repetitive device-storage copy | Explicit loading state, clearer empty-state instructions and quiet count/sync footer; existing save/delete/reopen contracts retained |
| Editor | V4 composition, detection, undo, gestures and export already implemented | Rendering/detection architecture untouched; all original tests retained. Detection remains fallible; help recommends reviewing/solid redaction for sensitive text |

## Decisions

[ADR-002](../Engineering/Decisions/002-app-store-readiness.md) accepts reversible preparation only. [Commerce setup](COMMERCE_SETUP.md) defines the future owner decisions and activation matrix. The pure allowance policy has no persistence or editor call sites. Editing, exports and gallery stay unrestricted in this build. A paid release requires approved usage rules, durable failure-safe accounting, ongoing value and sandbox tests before configuration is activated.

Visual decision: keep the headline and gradient accent stationary after simulator inspection reproduced glyph/placement drift with decorative animations. The refined portrait retains native blur/reveal motion and Reduce Motion behavior. This favors stable typography while preserving the requested living hero.

No new dependency, backend schema, identity system, analytics, photo fingerprinting or CI provider was introduced. The preparation added three deterministic readiness tests to the existing SwiftPM/native core layer, PR plan and inventory; this follow-up adds three consent/session regressions (six readiness tests total). Test architecture/timeouts are unchanged. Integration text expectations were updated to match intentional copy changes, with behavior checks retained.

## Apple requirements verified from official sources

Apple review, subscription, privacy and upload requirements rechecked against official sources on 2026-10-10. The Google artwork and launch references were checked in the prior preparation. Recheck changing requirements for the actual submission.

- [Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) cover complete functional submissions, accurate metadata, support contact, digital-feature purchases, equivalent login, accessible privacy policy and deletion.
- [Subscriptions](https://developer.apple.com/app-store/subscriptions/) describes monthly offer presentation: benefits, duration, full localized renewal price, restoration, Privacy Policy and Terms links.
- [Account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/) explains in-app deletion, Apple-token revocation and continued subscription billing until separately cancelled.
- [Privacy details](https://developer.apple.com/app-store/app-privacy-details/) distinguishes local-only processing from collection and requires accurate disclosures for optional cloud/account features and partners.
- [StoreKit current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements), [updates](https://developer.apple.com/documentation/storekit/transaction/updates) and [restore](https://developer.apple.com/documentation/storekit/appstore/sync()) underpin the native adapter.
- [Current submission requirements](https://developer.apple.com/news/upcoming-requirements/) include upload SDK/toolchain minimums, iOS deployment minimum, updated age-rating questionnaire and EU trader-status requirements. Local Xcode 26.6/iOS SDK 26.5 and iOS 17 deployment meet current build minimums; owner metadata and archive validation remain required.
- [Google sign-in branding](https://developers.google.com/identity/branding-guidelines) permits the official downloaded artwork used here; sources/restrictions are recorded in `Design/ThirdPartyAssets.md`. No Google SDK or provider registration was added.
- [Launching HIG](https://developer.apple.com/design/human-interface-guidelines/launching) informs immediate native content rather than artificial launch delays.

## Product-quality validation — 2026-10-10

- SwiftPM: **54 passed**, zero failures; two documented opt-in macOS performance profiles skipped. `/tmp/veil-quality-swift-final.log`.
- Corrected native PR: **58/58 passed**, zero skips/failures, all required identifiers verified. `/tmp/veil-quality-pr-verified.xcresult` and `.log`.
- Full native Integration, iPhone 17 Pro / iOS 26.5 light: **91/91 passed**, zero skips/failures/expected failures. Execution inventory verified all 54 core, 2 real-Vision and 35 existing UI cases. `/tmp/veil-quality-full.xcresult` and `.log`.
- Targeted compact dark Integration, iPhone 13 mini / iOS 26.5: **13/13 passed**, zero skips/failures. Covers first use, information/account/provider preview, direct portrait interaction, largest text, toolbar geometry, composed/scoped undo, manual gestures/export, local persistence and rendered-control/gallery stress. `/tmp/veil-quality-compact.xcresult` and `.log`.
- Unsigned universal Simulator Release build: **passed** for arm64/x86_64; `check_release.py` confirmed no fixture analyzer or bundled debug photo fixtures. `/tmp/veil-quality-release.log`. This is not a signed device archive.
- Local backend: ownership and Vault token privilege/cleanup policy checks passed in isolated PostgreSQL, with rolled-back test data; deletion-handler **5/5** and CI infrastructure **5/5** passed. `/tmp/veil-quality-policies.log`, `-deno.log`, `-ci.log`.
- Inventory **98 Swift methods**, all original baseline cases preserved; plist/project/privacy/entitlements lint, opaque icon and `git diff --check` pass. No timeout increase, skip/quarantine, provider activation or test-layer redesign.
- Independent critical review: consent/deletion/identity publication and landing-test race findings resolved; no open production findings. QA independently checked native counts/inventory and visually inspected the six retained compact screenshots; QA reused the presentation developer thread, with independence supplied by the non-implementing CTO reviewer.
- First PR attempt: **57 passed / 1 failed**, unchanged 180-second case limit. A SwiftUI parent accessibility identifier propagated onto banner children, preventing discovery of the dismiss button. Explicit accessible containment plus the stable child button fixed it; the corrected full PR passed. `/tmp/veil-quality-pr.xcresult`, `.log` and `-pr-failure-summary.json` are retained. This was a UI accessibility/locator defect, not a timing adjustment.

[Machine-readable results and final source fingerprint](Evidence/product-quality-validation.json), [home](Evidence/quality-home-dark-compact.png), [guide](Evidence/quality-guide-dark-compact.png), [largest-text guide](Evidence/quality-guide-largest-text.png), [account](Evidence/quality-account-dark-compact.png), [About](Evidence/quality-about-dark-compact.png), [Help](Evidence/quality-help-dark-compact.png). Retained screenshots contain only code-native artwork/UI; scroll pages show a viewport. Earlier PR/compact checks preceded the final valid-symbol and singular-footer corrections; full Integration and the final Release build validate final source. Physical startup speed is not inferred from simulator test duration.

## Historical preparation validation — 2026-10-09

- SwiftPM: **51 passed**, zero failures; two existing opt-in performance methods skipped. `/tmp/veil-readiness-swift-test.log`; hardened parser follow-up **3/3 passed** in `/tmp/veil-readiness-policy-final.log`.
- Native PR plan, iPhone 17 Pro/iOS 26.5: **55/55 passed**, zero skips. `/tmp/veil-readiness-pr-final.xcresult` and `.log`. `verify_execution.py` confirmed all 55 required identifiers with no missing/skipped/expected failures.
- Targeted Integration UI on iPhone 13 mini/iOS 26.5 (dark appearance): **6/6 passed**, zero skips. `/tmp/veil-readiness-compact.xcresult` and `.log`. Covers About/Settings/privacy, unconfigured account, disabled provider preview with official Google artwork, portrait animation, largest-text home and largest-text gallery selection.
- After simplifying the decorative accent, home animation/largest-text checks: **2/2 passed** on the compact device. `/tmp/veil-readiness-home-final.xcresult` and `.log`. Final images inspected; headline/accent placement is stable. Portrait motion remains.
- Unsigned Simulator Release build: **passed**, `/tmp/veil-readiness-release-final.log`. `scripts/ci/check_release.py` passed against the final Release app: no fixture analyzer or bundled debug photo fixtures. This is not a signed/device archive.
- Inventory **95 Swift cases**, project/plist/storyboard/asset validation and `git diff --check` passed. No original test or testing layer was removed; no wait/timeout increased.
- Independent review found two P2 issues in prepared commerce (stale overlapping refresh publication; DEBUG preview becoming purchasable). Both were fixed and rechecked; no remaining findings. QA verified code/static checks and native summaries, using the disclosed reused developer thread.
- The first PR execution was interrupted after reaching a stale empty-gallery text expectation. Its log/result are retained as `/tmp/veil-readiness-pr.log` and `.xcresult`; classification: test-copy mismatch. Updating the expected text fixed it, without changed timing or behavior assertions. Xcode also emitted a teardown diagnostic during interruption; it is not evidence of a product crash.
- Compact gallery produced a SwiftUI/UIKit toolbar hierarchy runtime warning while its behavior/assertions passed. Retain `/tmp/veil-readiness-compact-attachments/6933FC3D-9DD9-4E3A-85EE-EF7AACC4B387.txt`; app code does not insert a `UIKitToolbar` directly. Physical layout/system-UI acceptance remains required; no private-framework workaround was added.

[Machine-readable summary and source fingerprint](Evidence/validation.json), [light home](Evidence/home-light.png), [dark compact home](Evidence/home-dark-compact.png), [largest-text compact home](Evidence/home-largest-text-compact.png), [About](Evidence/about-compact.png), [disabled provider preview](Evidence/account-preview-compact.png). Only code-native illustration/UI appears in retained screenshots.

The PR and 91-case Integration results in this historical product-quality section validate only that earlier source revision; they do not establish acceptance for the current candidate. Current full Integration and split-runtime matrix results are stated at the top of this report and in [FINAL_QA_REPORT.md](FINAL_QA_REPORT.md). Opt-in profiles, actual StoreKit purchases, live provider/backend behavior, physical cold-launch/VoiceOver acceptance and distribution signing remain release-candidate gates. No Simulator timings are represented as physical startup measurements.

## Owner actions before release

1. The owner approved two successful free exports and the monthly/yearly targets on 2026-10-12; quota accounting is implemented. Complete the App Store Connect configuration and native StoreKit/sandbox acceptance in MONETIZATION_IMPLEMENTATION.md before commerce activation.
2. Supply reviewed legal owner/privacy contact, working public Privacy Policy, Terms and support/contact page; confirm jurisdiction/rights, processors/region, transfer/backup/tombstone retention, request and support-message handling. Populate `VeilPublicLinks` only with those destinations. In-app privacy explanations are not a substitute for a policy.
3. If account/cloud features ship, authorize and complete Apple/Google/Supabase setup and deployed two-user isolation, consent/offline/deletion/token-revocation acceptance. No credentials belong in evidence. Do not ship unfinished provider marketing or controls.
4. Complete physical-device V4 acceptance, VoiceOver/Reduce Motion/Transparency, small/largest text, older supported iOS, 12/48MP memory and processing, actual Photos/Share and app-switcher privacy. Measure cold/warm launch with Instruments App Launch and the `Local preparation` signpost, without debugger; separate OS launch, cleanup/gallery and optional account/network restoration. Record device/OS/configuration and real numbers before claiming speed improvement.
5. The preceding product-quality source passed full Integration91. The metadata work now adds nine core cases (full Integration100); run the full plan, opt-in performance profiles and signed-device archive/privacy checks on the final release candidate. Include metadata/wide-gamut/large-photo acceptance from METADATA_REMOVAL.md. Review archive privacy report/SDK declarations and actual App Privacy answers (including purchase-history handling if activated), public metadata, screenshots, age rating, territories and commercial agreements.
6. Owner approves signing/archive/upload/distribution and V4 merge only after the existing gates pass. No green test grants release authorization.

## Roles actually used

Root acted as Engineering Lead/implementer. Read-only CTO `gpt-6-astra` reviewed architecture, then the same non-implementing thread performed independent critical review under the workflow's two-child limit. Developer `gpt-6-luna` implemented bounded presentation/gallery UI in this follow-up (home/information UI in the prior preparation); that thread was reused for QA static/evidence verification. QA was not independent of its own presentation implementation; the CTO/reviewer was independent of all implementation. No nested agents.


## Freemium update — 2026-10-12

[MONETIZATION_IMPLEMENTATION.md](MONETIZATION_IMPLEMENTATION.md) is the current authority for commercial architecture and validation. Two successful free operations and native monthly/yearly Pro replace the earlier inactive monthly-only proposal. Rendering, metadata Keep default, watermark behavior, home animation and cloud consent are preserved. Production payment activation and distribution have not occurred. Public legal links, App Store Connect and physical/sandbox/device release gates remain.
