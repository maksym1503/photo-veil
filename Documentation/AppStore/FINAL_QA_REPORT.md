> Current release update — 2026-10-28: approved legal site is live and verified; Privacy/Support URLs are configured and read back in ASC and signed build1.0(7). Build7 is VALID and IN_BETA_TESTING in the existing internal group. See [build7 release report](LEGAL_RELEASE_BUILD7.md) for exact test outcomes, unsubmitted subscription draft and remaining owner gates. Historical missing-policy/build6 statements below no longer describe the current binary. No public App Review or release occurred.

> **Latest focused update — verified 2026-10-28:** build **1.0 (6)** is uploaded, processing **VALID**, and **IN_BETA_TESTING** in the existing internal acceptance group. Home animation/URL integration and dormant SDK-free contextual advertising preparation are implemented; live ads/public policy remain blocked on approved external setup. PR94, Commerce23 and focused UI checks passed. See [FINAL_IMPROVEMENTS_BUILD6.md](FINAL_IMPROVEMENTS_BUILD6.md); older checkpoints below are historical.

> **Final autonomous checkpoint — verified 2026-10-27:** corrected compatibility matrix **135/135 PASS**, plus **82 regular SwiftPM cases and two separately enabled host profiles PASS**. Signed build **1.0 (5)** uploaded and Apple processing **VALID**; TestFlight is **MISSING_EXPORT_COMPLIANCE**, not available for testing. Commercial App Review remains blocked by public legal URLs/final purchase-enabled build, owner declarations and physical/Sandbox acceptance. Earlier failures and checkpoint text below remain historical. See [the complete current handoff](AUTONOMOUS_RELEASE_HANDOFF.md).

<!-- autonomous-current-status -->
> **Current status — autonomous execution, 2026-10-26:** Fresh autonomous QA, artifacts, native StoreKit renewal correction and current failures/unverified scope are recorded in the handoff. Earlier run results below remain historical; they are not rewritten as successes. [AUTONOMOUS_RELEASE_HANDOFF.md](AUTONOMOUS_RELEASE_HANDOFF.md) is the authoritative current report.

---

# Current live ASC / annual reconciliation — 2026-10-26

**BLOCKED for TestFlight/AppReview.** [Current automated audit](ASC_AUTOMATION_2026-10-26.md) and [sanitized evidence](ASCPreparation/2026-10-26/README.md) supersede earlier catalog assumptions below. Canonical products are `vail.pro.monthly` / `vail.pro.annual` in Photo Privacy Pro; old cross-group yearly is untouched. Live app1.0 has no builds. Annual level1/group English draft localization were corrected; no prices/offers/availability changed. Poland monthly14.99 is above12.99 target; annual99.99 matches; no trials; annual availability missing.

Fresh annual revision: **nativeCommerce FAIL:22passed,1failed,0skips** (unchanged monthly paid-renewal expectation); all5UI and annual native purchase/restore/obsolete-SKU assertions passed. Cause unknown after preserved-log review; no unauthorized rerun/timeout change. **Unsigned arm64 iOS Release and test-isolation checks PASS**. App Debug/Release teams match the live certificate, but distribution signing/export, uploaded processed build, physical/Sandbox and owner legal/marketing approvals remain open. Historical135/135 matrix and previous full-run failures below describe prior revisions, not a fresh passing suite for this SKU change. No marketing/screenshot upload or review submission/publication occurred.

---

# Final QA — commercial 1.0 candidate

Evidence date: **2026-10-13**. This is the current candidate record; prior documents retain historical runs. Status vocabulary: PASS verified; FAIL executed and failed; BLOCKED dependency prevents completion; NEEDS OWNER ACTION external/manual decision; NOT VERIFIED insufficient evidence. No test result below implies upload or App Review approval.

## Inspection scope

Working tree, README/V4 acceptance gate, architecture/security/CI strategy, Xcode targets/schemes/plans/resources/signing settings, SwiftPM dependencies, export admission/completion, Keychain allowance, native StoreKit verification/status, local gallery/temp lifecycle, image/redaction/watermark composition, optional source metadata, permissions, public links, privacy manifests, legal/listing drafts and existing screenshot evidence. Existing uncommitted implementation/signing changes were preserved.

## Executed checks

