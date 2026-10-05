# Veil V4 — App Store preparation

Draft only; no submission. V3 is approved/merged. **V4 must remain a Draft PR until physical-device and configured-backend validation.**

## Ready in code

- Bundle `com.maksym1503.veil`, display Veil, iPhone/iOS 17+/portrait, existing opaque icon and native launch. V4 sets marketing version 4.0/build 4; confirm the intended public version before uploading. Owner DEVELOPMENT_TEAM remains local.
- No login wall. PhotosPicker selection-scoped import needs no broad Photos read permission. Save to Photos invokes `.addOnly`, with English/Polish `NSPhotoLibraryAddUsageDescription`; denied/restricted states retain local save/Share.
- Gaussian/Pixelate/Solid and region masks use one preview/export renderer. Face analysis reads the normalized original, independent of viewport. Documents uses on-device Vision; OCR strings do not persist/upload/log.
- Explicit local history: protected processed JPEGs/thumbnails, versioned metadata, backup exclusion, file deletion and failure-safe corrupt/unknown-schema handling. No sensitive original cache. Temporary share cleanup on dismissal/next launch.
- Optional Supabase Auth SDK with device-bound Keychain, native Apple nonce-bound token exchange, Google OAuth/PKCE with exact callback validation. Private SQL/Storage ownership policies, retryable local-first sync and server account-deletion/revocation code supplied. **External setup/live integration remains required.**
- Settings includes account/sync, storage count/usage, independent local/cloud deletion. Privacy copy distinguishes local processing from optional cloud uploads and does not claim end-to-end encryption.
- PrivacyInfo manifest conservatively declares optional account user ID/name/email and synced photos as linked-to-user, app-functionality collection, never tracking. No new app/Auth-product required-reason API use identified; Swift Crypto supplies its own manifest. Final archive privacy report still required.
- Adaptive native tool menu at accessibility text sizes, labeled controls, neutral detection vocabulary and minimum touch targets. V3 landing Reduce Motion/Transparency behavior retained. App-switcher shielding added; physical snapshot/VoiceOver review required.
- Release excludes all test JPEG fixtures and DEBUG fixture/evidence/history-reset logic. Unsigned build/tests do not validate distribution signing or provider entitlement correctness.

## Needs developer input / release gates

- Complete [backend setup](../Backend/BACKEND_SETUP.md): project/region, private bucket, migrations, provider IDs/secrets, Apple capability/provisioning, redirects, function deployment, two-account API isolation and deletion/revocation validation. No backend has been provisioned or deployed by this work.
- Publish reviewed Privacy Policy, optional Terms and usable support contact/URL; fill `VeilPublicLinks`. Confirm legal owner, jurisdiction, lawful basis, processors/DPA, cross-border transfers, retention/backups/tombstones/orphan cleanup, privacy-request process and support website practices. Drafts are not legal advice.
- **Replace V3's “Data Not Collected” answer.** A cloud-enabled V4 distribution needs App Privacy disclosure for account user ID, name/email and user photos, linked to identity, App Functionality, no tracking. Confirm actual managed-service logging/security data and any additional category with the configured deployment. Optional collection still belongs in the distributed app's answers.
- Confirm public version/build, App Store name/category, pricing/territories, age rating, rights, distribution signing, Xcode Validate App and privacy report. Do not commit a team or secret.
- Give App Review working backend/provider access/instructions. Core editor works without login; Account is in Settings; sync defaults off and needs consent. Delete account is inside Account. Provide a reviewer test account where appropriate; do not put its credentials in the repository. Explain add-only Photos use, no Photos/Drive account scope, no universal document detector and no card-compliance certification.
- Complete [physical-device checklist](../QA/V4/PHYSICAL_DEVICE_CHECKLIST.md), VoiceOver/largest text, older supported iOS/device, real Background Vision, distant faces, rotated/multi-country documents, JPEG metadata behavior, 12/48 MP memory/latency, app-switcher snapshots and configured cloud/offline lifecycle.
- Screenshots must show actual app behavior with approved/licensed photos. Keep cloud claims/screenshots unavailable until configured and tested. Never represent fixture recall as guaranteed detection.

## References
[Apple Photos picker](https://developer.apple.com/videos/play/wwdc2023/10107/), [manifest data types](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype), [required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [Apple deletion/revocation](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple).
