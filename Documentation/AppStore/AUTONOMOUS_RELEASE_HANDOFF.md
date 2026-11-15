> Final update2026-10-28: App Privacy published; app1.0(7), group and both subscriptions submitted and read back WAITING_FOR_REVIEW. MANUAL release retained; no public release. See [actual final submission](FINAL_SUBMISSION_STATUS.md). Earlier submission-authorization and App Privacy/contact blockers below are historical and resolved.

> Current release update — 2026-10-28: approved legal site is live and verified; Privacy/Support URLs are configured and read back in ASC and signed build1.0(7). Build7 is VALID and IN_BETA_TESTING in the existing internal group. See [build7 release report](LEGAL_RELEASE_BUILD7.md) for exact test outcomes, unsubmitted subscription draft and remaining owner gates. Historical missing-policy/build6 statements below no longer describe the current binary. No public App Review or release occurred.

> **Latest focused update — verified 2026-10-28:** build **1.0 (6)** is uploaded, processing **VALID**, and **IN_BETA_TESTING** in the existing internal acceptance group. Home animation/URL integration and dormant SDK-free contextual advertising preparation are implemented; live ads/public policy remain blocked on approved external setup. PR94, Commerce23 and focused UI checks passed. See [FINAL_IMPROVEMENTS_BUILD6.md](FINAL_IMPROVEMENTS_BUILD6.md); older checkpoints below are historical.

# Autonomous release handoff — 2026-10-26–27

**Current scope:** Blur, Watermark & Metadata, `com.maksym1503.veil`, app `6822230720`, version **1.0 (5)**. This report supersedes the older live-state summaries in the release documents; their dated failures and artifacts remain historical evidence. No final App Review submission, public release, external beta review, tester invitation or legal-site deployment occurred.

## Release verdict

- **PASS:** approved commercial configuration, English draft listing, six rights-cleared listing screenshots, both subscription review images, distribution archive/export and Apple IPA validation.
- **PASS:** corrected full compatibility matrix **135/135 unique cases**, zero failures/skips/retries, matching source/build fingerprints: native 9 on iOS 26.1 plus 126 on iOS 26.5. The earlier failed native shard remains preserved as history.
- **PASS:** signed build **1.0 (5)** uploaded and independently read back as **VALID**.
- **BLOCKED:** TestFlight testing/distribution is **MISSING_EXPORT_COMPLIANCE**. The owner must answer Apple’s compliance questions; no answer was supplied automatically. No build/group assignment or tester invitation occurred.
- **BLOCKED:** commercial App Review readiness. No approved public Privacy Policy/Support URL, legal identity/contact confirmation or completed owner compliance declarations. Production purchase completion remains intentionally disabled while the Privacy Policy URL is absent. Build 5 is intended only for bounded internal acceptance once Apple's distribution gates allow it; it cannot establish production purchase acceptance.
- **NOT VERIFIED:** real Apple Sandbox purchases, physical-device acceptance, cross-device restoration, 12–48 MP iPhone memory and VoiceOver acceptance. The registered paired iPhone is currently unavailable; cached device information is not a test result.

## Completed App Store Connect changes

All mutations used the existing authenticated `asc` CLI against the verified app/resources. Raw account/signing responses are private outside the repository. Selected non-sensitive readbacks are in [AutonomousRelease/2026-10-26](AutonomousRelease/2026-10-26/).

