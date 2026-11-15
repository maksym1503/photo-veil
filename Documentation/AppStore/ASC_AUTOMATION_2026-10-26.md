<!-- autonomous-current-status -->
> **Current status — autonomous execution, 2026-10-26:** Historical audit and earlier reconciliation evidence below are preserved. The later autonomous execution configured the approved prices/trials/availability and completed signed distribution validation; consult the handoff for current verified results and unresolved gates. [AUTONOMOUS_RELEASE_HANDOFF.md](AUTONOMOUS_RELEASE_HANDOFF.md) is the authoritative current report.

---

# App Store Connect automated preparation — 2026-10-26

**TestFlight BLOCKED. App Review BLOCKED.** This is the current live API reconciliation, superseding older owner-reported catalog assumptions. Existing uncommitted work/signing was preserved. No API credentials were read into the repository; authenticated raw responses, certificates and native receipt-bearing diagnostics remain in a private temporary directory. Public evidence is field-allowlisted under [ASCPreparation/2026-10-26](ASCPreparation/2026-10-26/README.md).

## Automatically completed

- Verified installed `asc`5.17.0 authentication with an actual read-only Apple request and resolved the app by exact BundleID `com.maksym1503.veil`: **6822230720**, **Blur, Watermark & Metadata**.
- Audited app/version/localizations, builds/TestFlight, both groups/products, product localizations, Poland prices/price points, introductory offers, availability, grace, signing inventory and submission validation using discovered CLI commands/public Apple endpoints.
- Corrected annual resource6822764295 from service level2 to **level1**, matching monthly and the approved equal-feature model. Immediate API read-back verified. No price, offer, availability or FamilySharing field was changed.
- Created group version `dca369ae-f256-4d45-9c55-ef773f02695b` and exact approved **en-US Photo Privacy Pro** group localization. Read back **PREPARE_FOR_SUBMISSION**; no review submission or activation.
- Migrated the app/fixture/explicit UI checks to **`vail.pro.annual`**. Central verified-entitlement allowlist continues to drive loading, purchase, updates/status and restore; internal `yearlyID`/Yearly presentation remains. No legacy alias or persistence/schema migration. Added native canonical-product and obsolete-SKU exclusion assertions to the existing annual lifecycle case. See [ADR010](../Engineering/Decisions/010-annual-product-identifier.md).
- Prepared exact English metadata API payloads and a commercial proposal locally. Validated all six listing screenshots with `asc`, plus a read-only upload dry run. **Neither operation uploaded screenshots or marketing copy.**

## Actual live configuration

| Resource | Verified state |
| --- | --- |
| App / iOS version | App6822230720; version1.0 `f43ca897-4b4c-497f-8c81-dc87b22cbae2`, PREPARE_FOR_SUBMISSION; manual release |
| Builds / TestFlight groups | **0 builds**, **0 beta groups**; no build attached to1.0 |
| Intended group | **Photo Privacy Pro —22471223** |
| Monthly | **vail.pro.monthly —6822234307**, ONE_MONTH, level1, MISSING_METADATA |
| Annual | **vail.pro.annual —6822764295**, ONE_YEAR, now level1, MISSING_METADATA |
| Obsolete group/product | **Photo Privacy Yearly —22475732** / **vail.pro.yearly —6822760203**, ONE_YEAR, MISSING_METADATA; **untouched, not deleted, not recognized/offered by the updated app** |
| Poland monthly price | **14.99PLN**, differs from approved target12.99PLN; target price point exists |
| Poland annual price | **99.99PLN**, matches target; having a price does not establish sale availability |
| Introductory offers | **0 monthly, 0 annual**; no production three-day trial created |
| Availability | Monthly175territories includingPoland, automatically includes new territories. Annual availability resource is **missing** (API404). No availability changed |
| Billing grace | `optIn:false`, `sandboxOptIn:false`, duration/renewalType unset. Not enabled |
| Product English names | Photo Privacy Pro Monthly / Photo Privacy Pro Yearly; descriptions already say unlimited photo exports. Source app Yearly wording remains consistent with duration |
| Group English localization | Newly prepared in draft group version; not submitted |

