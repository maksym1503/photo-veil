> Vail1.1 update: owner approved new installations1 successful export and preserved
> legacy recorded allowance2, with no usage reset. ADR-014 implements the same
> Keychain identity and success-only shared gate. This document's earlier two-free
> universal policy describes1.0. Current QA: `Documentation/QA/NextRelease/Beta/`.

> Current release update — 2026-10-28: approved legal site is live and verified; Privacy/Support URLs are configured and read back in ASC and signed build1.0(7). Build7 is VALID and IN_BETA_TESTING in the existing internal group. See [build7 release report](LEGAL_RELEASE_BUILD7.md) for exact test outcomes, unsubmitted subscription draft and remaining owner gates. Historical missing-policy/build6 statements below no longer describe the current binary. No public App Review or release occurred.

<!-- autonomous-current-status -->
> **Current status — autonomous execution, 2026-10-26:** Current native Commerce regression passed 23/23 after correcting the renewal test oracle; old 22/23 failure evidence remains preserved. Canonical production identifiers remain vail.pro.monthly and vail.pro.annual. Current commercial setup and legal-gated purchase limitation are detailed in the handoff. [AUTONOMOUS_RELEASE_HANDOFF.md](AUTONOMOUS_RELEASE_HANDOFF.md) is the authoritative current report.

## Autonomous native QA — 2026-10-26

The former monthly renewal timeout used a second `Transaction.updates` iterator even though Apple's API does not promise per-iterator broadcast delivery. The revised test observes app reconciliation and requires a new verified paid monthly transaction plus matching current entitlement. The production observer and original deadline are unchanged. The focused renewal case and a standalone 23-case Commerce suite passed; the original 22/23 failure remains preserved.

A subsequent full compatibility attempt passed all 126 non-StoreKit cases but failed two of nine native cases: an unrelated UI-runner prelaunch purchase probe reported no expected JWS, and a grace test started its two-second clock before initial product loading/purchase completed. The CTO-approved corrections move explicit signed environment/product/bundle checks into the actual app-hosted helper and establish verified initial access at real time before native grace acceleration. The UI retains its real paywall purchase, one annual ledger transaction, three-day duration, extra exports and restart; hosted signature checks are separate coverage, not the same UI transaction's signature proof. No mock purchase, skipped assertion, production override or increased timeout was added.

Same-destination focused tests passed **2/2**, then the new native shard passed **9/9**. The fresh 126-case companion run and strict aggregate check also passed: **135/135 unique cases**, zero failures/skips/retries, identical source/build fingerprints across all four snapshots. This is the documented split-runtime matrix, not a single-runtime full Integration pass. Failed and corrected bundles, exact paths and current upload status are in [the autonomous handoff](AUTONOMOUS_RELEASE_HANDOFF.md). Apple local StoreKit validation is not real Apple Sandbox or physical-device acceptance.


---

# Annual product reconciliation — 2026-10-26

Canonical paid identifiers are now `vail.pro.monthly` and `vail.pro.annual`, matching live Photo Privacy Pro group22471223. Internal Yearly naming stays intact. Earlier implementation/QA sections below correctly retain the then-used `vail.pro.yearly`; [ADR010](../Engineering/Decisions/010-annual-product-identifier.md) supersedes those setup identifiers, not their historical evidence. The obsolete live group/product were not changed or deleted. No quota/gallery/account migration or legacy entitlement alias was added. Current source tests, Release results and actual price/offer state are in [ASC_AUTOMATION_2026-10-26.md](ASC_AUTOMATION_2026-10-26.md).

---

# Veil freemium implementation

## Commercial 1.0 preparation — 2026-10-13

The current release verdict and fresh results are in [RELEASE_READINESS.md](RELEASE_READINESS.md) and [FINAL_QA_REPORT.md](FINAL_QA_REPORT.md). Earlier results below remain historical. The latest full serial Integration executed **135 cases: 125 passed and 10 failed**; all ten failures were native OCR UI cases on iOS 26.1. All eight native StoreKit cases and the eligible-trial UI case passed. A standalone real-Vision reproduction outside Veil showed the same SIGBUS on iOS 26.1; unchanged plate UI passed on iOS 26.5. The CTO-approved split-runtime compatibility matrix passed **135/135 unique required cases**, zero skips/failures/retries: 126 non-StoreKit on iOS 26.5 and eight StoreKit plus one eligible-trial UI case on iOS 26.1. Exact inventory and source/build fingerprints were verified. This matrix does not turn the separate 125/135 full Integration into a pass or establish a global OCR fix. The prior parallel run and serial Commerce comparison remain recorded below as historical evidence.

