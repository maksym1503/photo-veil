# Contextual sponsorship — build 1.0 (6)

**Prepared, not activated.** This binary contains no ad SDK, provider/account identifiers, inventory endpoint, live creative or third-party ad request. All placements collapse when unconfigured. No privacy declaration is changed to claim hypothetical collection. Two successful free exports and existing subscriptions are unchanged.

## Chosen boundary

Native text banners on the empty foreground home only. No interstitial, rewarded, gallery, editor, picker, export or paywall ads. Pro, trial and grace are ad-free; unknown, busy, loading, failed/unverified or conflicting subscription snapshots are also ad-free. An epoch rejects stale verification; presentation generations reject stale inventory responses after navigation, backgrounding, consent withdrawal or Pro changes.

The optional first-party URLSession adapter accepts a fixed approved public JSON endpoint, not a photo/context payload. Ephemeral networking has no cookie, credential or URL cache storage; HTTPS same-origin redirects, an8KiB stream limit and strict text/URL schema are enforced. No remote images/scripts/web views, tracking IDs, ATT prompt, analytics or impression/click beacons. Syntactic URL screening is not DNS/private-network isolation; endpoint ownership remains essential. Destination navigation occurs only on an explicit user tap in the system browser.

Non-personalized AdMob was researched, not integrated: it still uses identifiers/storage for some reporting and requires consent tooling; an in-process SDK also cannot be proved unable to inspect app memory merely because no photo is passed. A new SDK/provider would require renewed source, data-flow, consent and encryption review.

## Required before activation

1. Approve a real contextual inventory/direct-sponsor provider, its content rights/age appropriateness, logging/retention/transfers, legal basis and privacy terms. The current adapter is for an approved public native creative feed; it is not an undocumented AdMob API. No external account is registered or terms accepted.
2. Publish the approved app Privacy Policy and Support page. Supply their real HTTPS URLs through `VEIL_PRIVACY_POLICY_URL` and `VEIL_SUPPORT_URL` app build settings; defaults are empty. Verify actual public200 responses, correct brand/content and absence of draft banners/placeholders. Terms uses Apple's real Standard EULA.
3. Review App Privacy, manifest collection categories and policy text against the actual provider. The Release guard rejects enabled advertising with an empty collection declaration, absent review flag or missing public URLs. Do not invent categories to pass it; review the guard if verified provider practices require a different declaration.
4. Add a bundled `VeilContextualAdvertising` Info.plist dictionary with real values: `Enabled`/`PrivacyReviewApproved` booleans, `InventoryURL`, `ProviderPrivacyURL`, `ReportURL`, `ProviderDisplayName`, and `DisclosureVersion` (`2026-10-v1`). No secret API key belongs in the app. No sample production values are supplied. A new reviewed binary is required; the feature cannot be remotely enabled in build6.
5. User-initiated Sponsor privacy explains the named provider, fixed context and IP/standard request data. Unknown/declined consent never requests inventory; only the matching explicit grant permits a request. Choice is memory-only and can be withdrawn. If the selected service requires a certified CMP or additional choices, implement that before activation; the native opt-in is not a universal CMP substitute.
6. Validate real delivery/no-fill/offline, report/why-this-ad, maximum text sizes, foreground external purchase and Pro restoration on a device. Do not activate until all provider/legal conditions are satisfied.

Inventory response has exactly five string fields: `advertiser` (max80UTF-8 bytes), `headline` (max120), `callToAction` (max32), `destinationURL`, `reportURL`. Report must match the configured report URL; privacy comes only from the approved config. No query credentials/tracking, userinfo, unsupported schemes or private/literal/reserved hosts. Unknown schema keys and oversized/invalid responses yield no ad and no error UI. Provider/transport failure never blocks editing.

## Official references

- [Apple advertising/review requirements](https://developer.apple.com/app-store/review/guidelines/) — advertising disclosure, targeting information and inappropriate-ad reporting.
- [Apple tracking rules](https://developer.apple.com/app-store/user-privacy-and-data-use/).
- [Google ad-serving modes](https://developers.google.com/admob/ios/privacy/ad-serving-modes) and [SDK data disclosure](https://developers.google.com/admob/ios/privacy/data-disclosure).

The current disabled, SDK-free build does not make advertising compliance claims for an unchosen future provider. Existing legal-site drafts remain unpublished; no personal contact details were inferred.
