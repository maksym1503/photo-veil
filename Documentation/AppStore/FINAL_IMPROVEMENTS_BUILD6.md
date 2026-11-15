# Focused final improvements — 2026-10-27–28, build 1.0 (6)

Current app: Blur, Watermark & Metadata / Veil, `com.maksym1503.veil`, app6822230720. Preserve the earlier release history; this report covers only the focused follow-up. No public App Review, external beta review, provider registration, agreement acceptance or legal-site publication.

## Implemented

- Home illustration: removed the PRIVATE COPY overlay entirely; no replacement label because the existing headline already names watermarking. Existing portrait, gradient, blur and map retained. A shared two-state phase now starts blur and location removal together; automatic easing0.7s (was1.2), first transition0.9s (was1.2), cycle2.2s (was2.6), manual0.4s. Caption stays crisp rather than crossfading overlapping text; map motion remains synchronized. Tap/haptic, static Reduce Motion and accurate accessibility value preserved.
- Advertising: native, contextual text-banner infrastructure only on empty foreground home. No ad SDK, identifiers, cookies, credential/cache storage, remote scripts/images or analytics; no photos/metadata/OCR/account/export payload in the provider interface. Native explicit consent/decline/withdrawal, Why this ad and Report controls are prepared. Main-actor generation/cancellation rejects stale loads; verified-free classification also rejects stale or uncertain StoreKit scans, foreground changes and conflicting active/grace status. Pro/trial/grace, busy/restore, editor, picker, gallery, settings, export and paywall are ad-free. Two free successful exports unchanged.
- Advertising is **inactive**: no approved provider/feed or public privacy/support configuration exists. No ad requests, prompts or empty slot are shown. No fake production credential or ad campaign was supplied. [Provider/setup requirements](CONTEXTUAL_SPONSORSHIP_SETUP.md) distinguish a direct approved native feed from services requiring their own SDK/CMP.
- Privacy Policy cause: source hardcoded nil; live ASC Privacy/Support URLs are also nil, and the owner legal config is absent. Added validated `VEIL_PRIVACY_POLICY_URL` / `VEIL_SUPPORT_URL` build settings, expanded into Info.plist and read by public-link configuration. Missing policy has truthful awaiting-publication text; Terms still opens Apple Standard EULA. Purchasing remains gated until a real approved policy is published/configured. Draft pages were not uploaded or published.
- Build6 uses the existing owner-confirmed build5 Apple-system-only encryption classification (`ITSAppUsesNonExemptEncryption=false`), approved by CTO after live readback. No new crypto dependency. Signing uses the existing Distribution identity/profile; no new identity was created.

## Architecture and review

[ADR-012](../Engineering/Decisions/012-contextual-sponsorship-boundary.md) records the provider/consent/data boundary and owner gates. Root implemented integration and QA; developer (`gpt-6-luna`) implemented core/tests and the screenshot composition; independent CTO/reviewer (`gpt-6-astra`) reviewed architecture, source/races and actual native screenshots. Three review findings—stale verification, foreground reuse and conflicting Pro snapshots—were corrected and regression-tested before upload. Export-access semantics were not changed. The broad pre-existing working tree/signing work is preserved; no destructive Git operation or merge.

Source areas: `ContextualAdvertising.swift`, `HomeSponsorshipBanner.swift`, ad-only readiness in `VeilSubscriptionStore.swift`/scene lifecycle, `VeilPresentation.swift`, picker visibility in `PhotoVeilHome.swift`, legal status in `VeilSubscriptions.swift`; focused tests/inventory/PR membership, public build settings and Release isolation guard. No new third-party dependencies, tracking or backend.

## Actual validation