| Check | Status | Evidence / scope |
| --- | --- | --- |
| SwiftPM baseline | PASS | 84 executed: 82 passed, 2 existing opt-in profiles skipped; `/tmp/veil-rc-baseline-swift.log` |
| Opt-in native desktop profiles | PASS | Both skipped cases then executed explicitly: 2 passed, 11.632s; `/tmp/veil-rc-performance.log`. Desktop synthetic performance does not establish iPhone memory/latency. |
| Disposable PostgreSQL ownership/Vault policies | PASS | `/tmp/veil-rc-backend-policies.log`; no production backend connection/migration |
| Deno edge-function unit tests | PASS | 5 passed; `/tmp/veil-rc-deno.log` |
| Python CI contract tests | PASS | 5 passed; `/tmp/veil-rc-ci-contracts-final.log` |
| Inventory/static validation | PASS | 143 source methods after screenshot journey; matrix includes 43 Integration UI methods; `/tmp/veil-rc-static-final.log` |
| Legal-site source / listing limits | PASS | Four static pages, no scripts/external assets; title26, subtitle23, promo164, description3194, keywords91 UTF-8 bytes |
| Final real screenshot journey and saved-file audit | PASS | 1 actual UI test, `/tmp/veil-rc-capture-metadata.xcresult`; six 1320×2868 native PNGs. Fictional GPS/date/camera/comment fields were verified in Keep and absent in Remove; both outputs 1122×1402. Audit: `Evidence/Release-1.0/exports/metadata-audit.json`. Publishing rights for the synthetic sample remain NOT VERIFIED. |
| First full Integration (parallel) | FAIL | 135 executed:133passed,2failed,0skipped. Grace missed both expectations; concurrent refresh stalled. All43UI passed. `/tmp/veil-rc-integration/Tests.xcresult` |
| Serial native Commerce comparison | PASS |23/23passed,0failures/skips; exact inventory verified. Dark iPhone13mini/iOS26.1. Grace5.115s and concurrent refresh1.395s with unchanged native assertions/timeouts. `/tmp/veil-rc-commerce-serial/Tests.xcresult` |
| Native Photos-denied UI branch | PASS | Current serial Commerce case passed65.914s: real system denial, useful error, cancelled shares, two subsequent free saves and third-export paywall. Included in the completed23-case Commerce pass. |
| Clean Simulator Release | PASS |Actual PhotoVeil project1.0(5), arm64+x86_64. `/tmp/veil-rc-release.log`; hardened `check_release.py` passed: no debug fixtures/overrides, `.storekit` or StoreKitTest linkage. Archive/distribution acceptance separate. |
| Physical VeilDevice attempt | BLOCKED |Build exited 65 before test execution because test runners lack provisioning profiles. No provisioning updates were authorized or attempted; no signing/provider changes. `/tmp/veil-rc-device-team.xcresult`; both signing attempts are summarized in `Evidence/Release-1.0/physical-attempt.json`, with private logs retained locally. |
| Device Release archive | PASS |Local arm64 archive1.0(5), existing development identity/profile, deep/strict signature verified; test-isolation checker passed. Includes final paywall copy. `/tmp/veil-rc-1.0-5.xcarchive`. App Store export/upload NOT VERIFIED. |
| Full serial Integration | FAIL |Completed 135 cases: **125 passed, 10 failed**, zero skips. All 10 failures were native OCR UI cases on iOS 26.1. All eight native StoreKit cases and the eligible-trial UI case passed. The separate compatibility matrix is recorded in the next row; its result does not erase or replace this failed full-run record. |
| CTO-approved split-runtime compatibility matrix | PASS | **135/135 unique required cases**, zero skips, failures or retries: 126 non-StoreKit cases on iOS 26.5 and 9 StoreKit/trial UI cases on iOS 26.1. `scripts/ci/local_release_matrix.py verify /tmp/veil-rc-matrix-final` exited 0 and verified exact inventories plus matching source/build fingerprints. This is a compatibility matrix result, not a passing single-runtime full Integration. |

## Apple technical requirements checked