Owner-reported external state: enrollment active; bank/tax submitted; DSA verification submitted and last under review; app1.0 Prepare for Submission; group **Photo Privacy Pro** and monthly record created. Yearly record, live prices/trials, agreements and legal/review fields are **NOT VERIFIED**. No App Store Connect account was accessed. Use [current exact-value handoff](APP_STORE_CONNECT_CHECKLIST.md), which supersedes the older setup assumptions below.

Local candidate version1.0/build5, unchanged bundle/products and in-app Veil. The local configuration group display name now matches Photo Privacy Pro. The test runner retains simulator signing for real Keychain and chooses installed iOS26.1 for native StoreKit plans; PR retains newer-runtime coverage. No production purchase or subscription activation occurred. Approved public Privacy/Terms URLs remain required; nil links correctly prevent production purchase.

Implementation date: 2026-10-12. Local development only; no product registration, payment activation, paid service, distribution or signing change. App name stays Veil; owner-specified identifiers are `vail.pro.monthly` and `vail.pro.yearly`.

## Product and architecture

Veil provides two free successful output operations per device-local allowance, without an account. Editing, preview, import and failed/cancelled exports are free. Save to Veil counts after protected gallery persistence; Save to Photos after Photos completion; Share after `UIActivityViewController` reports completion without an error. Each successful operation counts, even when exporting the same photo again. Gallery re-exports use the same gate. Deleting history, signing out, cloud downloads and automatic replication of an already saved output do not reset or spend allowance. Subscribers have unlimited exports; paid exports do not spend unused free exports.

`ExportAllowance` serializes one UUID lease across all editor/gallery output paths. It prevents overlapping admission and duplicate completion. `VeilExportAccess` refreshes verified StoreKit entitlements before admission, then holds that lease through rendering, saving or native sharing. Future explicit cloud-upload/export commands must use this coordinator before creating an output and complete its lease only after successful output. The current opt-in cloud replication pipeline remains unchanged.

A separate nonsynchronizing Keychain item stores only schema version and completed count (0–2), using WhenUnlockedThisDeviceOnly protection. Corrupt/locked storage never creates a new allowance. Storage is probed before free admission; a successful output whose bookkeeping write fails is retained in memory and retried before another free admission. Pro is never unlocked by that record or by a stored local Boolean.

`VeilSubscriptionStore` uses StoreKit 2 products, verified current entitlements, a transaction listener, foreground/admission refresh and user-initiated AppStore.sync restore. Recognition and restore operate independently of legal-link readiness. Revocation/refund/expiry remove access; cancellation retains access through Apple's entitlement duration; billing grace retains access while Apple includes the transaction in current entitlements. There is no custom offline extension. No new account, server, billing SDK, analytics, tracking or image-processing changes. See [ADR-007](../Engineering/Decisions/007-freemium-exports.md).

The native paywall offers the same unlimited-export entitlement monthly or yearly, with StoreKit localized full billing prices. Yearly savings compare actual annual price with twelve monthly prices in the same currency (approximately 36% at the requested Polish targets). A three-day trial CTA appears only for an actual eligible three-day free-trial offer. All other cases use paid subscription wording. Full renewal amount/frequency and automatic renewal are disclosed. Close, Restore Purchases and legal actions remain available. An exhausted free user can dismiss and continue editing; purchasing does not unexpectedly start an export.

## Local StoreKit testing

`Configuration/VeilLocal.storekit` contains one group, equal service levels, monthly/yearly subscriptions, 12.99/99.99 PLN targets and three-day introductory trials. It is a test resource only, never an app resource. Use the explicit `VeilLocalStoreKit` scheme for local Run and `VeilCommerce` test plan for transaction/UI testing. Native transaction tests use the dedicated app-hosted `PhotoVeilCommerceTests` target; existing unhosted core testing is preserved. The normal PhotoVeil Run/Archive scheme has no StoreKit configuration attachment. Never archive/distribute the local-testing scheme.