| Check | Result |
| --- | --- |
| SwiftPM | PASS:91 executed,2 opt-in profiles skipped,0 failures (89 regular passes); `/tmp/veil-final-polish-swiftpm-final2.log` |
| Final ad eligibility/epoch tests | PASS:7/7; `/tmp/veil-final-polish-ads-definitive.log` |
| Native PR | PASS:94/94,0 failures/skips; `/tmp/veil-final-polish-pr/Tests.xcresult` |
| Native Commerce | PASS:23/23,0 failures/skips; `/tmp/veil-final-polish-commerce/Tests.xcresult`, including actual local trial/restored/grace Pro ad-suppression assertions |
| Focused native UI | PASS:3/3, screenshot/export journey, picker without broad Photos read permission, hero cycle/tap; `/tmp/veil-final-polish-ui/Tests.xcresult` |
| Final large-screen hero | PASS:1/1; `/tmp/veil-final-polish-large-home.xcresult`; actual final screenshot reviewed in light appearance, earlier compact dark screenshot reviewed |
| Inventory/whitespace | PASS:150 Swift methods; all previous tests retained,7 added; `git diff --check` |
| Signed Release archive/export | PASS: `/tmp/veil-final-polish-1.0-6.xcarchive`, `/tmp/veil-final-polish-export/Veil.ipa`; signature/profile/resource guards passed |
| Final artifact | PASS:build6, correct bundle, no ad configuration/SDK/backend/test fixtures/StoreKitTest, empty public policy/support settings, empty collection array/trackingfalse, system CryptoKit/Security unchanged |
| Apple IPA validation | PASS:VERIFY SUCCEEDED with no errors |
| Live-ad Release privacy guard | PASS: temporary copied artifact with Enabled advertising and empty collection declarations was rejected; signed original unchanged |

Initial new-test compile and inventory/source-membership issues were corrected before the passing runs. No failed native functional case was retried unchanged. Full142-case Integration/physical-device/real Apple Sandbox acceptance was not repeated for this focused change. Live ad delivery, an actual provider consent contract and public-host behavior are **NOT VERIFIED** because configuration/approval are absent. No physical VoiceOver or device performance result is claimed. Existing README/V4 owner gates remain.

## App Store Connect and TestFlight

Updated the home listing screenshot from the actual1320×2868 build6 capture, retaining the five other images and current caption/frame. Original native illustration has no external photo/model license dependency. Old home was removed only after new delivery COMPLETE and checksum verification; prior local source remains preserved. Current listing description/No Ads and no-collection declarations remain truthful for this SDK-free, inactive configuration; do not claim live advertising or silently change privacy answers for a future provider. Saved/read-back beta notes disclose the prepared-but-inactive module and missing public policy. The App Store version-review note update was BLOCKED by Apple requiring real contactFirstName/contactLastName/contactEmail/contactPhone; no contact was invented and the existing record is preserved. Updated local notes are prepared for later completion.

**PASS — uploaded, processed VALID and IN_BETA_TESTING**, independently read back 2026-10-28. Build/upload ID `5b4a3db1-65af-42c1-a472-e477693694b8`, version1.0/build6. Assigned only to existing internal group `8928356b-d0e7-4cdc-9ba4-48ce173822a6` (Veil 1.0 Internal Acceptance). English What to Test was saved/read back; automatic notifications are off. Owner-created membership/settings remain; no new invitations, external beta submission or public distribution. External state READY_FOR_BETA_SUBMISSION is eligibility only, not a submitted review. Encryption is false as expected from the owner-approved classification. [Actual readback](Evidence/FinalPolish-2026-10-27/testflight-readback.json).

## Required owner input before commercial activation

1. Approved, publicly accessible Privacy Policy and Support URLs plus the still-required legal/controller/contact/hosting facts. No public URL or legal identity is invented. [Legal confirmations](OWNER_LEGAL_CONFIRMATIONS.md); existing review-only Cloudflare package remains unpublished.
2. Approved contextual inventory/direct sponsor/provider and its age/content/privacy/retention/transfer terms; real feed/privacy/report endpoints. Complete actual collection disclosures and real-provider/device QA before enabling. No AdMob/other account was created.
3. Existing physical/Sandbox/final commercial acceptance and final App Review/public-release authorization. This execution performs neither public submission nor release.

## Verdict

**PASS — internal TestFlight update delivered. BLOCKED — commercial/public release and live advertising** until approved policy/support publication, provider/privacy setup and remaining owner acceptance. The current binary still has the legal purchase gate; no unapproved website was published and no App Privacy collection answer was invented. No production source edit followed the signed archive.