The app's first-release context plus all paginated versions showing only1.0 PREPARE_FOR_SUBMISSION, zero builds/beta groups and all products MISSING_METADATA support prelaunch identifier reconciliation. Absence of builds alone was not used as proof of no customers. Contrary historical customer evidence would require an explicit compatibility decision before removing a valid entitlement.

## Metadata and screenshots

The live approved title already exactly matches; no redundant write. Existing live English description/promo were preserved. Subtitle/keywords are absent; Support and Privacy URLs are absent. The local subtitle23, promo164, description3194 and keywords91UTF8bytes are prepared proposals, not evidenced owner-approved copy. Exact new-field payloads are [app-info](ASCPreparation/2026-10-26/proposed-app-info-metadata.json) and [version](ASCPreparation/2026-10-26/proposed-version-metadata.json). The title is the only listing field explicitly approved in prior local evidence. Owner approval was requested for the four proposed fields; no response/approval has been inferred.

Six native1320×2868 screenshot compositions in `Screenshots/1.0/en-US/listing/` pass `asc screenshots validate`: **6ready,0errors,0warnings**. CLI `IPHONE_69` maps to API `APP_IPHONE_67` for these accepted dimensions. Upload dry run returned `dryRun:true,total:6`; the live screenshot sets remain empty. The genuine running-app captures and fictional metadata have technical provenance, but sample-photo/likeness/property publication rights and exact set/caption approval remain **NOT VERIFIED**. Owner confirmation was requested; no uploads were authorized by technical validation alone.

**Uploaded App Store listing metadata: none. Uploaded screenshots: none.** The distinct subscription-group draft localization above is the only localization created. No Cloudflare/legal-site artifact was uploaded or used as a public URL.

## Commercial proposal — approval required

[commercial-change-proposal.json](ASCPreparation/2026-10-26/commercial-change-proposal.json) records the actual/target Poland prices and exact monthly price point. It prepares **FREE_TRIAL / THREE_DAYS /1period** for both products, without inventing storefronts, dates or annual sale availability. Poland-only CLI dry runs succeeded; their `created:1` counts describe proposed actions, **not real Apple offers**. Annual99.99 already matches and needs no price rewrite.

Owner must approve the monthly14.99→12.99 Poland change, trial storefronts/start/end dates and annual availability scope. No price equalization, offer creation, grace change or sale activation was performed. Intro eligibility remains Apple-controlled once configured: one introductory offer per subscription group. Same-feature durations belong at the same level. [Apple introductory offers](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions), [subscription levels](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/).

## Fresh tests and build

| Check | Result |
| --- | --- |
| Source inventory/static validation | **PASS** —143methods; no methods/plans removed or skipped |
| Fresh native VeilCommerce | **FAIL:22/23passed,1failed,0skipped**, `/tmp/veil-asc-annual-commerce-20261026/Tests.xcresult` |
| Included free-export UI / annual migration coverage | **PASS** —all5UI cases; two-successful-export/third-paywall, failures/cancelled share/deniedPhotos, completed share, large-text/light paywall, real annual trial/unlimited/restart. Annual native purchase/restore/shared-group eligibility and new obsolete-product assertions passed |
| Monthly renewal case | **FAIL** —unchanged `testMonthlyTrialRenewalCancellationAndExpiration` exceeded existing10s wait for paid renewal update. No timeout/assertion change or skipped case. Not attributed to annual migration without evidence |
| Postmortem diagnosis | **UNKNOWN cause** —preserved native logs separate an earlier finish-after-delete404 from the later renewal. Test iterator initialized before forceRenewal; subsequent native status activity exists, but a signed second monthly transaction reaching the test is not demonstrated. Independent CTO review found no identified infrastructure cause, so repository policy does **not** permit a diagnostic rerun. No rerun performed; original failure remains |
| iOS arm64 Release build | **PASS**, version1.0/build5, actual Xcode project. Unsigned generic iOS build, **not** distribution archive/signature/export/upload validation |
| Release test isolation | **PASS** —no debug photo fixtures/analyzer, local `.storekit`, commerce launch overrides or StoreKitTest linkage |
| Screenshot validation / upload dry run | **PASS locally/read-only** —six files; not Apple asset delivery/upload acceptance |