Missing real Terms/Privacy links disables production purchasing while keeping restoration and entitlements functional. An explicit DEBUG-only UI-test development override permits local purchase exercises; it requires both `-veil-ui-testing` and `-veil-storekit-testing`. The paywall labels this state. Launch flags cannot technically prove Xcode has attached its StoreKit environment: verify the attached local configuration and Xcode purchase environment before exercising it. Release excludes this override. No production purchase flags are supplied.

Local validation commands (choose an installed simulator destination; normal simulator ad-hoc signing is required for Keychain):

```sh
swift test
python3 scripts/ci/validate.py
xcodebuild -project PhotoVeil.xcodeproj -scheme VeilLocalStoreKit -testPlan VeilCommerce -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -parallel-testing-enabled NO test
```

For manual testing, open the project, choose **VeilLocalStoreKit**, explicitly select an iOS Simulator in Xcode, verify/reselect **Edit Scheme → Run → Options → StoreKit Configuration: VeilLocal**, then Run. Native IDE selection/launch remains unverified; loaded-product visual acceptance is now exercised through the native UI tests described below; do not treat the scheme reference alone as proof of an active local environment. Never authenticate a real Apple Account to work around missing local configuration. Xcode's StoreKit transaction manager can simulate renewal, cancellation, refund, billing retry and grace. Test monthly and yearly separately with reset transactions; changing plans must not create a second introductory eligibility. Automated tests use actual StoreKitTest transactions, not an entitlement Boolean override. Eight native lifecycle cases are defined; their existence does not imply they passed.

Synthetic UI tests use an isolated Keychain account namespace; a supplied UUID `-veil-test-storage-id` preserves usage between test app restarts. Without a supplied ID a new test namespace is used. Production usage is unaffected. Tests must not clear the production Keychain record.

## Files

- `CommercePolicy.swift`: operation allowance, versioned record, share completion and pricing/trial presentation policy; former preparation helpers retained for compatibility.
- `VeilSubscriptionStore.swift`: StoreKit manager, product validation, verified entitlements and purchase/restore.
- `VeilSubscriptions.swift`: native two-plan paywall.
- `PhotoVeilApp.swift`: shared coordinator, secure usage storage, lifecycle wiring.
- `PhotoVeilHome.swift`, `VeilGallery.swift`: admission/completion integration, authoritative native share callback.
- `VeilPresentation.swift`: Pro settings entry; image/editor/hero presentation unchanged.
- `Configuration/VeilLocal.storekit`, `VeilLocalStoreKit.xcscheme`, `VeilCommerce.xctestplan`: explicit local testing.
- `Package.swift`, Xcode project, test inventory/matrix/plans and CI validation/release/execution scripts: source/test/resource membership and release isolation.
- Commerce core, native StoreKit and UI tests: success/failure/limits/lease/persistence, trial/prices, real local subscriptions and app export flow.
- README, commerce setup and release/legal drafts: current model and remaining owner gates.

## Earlier implementation validation (before the blocker investigation)

These historical results are preserved. The subsequent native investigation and final results below supersede the original local StoreKit blocker.

