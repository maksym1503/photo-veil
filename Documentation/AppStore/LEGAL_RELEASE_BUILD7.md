# Legal publication and release build1.0(7) — 2026-10-28

**PASS — legal site published and verified; build7 is available for existing internal TestFlight testing. NEEDS OWNER ACTION — App Review preparation remains blocked by Apple declarations/contact fields and physical-device acceptance. No public review or release performed.**

## Completed

The owner deployed the approved publication ZIP to the separate Veil Cloudflare account. Verified deployment `2414be66-2ee4-4160-b848-e51d0e5a68c0` succeeded at `veil-legal.pages.dev`. Privacy, Terms, Support and home responses match approved files exactly. Public personal details are only **Maksym Bilyi, Poland, veil.app.support@proton.me**. No address, phone, personal Gmail or unrelated domain was published. No custom domain or paid service added; no analytics configured.

- Privacy: https://veil-legal.pages.dev/privacy
- Website Terms: https://veil-legal.pages.dev/terms
- Support: https://veil-legal.pages.dev/support
- App Terms remain Apple's Standard EULA.

App Store Connect en-US Privacy and Support URL fields were saved and read back. App Debug/Release build settings now contain those real HTTPS URLs and build number **7**. Bundle ID, signing team, existing functionality, default Keep metadata, processing/export behavior, two-free-export policy, subscription prices and trader classification are unchanged. Advertising remains disabled in the signed binary.

The production legal gate derives permission from validated bundled Privacy and Terms links; those links now exist. Missing-link denial remains separately tested. No test-only purchase override was added to Release. Actual purchase access still depends on StoreKit products and verified transactions.

ASC copyright is `2026 Maksym Bilyi`; release mode is **MANUAL**. Both intended products remain in Photo Privacy Pro: monthly `vail.pro.monthly` **12.99 PLN**, annual `vail.pro.annual` **99.99 PLN**. Fresh Poland offer reads verify FREE_TRIAL / THREE_DAYS / one period from2026-10-26. Both were READY_TO_SUBMIT before draft staging. Six listing screenshots read back COMPLETE; subscription validator returned zero errors. Optional promotional-image warnings and obsolete unused yearly resources remain; no products/groups deleted or commercial settings changed.

## Signing, build and upload evidence

- Release archive: `/tmp/veil-legal-build7-1.0-7.xcarchive` — **PASS**.
- Distribution IPA: `/tmp/veil-legal-build7-export/Veil.ipa` — **PASS**.
- Signature, App Store provisioning and release resource guard — **PASS**.
- Signed Info.plist verifies version1.0/build7, correct bundle, public URLs, `ITSAppUsesNonExemptEncryption:false`, no enabled advertising configuration. App privacy manifest collection array remains empty; backend configuration absent.
- Apple IPA validation — **VERIFY SUCCEEDED with no errors**.
- Upload/build ID: `f12ba272-cd8f-45b5-9705-80428ebf84af`; upload completed; processing **VALID**.
- Read-back internal state: **IN_BETA_TESTING** in existing **Veil1.0 Internal Acceptance**, group `8928356b-d0e7-4cdc-9ba4-48ce173822a6`.
- en-US What to Test notes saved; build7 attached to version1.0. No new testers invited, external beta review submitted, or public distribution initiated.
- Reused existing identity/profile/keychain. Temporary signing overrides restored, keychain search list restored, dedicated keychain locked, temporary recovered password removed. No credentials in repository or public site.

## Tests and failures, accurately scoped