Official [current upload requirements](https://developer.apple.com/news/upcoming-requirements/) checked13October2026: Xcode26+/iOS26SDK since28April2026, iOS deployment target13+ since9September2026, and updated age-rating questionnaire. Inspected Xcode26.6/SDK26.5 and app minimumiOS17 meet the toolchain/deployment thresholds; no upload acceptance is implied. [Screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) accepts1320×2868 for6.9-inch iPhone; six final opaque JPEGs pass local dimensions/hash/alpha validation. No iPad assets are required for this iPhone-only target.

PR87/87 passed on iPhone13mini/iOS26.5, no skips/failures; exact inventory verified (`/tmp/veil-rc-pr/Tests.xcresult`). That PR and the earlier universal Simulator Release preceded the isolated paywall-copy correction. The completed serial Integration included the final copy but has the overall OCR failures recorded above. A later local arm64 development archive also includes the final copy and passed strict signature/test-isolation checks; it is not a distribution archive. Distribution signing/export remains NOT VERIFIED.

## Findings and privacy boundaries

- **Historical first-run failures:** the initial full Integration finalized133/135, with two StoreKit failures (accelerated grace expectation and concurrent refresh/XCTest stall). The later serial Commerce comparison passed23/23, including those targeted cases. These results remain preserved as historical evidence and do not substitute for the final full-run result below. No skip, mock, timeout inflation or retry-until-green was used.
- **Resolved configuration defect:** marketing version4.0/build4 was inconsistent with owner App Store version1.0; now1.0/build5. Owner must verify build uniqueness.
- **Resolved test-runner defect:** unsigned simulator invocation invalidated Keychain-backed allowance testing. Normal ad-hoc simulator signing retained. Installed iOS26.5 fails native StoreKit configuration activation; StoreKit plans explicitly select verified26.1 without disabling native tests.
- Distribution signing inventory: one valid development identity, zero Apple Distribution identities; counts only in `/tmp/veil-rc-signing-inventory.json`. Signed distribution acceptance is **BLOCKED** without approved signing/provisioning. No credentials were printed or changed.
- Keep remains default. JPEG re-encoding retains supported GPS/capture/camera/descriptive fields where available, not exact source bytes, opaque MakerNotes, original embedded previews/auxiliary content or unsupported tags. Remove creates sanitized output and fails closed. Originals are not overwritten. Blur is not a guarantee against inference; inspect every output.
- Two successful operations count, not two unique photos. Save-to-gallery/Photos consume only after completion; activity completion is iOS success, not proof of recipient delivery. Process death between external success and local bookkeeping is not atomic. Local Keychain allowance is anonymous/device-local, not cross-device/reinstall-proof.
- No analytics/ads/tracking added. Optional Auth/cloud SDK code exists but backend config is absent. Source manifest is conservative about potential optional cloud collection; questionnaire must match the actual distributed scope. Apple purchase processing and on-device analysis are not developer data collection by themselves.
- Public legal links are unset; production purchasing is correctly blocked. Do not claim this local candidate is commercially operable until approved URLs and App Store products exist.

## Latest full serial Integration and OCR findings

The completed full serial Integration executed **135 cases: 125 passed and 10 failed** on the compact dark iOS 26.1 destination. All ten failures were native OCR UI cases. All eight native StoreKit lifecycle cases and the eligible-trial UI case passed in that run. Do not describe the overall Integration run as passing.

Crash evidence identifies Apple Espresso/TextRecognition on `com.apple.CoreRecognition.recognizerPredictionQueue` (SIGBUS/KERN_MEMORY_ERROR in mapped-file regions) in largest-text tool/plate and rapid-selection cases. An isolated real-Vision reproduction outside Veil showed the same SIGBUS on iOS 26.1; unchanged plate UI passed on iOS 26.5. These observations narrow the failure, but do not establish a general platform cause or convert any failed test into a pass. No OCR quality/revision/CPU-only/mock workaround was introduced. [Sanitized crash frames](Evidence/Release-1.0/ocr-crash-summary.json); raw crash reports stay locally under DiagnosticReports.

The CTO-approved split-runtime compatibility matrix passed: **126 non-StoreKit cases on iOS 26.5**, plus **eight native StoreKit cases and one eligible-trial UI case on iOS 26.1**. The verifier confirmed 135 unique required cases with zero skips, failures or retries and matching source/build fingerprints. This result does not resolve the separate full serial iOS 26.1 Integration failure; it is not a single-runtime full Integration pass. The default single-runtime Integration runner still selects 26.1 and retains this known OCR limitation; the local matrix does not rewrite or silently replace the CI gate. The physical-device test build separately exited 65 before tests because runner provisioning profiles are missing; provisioning updates were not authorized or attempted.

## Visual / asset evidence

Actual light 6.9-inch screenshots were reviewed by root and a separate presentation QA thread: home, Redact, Metadata Keep, Watermark, final review and gallery. Redaction/watermark are visible and controls fit. The final fictional-metadata sample shows supported metadata kept; the saved Keep and Remove outputs were audited. Two faces and the selected plate are blurred in Keep, faces are blurred in the separately configured Remove example, with baked watermarks in both. Native AppKit composition uses full unaltered UI images, not fabricated UI. Fourteen additional light/large captures (Guide/About/Privacy/Help, Metadata, Watermark, review, largest text and gallery delete/selection) passed independent visual review with no material clipping/overlap. Empty Gallery was not in that reviewed set.

Nine current compact dark screenshots from cases that passed within the overall failed Integration run were independently inspected: home, Redact, Keep metadata, Watermark, final review, gallery, Remove output and loaded monthly/yearly local StoreKit trial plans. The core editing and review screens are legible and balanced, with visible redactions and watermark; Keep is clearly selected; gallery content fits. Loaded plan prices/trial disclosures are visible, while the purchase controls and legal links continue below the scroll viewport by design; native tests verify scroll access. These are local `.storekit` prices, not production App Store pricing. The captures do not imply that the entire Integration passed. Visual review does not establish physical-device VoiceOver, animation, or device performance acceptance.

Existing historical visual pass is not a fresh physical VoiceOver or live animation/performance result. Synthetic sample publication rights remain owner confirmation.

## External acceptance not performed

**NOT VERIFIED:** real Apple Sandbox purchases, physical-device restore/reinstall/cross-device, real billing recovery/refunds, offline account transitions, VoiceOver, mobile peak memory/color/48MP, actual ASC agreement/products/prices/trials/DSA/privacy/review fields. **BLOCKED:** signed distribution export/upload acceptance, public legal URLs, existing V4 physical/configured-backend gate. A local development-signed archive passed; that is distinct from App Store distribution acceptance. No TestFlight upload, distribution, deployment or submission was performed.

See [manual owner steps](APP_STORE_CONNECT_CHECKLIST.md). The split-runtime compatibility matrix passed, while physical-device acceptance, distribution signing, production Sandbox, legal publication and the V4 owner gate remain outstanding. A passing local matrix is not release authorization.