- Full SwiftPM suite: **84 executed; 82 passed, two existing opt-in performance cases skipped; zero failures**. Includes ten deterministic commerce cases and existing metadata/watermark/rendering/persistence tests. Log: `/tmp/veil-commerce-all-core-final.log`.
- Simulator Debug build succeeds. An initial unsigned UI run could not access Keychain and was stopped; normal local simulator signing corrected that test context. Production signing settings/identities were not changed.
- First unhosted StoreKit attempt was stopped on an Apple Account prompt; it is invalid transaction evidence. Six hosted cases then failed local configuration setup (`SKInternalErrorDomain Code 3`, empty products). That earlier eight-case suite used a simulated-error handshake before purchase/restore; the investigation below supersedes it because this call did not reliably establish activation. No live purchase was attempted.
- A CTO-approved recheck with corrected ad-hoc simulator signing also failed: **one selected monthly lifecycle case failed before purchase because zero products loaded**, with the same configuration error. `/tmp/veil-commerce-storekit-signed.xcresult` and `.log` preserve that result. The remaining seven final native cases were not executed after this prerequisite failure. At this stage native StoreKit lifecycle validation was blocked pending a functioning local environment. Apple's [developer forum report and DTS response](https://developer.apple.com/forums/thread/826971) describe the matching command-line StoreKit/iOS 26.5 configuration problem, including Xcode 26.6 with runtime 23F77. This historical run is failed prerequisite evidence; the later 26.1 native results are recorded below.
- **VeilPR: 87 passed, zero failures/skips/expected failures**, including ten commerce core cases and five existing composed UI smokes. `verify_execution.py` confirmed exact required inventory. Result: `/tmp/veil-commerce-pr-final.xcresult`.
- **First commerce UI run: 13 passed (10 core + 3 UI)** on iPhone 13 mini, iOS 26.5. Confirmed two free saves, third-operation gate, restart persistence, gallery gate and editor/gallery Share cancellation. This deliberately selected app-owned cases; it is not a passing full StoreKit plan. Result: `/tmp/veil-commerce-ui.xcresult`.
- Actual dark/unavailable-plan and largest-text screenshots reviewed independently. No material clipping/overlap found. At that stage product-loaded prices/trial/selection/CTA presentation was unverified; later loaded-plan UI captures and purchase execution are recorded below.
- **Final commerce UI/core selection: 14 passed, zero failures/skips**, on light iPhone 17 Pro, iOS 26.5: ten core cases and four UI cases. A completed native Copy share consumes one operation; cancelled editor/gallery shares consume none. Restart and gallery gating pass. Largest accessibility text scrolls to a hittable Restore Purchases button. `/tmp/veil-commerce-ui-final.xcresult`.
- Independent QA reviewed actual dark/light and largest-text captures. Reviewable app-only images are in [Evidence/Monetization](Evidence/Monetization). No personal photos, billing account details or purchase payloads are stored there.
- **Two existing export regressions passed**: Photos add-only authorization/save and custom watermark style/text, metadata Keep/Remove review, gallery persistence, cancelled gallery Share and Save to Photos. `/tmp/veil-commerce-regression.xcresult`. The watermark flow reviews/cancels Share before its second completed save so it preserves all path coverage within the two-export allowance.
- **Final Release simulator build passed** (arm64/x86_64, unsigned compile validation; no distribution archive). `check_release.py` passed: no fixture analyzer/debug photos, `.storekit` resources or commerce test launch overrides. `/tmp/veil-commerce-release.log`.
- A final small change routes the runtime trial CTA through the same tested `SubscriptionOfferPolicy`; ten commerce tests were rerun and passed afterward (`/tmp/veil-commerce-core-policy-final.log`), and the final Release build includes it. The earlier full PR run preceded that behavior-equivalent policy reuse.
- Static inventory validation passes for **141 Swift test methods** with existing baseline preserved; `git diff --check` passes. Full Integration, opt-in macOS performance profiles and device/sandbox release acceptance were not completed by this task.

Root acted as Engineering Lead and integration implementer. The developer implemented the bounded StoreKit/paywall work and was reused for read-only QA/visual review; that QA was not independent of its own initial implementation. The non-implementing CTO provided independent critical review and approved the architecture/test-host correction. No nested agents were used.

The CTO independently reviewed transaction authority, lease/accounting behavior and test isolation. A gallery departure race was corrected with a preparation-lifetime generation; a suspended preparation cannot present an orphan share sheet or retain the global lease. Once a share sheet is presented, its actual completion remains authoritative.

## Native StoreKit blocker investigation — 2026-10-12

The original failure was configuration activation, before purchasing: iOS 26.5 (23F77), Xcode CLI 26.6 (17F113), `SKInternalErrorDomain Code=3`, then zero products. The fixture is a test-bundle resource, not an application resource. Hosted tests load its exact bundle URL with `SKTestSession(contentsOf:)`; the Run scheme reference is not used to locate this test resource. JSON, product IDs, group, source/resource membership and test host were inspected. Normal simulator ad-hoc signing remains enabled. Existing signing/team settings, simulators and owner work were preserved.