- Legal packaging/source tests **11/11 passed** in the preceding publication preparation; source/public files unchanged afterward. Not repeated unnecessarily.
- Live HTTP: four200 responses, correct404, redirects/internal and Apple links, approved byte hashes and configured headers — **PASS**.
- Actual WebKit rendering: **16/16** combinations at320/390px, light/dark, plus200% text stress, named controls,44px navigation and skip-link DOM focus — **PASS**. See [live QA report](CloudflarePages/2026-10-28-live-qa/QA_REPORT.md). HSTS was absent; HTTPS and HTTP→HTTPS redirect work. Physical keyboard and assistive-technology traversal are NOT VERIFIED.
- Commerce initial updated run: **22/23 passed,1 failed,0 skipped**. Native StoreKit **8/8**, quota **10/10**, UI **4/5** passed. Failed case was the new Privacy UI assertion querying a native SwiftUI action specifically as an XCUIElementTypeLink.
- Corrected only that test query to the named native accessibility action and retained enabled-state assertion. Focused rerun of the entire affected two-free-exports/third-paywall/restart/gallery case: **1/1 passed**, zero failures. Together, all23 distinct commerce cases have passing evidence; do not describe the original full run as green. The other22 successful cases were not repeated.
- An earlier test build failed because a new test referenced a UI type excluded from its app-hosted target. Corrected to inspect the actual host bundle's legal URLs. Product code was unaffected. Both original failures are preserved in `/tmp/veil-legal-build7-commerce*` logs/results.
- `git diff --check` — **PASS**.
- Full PR/SwiftPM/export regression suites were not rerun: rendering, metadata, gallery and monetization implementation did not change. Earlier genuine evidence remains historical. Physical iPhone, real Apple Sandbox, cross-device and V4 owner acceptance are NOT VERIFIED in this continuation.

Native evidence: `/tmp/veil-legal-build7-commerce-corrected/Tests.xcresult`, `/tmp/veil-legal-build7-focused-ui.xcresult`. Sanitized reports and actual paywall screenshot: [LegalRelease evidence](Evidence/LegalRelease-2026-10-28/validation-results.json). [TestFlight readback](Evidence/LegalRelease-2026-10-28/testflight-readback.json).

## First subscription review preparation

Created unsubmitted draft `e4273c34-de0d-42f9-8686-ae0e2c8b8212`, currently READY_FOR_REVIEW (draft state, not submitted). Added group version `dca369ae-f256-4d45-9c55-ef773f02695b`, monthly version `00f509c8-fa70-4513-8aa8-ac20d5c1f76b`, annual version `a1eeb33f-858b-48f3-a406-84aa5b6a839a`. Apple blocked adding app version1.0 because of unpublished App Privacy answers, missing App Review contact fields and missing content-rights declaration. No submit command was called. First subscriptions and their group require the new app version in the same submission: [Apple instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).

Final ASC validation has5 errors: contact first name/last name/email/phone and content rights. Privacy URL, Support URL, copyright, attached build and screenshots are no longer errors. Separately, the attempted app-version draft addition conclusively reports unpublished App Privacy answers. Public API cannot publish those answers. No Apple web session is authenticated; do not confuse missing independent web verification with revoked owner confirmations.

## Short owner checklist

1. Install **1.0(7)** from the existing internal TestFlight group. Test real Sandbox trial/purchase/restore, restart/cross-device access and exported pixels/metadata with non-sensitive photos; follow the existing physical-device protocol. No production payment needed.
2. App Store Connect → app → **App Privacy**: review and publish truthful answers. Signed local-only build has no configured backend, live ads, tracking or developer telemetry; engineering recommendation remains **Data Not Collected** for the app. Website/support correspondence is separately disclosed in the policy. Owner must confirm the declaration.
3. App → version1.0 → **App Review Information**: enter private reviewer first/last name, monitored email and real international-format phone. These are Apple review contacts; do not add them to Cloudflare. Approved name/email can be reused; no phone invented or extracted.
4. App → **App Information → Content Rights**: complete the required truthful rights attestation. It has not been inferred or signed for the owner.
5. Once these gates and physical acceptance are complete, add app version1.0 to the existing draft containing Photo Privacy Pro and both plans; refresh saved review notes. Final Submit for Review still requires separate owner authorization. Do not submit the subscription-only draft as the first release.

Paid Applications Agreement accepted, DAC7 completed and DSA Active are explicitly owner-confirmed. No repeat legal-content or deployment approval is required. App Store/public release remains **NOT READY** until the documented gates close; internal TestFlight availability is **PASS**.

Root implemented configuration/release automation; independent CTO reviewed source/gates/publication isolation; separate QA verified live HTTP/mobile screenshots. No unrelated design/architecture changes.