[Current test summary](ASCPreparation/2026-10-26/commerce-test-summary.json), [sanitized renewal diagnosis](ASCPreparation/2026-10-26/monthly-renewal-diagnostic.json), [Release artifact/hash](ASCPreparation/2026-10-26/release-build-summary.json). The historical135/135 split-runtime pass and separate125/135 full Integration failure apply to the previous SKU revision; neither is relabeled as a fresh passing suite for this change. No full Integration rerun or new physical/Sandbox test was claimed.

## Signing, TestFlight and App Review blockers

- **App signing team comparison PASS:** plist-parsed Debug/Release team matches the live development certificate OU and BundleID prefix. The certificate fingerprint has an existing local signing identity. An initial regex comparison was invalid because project.pbxproj is XML; that false mismatch was corrected before any signing edit. No signing settings changed.
- Apple API returned1development certificate, **0distribution certificates and0provisioning profiles**. Local keychain returned1development and0distribution identities. Distribution/archive/Organizer validation remains **NOT VERIFIED**; do not create certificates/profiles or upload/distribute without the existing owner approval. Four test targets have no explicit team, preserving the prior physical-test provisioning gate.
- No uploaded build, beta groups or attached processed build. Commercial TestFlight readiness remains **BLOCKED**, independently of successful unsigned compilation.
- Final strict/deep ASC validation fails; machine-readable error IDs/counts are in the sanitized audit. Missing keywords/supportURL, primary category, content-rights declaration, Review details/contact, copyright, processed build, app pricing/territory availability, screenshots, age-rating fields and Privacy URL remain. Intended products additionally lack AppReview screenshots/annualavailability; obsolete-group warnings are not a reason to mutate it.
- **NOT VERIFIED:** PaidApps agreement, banking/tax, DSA status and published AppPrivacy. Account health explicitly reports required agreement status unavailable through current public API. No cached Apple web session exists. No interactive login, session extraction or agreement/privacy publication was attempted.
- Public legal/controller/contact facts remain missing; `VeilPublicLinks` stays unset and production purchase is correctly blocked. The Cloudflare package is explicitly review-only. Owner must finalize/publicly publish legal pages through separately authorized work, then configure real approved app/ASC URLs and reconcile actual release-scope privacy/manifest declarations. No fake URL or legal identity inserted.
- Owner legal answers are still needed for content rights, age rating, encryption/export classification and review contact. API capability does not supply missing facts. AppReview3.1.2 ongoing-value/cross-device/legal disclosure requirements still need real commercial/Sandbox/device validation and Apple's review. [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/).
- Physical-device, Apple Sandbox, cross-device/reinstall, VoiceOver/mobile48MP, default full-Integration OCR runtime issue and README's V4 physical/configured-backend owner gate remain open. No provider activation or V4 acceptance waiver.

## Remaining approvals / next actions

1. Approve exact proposed English copy. Confirm image/likeness rights and final six screenshots/captions before upload. Existing live text stays until then.
2. Approve commercial changes with territories and dates: Poland monthly12.99 target, annual availability and three-day offers. Existing99.99 annual price stays; no automatic global equalization.
3. Supply legal/public endpoints, identity/contact and applicable legal/privacy/export/age/content-rights attestations; verify agreements/tax/banking/DSA in Apple systems.
4. Resolve the monthly native renewal test failure with evidence; do not retry to obtain green. Complete physical/Sandbox/cross-device and V4 acceptance.
5. Approve any necessary distribution provisioning/certificate work and a concrete signed archive/TestFlight upload/distribution only when gates are met. No review submission/publication is authorized.

Root acted as Engineering Lead, sole ASC mutator/native runner. CTO provided the architecture gate, independent code review and native-log causal review. Presentation reviewer audited prior metadata/asset/legal evidence. No nested agents, new dependency, tracking, backend or production service. [ADR010](../Engineering/Decisions/010-annual-product-identifier.md) records decisions; raw credentials, cert/account data and receipt logs are excluded from committed evidence.