A dedicated **Veil-CommerceNative-261**, iOS **26.1 (23B86)** simulator was created using Apple's free runtime download. The same fixture and initial test loaded both products and eligible trial correctly with no Code3. This isolates the original activation blocker to the 26.5 native environment, consistent with [Apple DTS's acknowledged StoreKitTest issue](https://developer.apple.com/forums/thread/826971). No private daemon state, production account or mock purchase was used. The default Xcode selection was not changed. Both Xcode 26.5 and 26.6 IDE applications exist on this host; all recorded command-line runs use Xcode 26.6. Opening the newer IDE did not establish a loaded workspace, so manual IDE Run acceptance is not claimed.

The first 26.1 purchase revealed a second harness defect: `setSimulatedError(nil, forAPI: .purchase)` returned successfully but native `ASOctaneSupportXPCService` logged **`Received unsupported ASOctaneSimulatedError "" for FailureType`**, and its localhost purchase server canceled the purchase. The harness now uses documented `resetToDefaultState()` and reapplies intended local settings; it verifies the read API reports no simulated purchase error. When clearing deliberately injected errors, it also asserts transaction IDs are preserved. Exact fixture-product IDs are fetched before any purchase/restore. Successful purchases must have Apple verification and `.environment == .xcode`; trials assert introductory offer, free-trial payment mode and a signed expiration exactly three days after purchase.

Real lifecycle execution also exposed missing observation of subscription status changes without a new transaction. `VeilSubscriptionStore` now consumes `Product.SubscriptionInfo.Status.updates` alongside `Transaction.updates`. Verified allowlisted events trigger the existing current-entitlements scan; they never grant access directly. Cancellation, billing and expiration updates now refresh while the app is open. Existing revision guards and task cleanup remain intact. No UI, metadata, image processing, export accounting, tracking, provider or production configuration changed.

Native mutation APIs return before publishing their signed updates. Tests register event/publisher observers before mutations, use existing bounded expectations and verify signed expiration/revocation after access removal. There are no polling retries, sleeps, fake entitlements or disabled assertions. The monthly case verifies trial → paid renewal → cancellation retaining access → expiration. The final grace case uses Apple's documented `.oneRenewalEveryTwoSeconds` clock rate. Observers register before purchasing; the test requires grace **with access**, subsequent native grace exhaustion/access loss, and a verified `.xcode` transaction whose signed expiration is in the past. The existing ten-second expectation bound is unchanged. Its focused run passed in **4.969 seconds**, with no calendar conversion assumptions, polling or sleep.

Earlier grace hypotheses remain failed evidence: expiring an already-expired grace transaction returned `NoTransactionFound`; toggling grace configuration did not terminate an existing grace entitlement; and no `SKTestTransaction.hasPurchaseIssue` was exposed for the proposed recovery API. The final test supersedes these unsupported harness operations with actual automatic grace exhaustion. Billing recovery itself is not claimed as tested.

Preserved investigation results:

- `/tmp/veil-commerce-native261-first.xcresult`: product loading/eligibility succeeded; purchase failed from the unsupported nil override.
- `/tmp/veil-commerce-native261-corrected.xcresult`: verified three-day trial succeeded; immediate renewal query raced the native update.
- `/tmp/veil-commerce-native261-renewal.xcresult`: trial and paid renewal succeeded; immediate expiration query raced the native update.
- `/tmp/veil-commerce-native261-synchronized.xcresult`: cancellation status observation failed, identifying the missing status observer.
- `/tmp/veil-commerce-native261-status.xcresult`: **one focused monthly lifecycle case passed**, including trial, paid renewal, cancellation and expiration.
- `/tmp/veil-commerce-native261-full.xcresult`: **eight executed, seven passed, one failed** on the invalid grace expiration call described above.
- `/tmp/veil-commerce-native261-commerce.xcresult`: **23 executed, 21 passed, two failed**. The UI purchase succeeded but a post-purchase transaction query from the separate UI runner returned no app entitlement; grace-policy toggling did not end existing grace. Both harness boundaries were corrected, not treated as product success.
- `/tmp/veil-commerce-native261-gaps.xcresult`: the real yearly-trial UI flow passed (51.576 seconds), including exports beyond two and app restart; the unsupported grace-recovery precondition failed.
- `/tmp/veil-commerce-native261-grace-clock.xcresult`: **one native grace/automatic-expiration case passed** (4.969 seconds).
- Full-plan, regression and Release results for the final revision are recorded separately below. Historical failures above remain failures and are not discarded.

The UI harness cannot query the app's StoreKit2 entitlement namespace from its separate runner. Before UI purchases it now performs a target-bound native `SKTestSession.buyProduct` preflight, verifies `.xcode` and the expected bundle ID, clears transactions/resets settings, and asserts an empty session. The UI then requires an eligible trial CTA, records the actual yearly SKU and three-day dates, and verifies Pro exports/restart in the app. App-hosted tests independently verify the app manager’s StoreKit2 transaction authority. The preflight transaction is distinct from the subsequent UI purchase and is not evidence of verification of that later transaction.

Additional changed files in this QA pass: native StoreKit test harness; subscription manager status observer; commerce UI test for real yearly trial, loaded plan screenshots, exports beyond two and app restart; test inventory/matrix; ADR007; this report. Real sandbox cross-device behavior and production products remain distinct acceptance boundaries; automatic grace exhaustion is now exercised using Apple’s native local clock.

Reproduce native QA with the installed iOS 26.1 runtime (install using `xcodebuild -downloadPlatform iOS -buildVersion 26.1 -architectureVariant universal` if needed). Create/select a dedicated simulator, then run `xcodebuild test -project PhotoVeil.xcodeproj -scheme PhotoVeil -testPlan VeilCommerce -destination 'platform=iOS Simulator,name=Veil-CommerceNative-261,OS=26.1' -parallel-testing-enabled NO`. Keep normal simulator signing enabled. Do not erase owner simulators or globally switch Xcode to work around the issue. The normal scheme is sufficient for these tests because native SKTestSession loads the test fixture explicitly. Manual Run still requires the explicit local scheme and simulator selection.

## Final native QA results

- **VeilCommerce: 23 passed, zero failures/skips/expected failures.** Ten core, eight native StoreKit, five UI cases. `scripts/ci/verify_execution.py` verified exact required inventory in `/tmp/veil-commerce-native261-final.xcresult`; the run completed successfully, not merely discovery or partial console output.
- Real native coverage: both products load; monthly/yearly purchases; actual eligible three-day introductory activation; one offer per group; trial-to-paid monthly renewal; cancellation retaining access; signed expiration; automatic native-clock grace exhaustion; billing retry without grace; external-purchase listener; refund/revocation; restore and manager restart; concurrent refresh; purchase cancellation/network failure/pending approval; unverified transaction denial; unavailable products.
- Real UI coverage: two free exports, third-operation paywall, persisted counter/gallery gate; completed Share consumption; cancelled editor/gallery Share remains free; yearly trial purchase followed by exports three/four and a further export after app restart; largest Dynamic Type/Restore accessibility. Product-loaded monthly/yearly prices, savings, selected states and trial billing copy were independently reviewed from running-app screenshots in [Evidence/Monetization](Evidence/Monetization). The existing paywall scrolls to the purchase CTA; no layout redesign was introduced.
- **SwiftPM: 84 executed, 82 passed, two existing opt-in performance tests skipped, zero failures.** `/tmp/veil-commerce-native-core-full.log`. Targeted commerce core rerun: ten passed, zero failures (`/tmp/veil-commerce-native-core.log`).
- **Two existing export regressions passed, zero failures/skips**: Photos add-only saving and custom watermark/styles/text, metadata Keep/Remove, gallery persistence, cancelled gallery Share and Photos export. `/tmp/veil-commerce-native261-regressions.xcresult`.
- **Release simulator build passed for arm64/x86_64**, unsigned local compile (no archive/distribution), `/tmp/veil-commerce-native-release.log`. `check_release.py` passed: no `.storekit`, debug fixture images/analyzer or commerce development flags. Binary linkage contains StoreKit, with **no StoreKitTest framework**.
- **Static inventory: 142 Swift methods**, `validate.py` passes; `git diff --check` passes. The full PR/Integration plans and opt-in performance profiles were not rerun as part of this blocker pass; earlier results above remain historical evidence.

Final evidence counts/hashes are in [validation.json](Evidence/Monetization/validation.json); the earlier snapshot is retained as `validation-before-native-qa.json`.

Root implemented the bounded fixes; the read-only CTO independently approved/reviewed architecture and final code, and the reused QA thread reviewed native harness/results and actual loaded-plan screenshots. No production credentials, provider, paid service, subscription registration or distribution was activated. Remaining real sandbox/device and App Store Connect gates below are not established by local Xcode testing. Billing recovery is not included in the passing scenario claims.

## Required App Store Connect setup and release gates

1. Confirm Paid Apps Agreement is active and tax/banking accepted. Enrollment is owner-reported active; bank/tax submitted, not independently confirmed accepted. No registration or contract was performed here.
2. Create the exact two supplied product IDs under this app in **one** auto-renewable subscription group, both **same level** with identical unlimited-export features. The app bundle/name are unchanged. Product IDs are permanent; verify spelling before creating them.
3. Set monthly period / yearly period and Polish target prices **12.99 PLN/month** / **99.99 PLN/year** using available Apple price points. Confirm storefront prices/tax handling; other storefronts use Apple's localized prices. No hardcoded production prices.
4. Configure a **three-day free trial on each product** with intended territories/dates. Apple allows one introductory offer per subscription group, not one per plan. Eligibility is Apple's decision. Configure Billing Grace Period deliberately in App Store Connect; do not promise access beyond Apple's verified state. Family Sharing remains off unless owner approves that irreversible setting.
5. Publish real Privacy Policy and Terms of Use destinations, identify legal controller/contact/support and set `VeilPublicLinks`. Do not ship nil links or treat the in-app explanatory privacy page as a public legal policy. Production purchase is intentionally blocked until these are supplied.
6. Provide subscription localizations, review screenshot/notes, availability and app-version association. Explain two free successful exports, unlimited protected outputs, exact trial/billing terms and ongoing product value. Submit products with the first commercial app version when Apple requires it.
7. Validate Apple sandbox/device purchase, account switch, restore/reinstall/second device, refunds, billing grace/retry, localized pricing, offline cached entitlements, renewal/cancel/expiry and accessibility. Local Xcode tests do not establish real App Store Connect or cross-device acceptance.
8. Owner physical-device V4 acceptance and configured-backend review remain separate merge/release gates. No App Store/TestFlight upload, Xcode Cloud, BrowserStack or production provider has been activated.

## Known limitations

- The free allowance is device-local and anonymous. Keychain often survives app deletion but Apple does not guarantee reinstall survival. Device erase, different devices and storage lifecycle changes can produce a new allowance. It is intentionally not an App Store account quota and is not synchronized or backed up. No fingerprint or tracking is used to prevent reinstall abuse.
- Photos/activity services and Keychain cannot commit atomically. A process kill in the narrow interval after external success but before persistence can leave that operation uncounted. Counting attempted/pending operations instead would incorrectly charge failures/cancellations; the implementation favors success-only accounting.
- Share completion indicates that iOS completed the selected activity; Veil cannot prove a recipient received the file or how many recipients/copies a third-party activity creates. Cancelling an activity does not consume an export.
- Apple controls offline entitlement freshness and external account changes. Cached verified entitlements can work offline; no app-local permanent unlock exists. Restoring or discovering newly purchased access on another device may require network/App Store availability.
- Re-encoded image metadata remains subject to the already documented Keep/Remove limitations. Monetization never changes metadata choice, pixels, originals, watermark content, Photos authorization or cloud consent.

## Official Apple sources checked 2026-10-12

- [Auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/): one group, equal levels, pricing disclosures, ongoing value, terms/privacy links.
- [Introductory offer setup](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions): one introductory offer per group.
- [Current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements): subscribed/grace included; refunded/revoked excluded.
- [Introductory offers](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app): actual offer and customer eligibility.
- [StoreKit testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-in-xcode), [SKTestSession](https://developer.apple.com/documentation/storekittest/sktestsession): local product/transaction/failure testing.
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 3.1.1, 3.1.2 and privacy/completeness requirements.