| Setting | Verified result |
| --- | --- |
| Subscription group | **Photo Privacy Pro**, `22471223` |
| Monthly | `vail.pro.monthly`, `6822234307`, **ONE_MONTH**, level **1**, **READY_TO_SUBMIT** |
| Annual | `vail.pro.annual`, `6822764295`, **ONE_YEAR**, level **1**, **READY_TO_SUBMIT** |
| Poland recurring prices | Monthly **12.99 PLN**, annual **99.99 PLN**; monthly was 14.99 PLN. Other monthly storefront prices preserved. |
| Introductory offers | **175 per product**; exact same selected territories; **FREE_TRIAL / THREE_DAYS / one period**, starts **2026-10-26**, no scheduled end. |
| Subscription availability | Annual now matches monthly's **175 territories**, including the future-territory setting. Availability is configuration, not evidence of approval or a live storefront product. |
| Eligibility/service | Same group and same level; one introductory offer per customer per group under Apple's rules. Both plans unlock identical unlimited exports. |
| Billing Grace Period | Remains disabled; not silently enabled. Grace-state code is separately tested locally. |
| English product metadata | Both existing/new draft product versions localized, benefit text and truthful provisional review notes completed. |
| Subscription review images | Both actual native paywall images delivered **COMPLETE**. Images use local StoreKit, not production Sandbox transactions. |
| Obsolete group | **Photo Privacy Yearly**, `22475732`, old `vail.pro.yearly` product untouched; no delete/revoke. |
| English listing | Approved name retained; subtitle, promotional text, keywords and revised **2,781-character** description uploaded and read back exactly. Apple Standard EULA linked in the description. |
| Category / age draft | **Photo & Video** primary; source-factual questionnaire completed without a Kids category or age override. Owner should review the factual answers before submission. |
| Download pricing / availability | Free download verified as **0.0 PLN**, base **POL**; app availability matches the selected **175 territories**. No preorders or public release. |
| Listing images | Six **1320 × 2868** JPEGs delivered **COMPLETE**, with local MD5 matches; native screenshot set is `APP_IPHONE_67` (CLI's `IPHONE_69` alias). Order finalized as Home → Redact → Metadata → Watermark → Review → Gallery. |
| App Review draft | Provisional version-1.0 notes saved/read back through the official API; no app demo account required. Missing private contact fields remain unset; no submission. |
| Build upload / processing | **1.0 (5)**, build ID `16483372-952f-46dc-908f-7eebcbfc472c`, **VALID**. English What to Test saved/read back; automatic tester notifications disabled. Internal/external eligibility is MISSING_EXPORT_COMPLIANCE; not distributed. |
| Internal TestFlight preparation | Internal-only group **Veil 1.0 Internal Acceptance**, no all-build access/public link/tester invitations. English beta description explicitly discloses the purchase/legal limitation. |

Apple permits both trial durations and limits an introductory offer to one per subscription group; switching these plans must not provide a second trial. Configuration changes can take time to propagate to Sandbox. Sources: [introductory offers](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/), [build status meanings](https://developer.apple.com/help/app-store-connect/reference/app-build-statuses/).

## Subscription review assessment

[Guideline 3.1.2](https://developer.apple.com/app-store/review/guidelines/#subscriptions) was rechecked against Apple’s current text. Both billing periods exceed seven days, provide the same repeated unlimited-export utility while entitled, and use the Apple Account entitlement across supported devices. The description/paywall explain the recurring benefit and actual localized billing rather than promising future cloud services or guaranteed privacy. Whether that ongoing utility satisfies App Review remains Apple’s assessment; configuration and native tests are not approval. No unapproved lifetime tier or new feature was invented. Cross-device behavior still requires real Sandbox acceptance.

## Repository work completed in this execution

Earlier annual-SKU migration and all product/editor/commerce implementation remain preserved. This execution specifically changed:

- `Tests/PhotoVeilCommerceTests/StoreKitSubscriptionTests.swift`: replaced the unsupported second `Transaction.updates` consumer in the monthly renewal test with event-driven store reconciliation and verified renewed Apple transaction/entitlement assertions. New paid transaction ID, Xcode environment, future expiration, no introductory offer and no revocation are required. Original 10-second deadline, cancellation and expiration checks remain. No polling, mock purchase, arbitrary sleep, retry-until-green or production observer change.
- `Sources/PhotoVeil/VeilPresentation.swift`: real [Apple Standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) link, after verifying that no custom EULA is configured. Public Privacy/Support URLs remain absent; the legal purchase gate was preserved.
- `PrivacyInfo.xcprivacy`: current local-only collection declaration is empty, tracking remains off. Historical optional-cloud declarations preserved in `Documentation/Architecture/Privacy/`. This is source/artifact disclosure work, not an App Privacy attestation or compliance certification.
- `scripts/ci/check_release.py`: validates the app manifest and rejects bundled backend configuration with empty collection declarations, in addition to existing production test-resource checks.
- `Tests/PhotoVeilUITests/Fixtures/release-owned-sample.jpg`, `PhotoVeil.xcodeproj/project.pbxproj`, and the existing screenshot journey: original synthetic document fixture, Debug-only resource wiring/Release exclusion, actual manual Redact/metadata/watermark/review/gallery captures. No test method or existing automatic detection coverage removed.
- `Documentation/AppStore/Screenshots/1.0-release/`: reproducible native artwork and listing renderer, six original running-app images, provenance, and native subscription review captures.
- Legal-site drafts, exact official-link allowlist and packaging tests; current legal facts, owner confirmations, review notes, beta notes, this handoff and [ADR-011](../Engineering/Decisions/011-autonomous-release-completion.md).

The broad pre-existing dirty working tree was retained. No unrelated work was reset, discarded or committed. Home animation, watermark behavior, default **Keep metadata**, rendering and privacy/export rules were not redesigned.

## Signing, build and artifact evidence

- **PASS:** distribution-signed arm64 archive `/tmp/veil-autonomous-1.0-5-target-signed.xcarchive`.
- **PASS:** exported IPA `/tmp/veil-autonomous-export/Veil.ipa`, **1.0 (5)**, correct bundle identifier, App Store profile, `get-task-allow = false`.
- **PASS:** strict/deep code-signature verification; hardened release-resource guard; actual app/Swift Crypto privacy manifests present, tracking off and empty collection declarations; no backend configuration, test photos, local StoreKit configuration, test analyzer, test launch override or StoreKitTest linkage in the app.
- **PASS:** Apple validation via `asc xcode validate --ipa …`: **VERIFY SUCCEEDED with no errors**. Validation is not upload, processing, TestFlight distribution or App Review approval.
- **PASS:** negative guard tests reject missing/malformed manifests and backend-with-empty-declarations. Tests operated on a temporary copy, preserving the signed artifact.

One needed Distribution certificate and App Store provisioning profile were created under the explicit signing authorization; no existing identities/profiles were revoked. Initial PKCS#12 import failed due to import-container compatibility, resolved with Apple's OpenSSL container encoding using the same identity. Initial archive signing flags incorrectly reached a dependency resource bundle; target-scoped temporary signing settings resolved that. Both failures are historical; the final signed archive and Apple validation passed. Existing project signing/team values and Keychain search list were restored.

Private signing material remains in an encrypted dedicated macOS Keychain outside the repository. Recovery was stored and verified through a native helper in login Keychain. Unencrypted private-key/import containers and temporary plaintext passwords were removed. No credentials are included in the handoff/package.

## Actual TestFlight upload status — verified 2026-10-27

**PASS — upload and Apple processing:** build `16483372-952f-46dc-908f-7eebcbfc472c`, **1.0 (5)**, iOS, minimum iOS 17.0, processing **VALID**. Apple reports upload date `2026-10-26T15:59:45-07:00`. The binary is `APP_STORE_ELIGIBLE`; “internal diagnostic” describes its intended use, not an internal-only binary restriction.

**FAIL, RECOVERED OBSERVATION:** the upload CLI committed the IPA, then its follow-up wait exited **3** with an authentication error. Fresh authenticated API calls confirmed the existing processed build; credentials were not replaced and the IPA was not uploaded again. Apple supplied no upload checksums for the requested comparison. The local IPA hash and successful prior Apple validation are retained; no server-checksum comparison is claimed.

**BLOCKED — distribution:** internal and external build states are **MISSING_EXPORT_COMPLIANCE**, with `usesNonExemptEncryption = null`. That legal answer remains for the owner. English test instructions were saved/read back using a fresh call. Apple’s default auto-notify flag was explicitly disabled. The internal group has zero testers; the build has zero group assignments and no beta-review submission. App Store version 1.0 remains **PREPARE_FOR_SUBMISSION / MANUAL**, with no selected build. Nothing was publicly distributed or submitted for review.

Evidence: [testflight-build-readback.json](AutonomousRelease/2026-10-26/testflight-build-readback.json). For owner completion: App Store Connect → app → TestFlight → iOS → 1.0 (5) → Manage export compliance. The exact build still has a nil Privacy Policy URL and cannot complete a new subscription purchase; a higher-numbered URL-configured build is required for commercial acceptance.

## Tests and independent review

| Check | Actual result / evidence |
| --- | --- |
| Standalone Commerce after renewal-test correction, before later staging changes | **PASS — 23/23**, zero skips/failures; `/tmp/veil-autonomous-commerce-revised/Tests.xcresult` |
| Revised monthly renewal case | **PASS — 1/1**; `/tmp/veil-autonomous-monthly-revised.xcresult` |
| Fresh SwiftPM | **PASS — 84 executed, 2 opt-in performance tests skipped, 0 failures**; `/tmp/veil-autonomous-swiftpm.log` |
| First fresh compatibility matrix | **FAIL:** 126/126 passed on iOS 26.5; 7/9 passed and 2 failed on iOS 26.1. `/tmp/veil-autonomous-matrix/`; first native UI probe and initial grace-access assertions failed. No aggregate pass. |
| Corrected staging | **PASS — 2/2**, same destination, zero failures/skips; `/tmp/veil-autonomous-native-staging/Tests.xcresult`. No production code change or unchanged test retry. |
| New complete compatibility matrix | **PASS — 135/135 unique cases**, zero failures/skips/expected failures/retries; current source and compiled-product fingerprints match all four before/after snapshots. Native 9 on iOS 26.1 + 126 on iOS 26.5. `/tmp/veil-autonomous-matrix-v2/`, [machine evidence](AutonomousRelease/2026-10-26/matrix-result.json). This is not a single-runtime full Integration pass. |
| Rights-cleared native screenshot journey | **PASS — 1/1**; `/tmp/veil-autonomous-owned-capture.xcresult` |
| Listing asset validation | **PASS — 6 accepted size/format assets, 0 errors/warnings**; six delivery/checksum readbacks independently verified |
| Legal audit / packaging | **PASS — four-page audit, 10/10 packaging tests**; `/tmp/veil-autonomous-legal-qa.log` |
| Fresh legal responsive rendering | **PASS — 32/32 native WebKit file-render states**, four widths × light/dark × four pages; additional 320px large-text stress and local HTTP/CSP checks passed. Six screenshots and reproducible harness in `CloudflarePages/2026-10-26-owner-review-final/qa/`. Chrome navigation blocked before DOM checks; its failed infrastructure attempt remains recorded, not counted as a pass. No live-host validation. |
| Repository inventory / whitespace | **PASS — 143 Swift methods accounted for**, `git diff --check` |
| Physical phone / real Sandbox | **BLOCKED / NOT VERIFIED**; phone unavailable, no transactions or physical tests claimed |
| Host performance opt-ins | **PASS — 2/2**, explicitly enabled and executed separately after the default suite; `/tmp/veil-autonomous-optin-profiles.log`. These resolve the default opt-in skips for host profiling, not physical-device performance. |

The later failed nine-case shard is preserved separately. Its prelaunch UI probe reported a successful off-device purchase without the expected signed JWS before the actual UI journey began. The grace test started a two-second subscription clock before product loading/purchase and failed its initial access assertion after 6.44 seconds. CTO approved establishing verified initial access at real time before native acceleration, and moving signed environment/product/bundle assertions into the existing app-hosted helper. The UI still performs a real paywall purchase and validates its ledger/trial/exports/restart; separate hosted checks are not claimed as same-UI-transaction signature proof. See ADR-011. The original failures remain failures, not product fixes inferred from testing infrastructure.

The old **22/23** Commerce failure remains recorded at `/tmp/veil-asc-annual-commerce-20261026/Tests.xcresult`. Inspection established an unsupported broadcast assumption in its second transaction iterator, not a proven Apple failure. Tests ran again only after correcting that oracle. Native Commerce uses genuine StoreKitTest transactions and signature verification, never mocked production entitlement flags.

The local Intel runtime compatibility issue remains: iOS 26.1 real OCR can crash on the historical fixture; iOS 26.5 local StoreKit configuration activation fails. The documented split-runtime matrix uses 126 non-StoreKit cases on 26.5 and nine native StoreKit/trial cases on 26.1. A passing matrix is **not** a single-runtime full Integration pass, production OCR fix or physical/Sandbox acceptance. Prior failures remain available.

Roles actually used: root Engineering Lead/Release Manager and QA; existing independent read-only CTO/reviewer (`gpt-6-astra`) for architecture/source/visual safety; existing developer thread (`gpt-6-luna`) for original assets/legal tooling and bounded QA. [ADR-011](../Engineering/Decisions/011-autonomous-release-completion.md) records the decisions. The final independent safety review also verified the IPA hash/bundle/build, absent compliance attestation, current manifest, absent backend configuration and preserved nil-Privacy purchase gate. It found no blocking issue for a conditional internal diagnostic upload after the matrix passes. No nested agents or provider activation.

## Host performance findings

Both opt-in profiles completed with zero failures. The 4032×3024 full-resolution effect-plus-JPEG operations took approximately **0.19–0.21 s**; 8064×6048 took **0.53–0.88 s**. Five-layer render plus JPEG took **0.30 s** at 12 MP and **1.28 s** at 48 MP. These are one diagnostic run on the Intel macOS host, not iPhone latency promises or a statistical benchmark. Coarse command/child maximum RSS was approximately **837 MiB**; this does not isolate the app's peak or GPU usage and cannot establish safe iPhone jetsam behavior. Physical large-photo memory acceptance remains open.

Detection remained fallible in the constructed small-face cases: **2/4** and **2/3** placed faces detected; edge/partial case **4/4**. The tests intentionally record diagnostics rather than asserting perfect recall. No output photograph or recognized text is included in release evidence. Existing review/manual redaction guidance and the V4 owner acceptance gate remain necessary; no claim of universal automatic detection was added. Sanitized measurements: [host-performance.json](AutonomousRelease/2026-10-26/host-performance.json).

## Marketing and legal publication package

- Final English listing: [APP_STORE_METADATA.md](APP_STORE_METADATA.md). No unsupported anonymity/security guarantees, blanket metadata-removal claim or hardcoded production price.
- Final listing artwork: [Screenshots/1.0-release/en-US/listing](Screenshots/1.0-release/en-US/listing/); actual unmodified UI captures plus reproducible original typography/composition sources. The synthetic document contains only fictional sample details, no third-party imagery or identifiable model. Older rights-uncertain people/car marketing assets were not used in this upload.
- Legal owner-review package: [REVIEW-ONLY-DO-NOT-PUBLISH.zip](CloudflarePages/2026-10-26-owner-review-final/REVIEW-ONLY-DO-NOT-PUBLISH.zip). Privacy, Apple-EULA-based Terms and Support are prepared, with safe static hosting controls. **Draft only; not publication-ready until required identity/contact/hosting facts and text are approved.**
- Facts and approvals: [LEGAL_FACTS_2026-10-26.md](LEGAL_FACTS_2026-10-26.md), [OWNER_LEGAL_CONFIRMATIONS.md](OWNER_LEGAL_CONFIRMATIONS.md), [App Review notes](APP_REVIEW_NOTES_DRAFT.md), [What to Test](TESTFLIGHT_WHAT_TO_TEST_DRAFT.md).

Current photo processing is local. Originals stay unchanged; Keep preserves supported fields rather than exact source bytes; Remove fails closed. No tracking/ads/new account/backend/analytics were introduced. Public website host request processing must be assessed separately from app photo processing. Source/artifact observations do not establish GDPR certification, an exact universal retention period or receiving-app behavior.

## Prioritized remaining owner checklist

1. **NEEDS OWNER ACTION — legal/business facts:** confirm public legal identity, dedicated public support/privacy contact, applicable business/trader information, website hosting details and the draft policies. Do not substitute personal residential data. Publish only the approved static package over HTTPS, then supply real Privacy Policy and Support URLs.
2. **BLOCKED — final commerce-capable binary:** put the approved URL into the app and ASC; build/upload a new version of the candidate (higher build number). Build 5's purchase gate cannot be enabled by changing only ASC metadata. Replace provisional purchase-disabled review notes and recheck localized products/trial eligibility in that final binary.
3. **NEEDS OWNER ACTION — Apple declarations:** confirm Paid Apps Agreement, bank/tax and current DSA status in Apple systems; review/publish App Privacy answers; personally complete the encryption/export-compliance classification for the uploaded build, which currently prevents TestFlight testing. No binding declaration, agreement acceptance or private contact was invented. Technical export inventory and Data Not Collected recommendation are prepared, not attestations.
4. **NOT VERIFIED — physical acceptance:** use a connected/unlocked iPhone to verify real OCR, Photos denial/grant, actual JPEG pixels/GPS in both policies, Share cancellation/success, restart and low-memory/large-photo behavior; verify VoiceOver/largest text and appearance. Then test monthly/annual trials, group eligibility on plan switch, renewal/expiry, restore and another device with real Apple Sandbox accounts. See [physical protocol](PHYSICAL_DEVICE_RELEASE_PROTOCOL.md). Existing README/V4 configured-backend/physical owner gates remain explicit; no cloud deployment was authorized or performed.
5. **NEEDS OWNER ACTION — final release:** verify the final legal URLs, subscription group localization and review assets, App Review contact, screenshots, compliance and build selection; include both first subscriptions with app 1.0. Only then authorize final App Review submission/public release. This execution did neither.

## Final acceptance status

- **TestFlight upload/processing: PASS.**
- **Ready for internal TestFlight testing: BLOCKED** by export compliance; build 5 is only a bounded diagnostic candidate because purchase completion is disabled.
- **Ready for commercial App Review: BLOCKED** by approved public legal/support URLs and final configured build, owner declarations/contact and physical/Sandbox acceptance.
- **Public release / final App Review / external beta review: NOT PERFORMED.** No required gate has been waived.

Final independent CTO/reviewer closure on 2026-10-27 found no blocking report/evidence consistency or safety finding. Review was read-only; live ASC verification and executed QA remain the coordinator’s recorded evidence. No production/source edits followed the passing matrix.
