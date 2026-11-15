# Legal-site source facts and owner inputs — 2026-10-26

This is an engineering fact audit of the current local-only app and the static
legal-site draft. It is not legal advice or an owner attestation. Product
statements below were checked against this checkout's source, build settings,
App Store metadata draft, and local StoreKit test configuration. Production
App Store product settings and owner/legal facts are called out separately.

## Verified product facts for the current local-only release

| Topic | Source-backed fact | Safe wording boundary |
| --- | --- | --- |
| Photos | A person chooses an image through Apple's system photo picker. Editing creates a new JPEG; the selected original is unchanged. Save to Photos requests add-only access when chosen. | Do not imply Veil has broad photo-library read access or that third-party sharing destinations follow Veil's policy. |
| Processing | Face, plate, document and text analysis use on-device Vision; recognized text is used during detection and is not saved by the app. Image rendering, metadata processing and watermarking are local. | Say “in this local-only release.” Do not promise that a photo can never leave the phone after an explicit save/share action. |
| Redaction limits | Detection can miss areas or include unrelated content. Blur/pixelation are not anonymity guarantees. Solid Redact is available. | Describe detection as suggestions; never promise anonymity, compliance, or complete coverage. |
| Metadata | Keep is the new-photo default; it carries supported metadata. Remove omits supported source location, date/time, camera/device, descriptive metadata, comments and previews. JPEG re-encoding rebuilds technical fields and cannot preserve every source tag. | Keep or Remove applies to the processed copy, not the original. Do not promise complete removal or exact preservation. Receiving apps may add their own fields. |
| Watermarks | Custom watermark text is session-only before export; the visible mark becomes image pixels in saved/shared output and thumbnails. It can be cropped or changed. | It is a visible usage cue, not proof of authenticity or protection from misuse. Avoid claiming reusable templates. |
| Local gallery and temporary sharing | Save to Veil stores processed images and thumbnails in protected app files excluded from backup. Share uses temporary processed JPEG storage with cleanup after sharing closes or at a later launch. | Exact deletion/retention periods are not source-backed. App termination can interrupt temporary-file cleanup. |
| Free exports and Pro | Two successful Save/Share outputs are free; editing/preview are free; failed/cancelled outputs do not count. Monthly and yearly StoreKit plans provide the same unlimited protected-export entitlement. | Do not say “two photos”; count is successful output operations. Keep prices localized and StoreKit-driven. |
| Introductory offer | UI advertises a three-day free trial only when StoreKit reports a configured free three-day introductory offer and Apple says the person is eligible. The local `.storekit` file has a three-day test offer. The coordinator reports that owner-approved production offer setup has now been applied, starting 2026-10-26 to 175 storefronts with no scheduled end date. | Use conditional wording: availability and eligibility are storefront/group-specific. Do not repeat a commercial approval request; no fixed localized price is hardcoded in this site. |
| Accounts and cloud | `Configuration/VeilBackend.plist` is absent in this checkout, and the build script omits the resource when absent; app code then creates no account client. The current public Terms URL is Apple's Standard EULA; Privacy Policy and Support URLs remain unset. | Describe this build as local-only and cloud/account sign-in as unavailable. Do not publish optional-cloud collection, provider, retention or deletion claims for this release. |
| Payments and terms | Apple processes subscription payment. The app checks StoreKit entitlements. App purchase availability is gated on both a Privacy Policy URL and a Terms URL. The current `VeilPublicLinks.terms` points to Apple's Standard EULA; the Privacy Policy URL remains unset, so purchases are blocked. | Do not imply purchases are currently available in the configured release. Keep purchase policy tied to the final submitted build and App Store settings. |
| Analytics/tracking | The app information copy states no Veil analytics/tracking; no analytics/tracking SDK was found in the inspected project dependencies or source. | This source inspection is not a third-party SDK or final binary privacy audit. |

The approved production monthly and yearly price schedules are applied; do not
request commercial re-approval. Apple's Standard EULA endpoint is the app's current public Terms link and the
App Store Connect `endUserLicenseAgreement` field was reported as `null` by the
2026-10-26 live API audit, which means no custom EULA is set there. The legal
site therefore links Apple's Standard EULA rather than collecting custom
license text. Apple Support's [subscription cancellation guidance](https://support.apple.com/en-us/118428)
supports the linked account-settings instructions. Both direct Apple links are
the only external navigation allowed by the static-site validator; they are
not page assets, scripts, fonts, or embeds.

## Privacy manifest status and App Privacy confirmation

The current local-only `PrivacyInfo.xcprivacy` declares an empty
`NSPrivacyCollectedDataTypes` array and no tracking. The prior four account,
identity and photo declarations are preserved in
`Documentation/Architecture/Privacy/OPTIONAL_CLOUD_MANIFEST_HISTORICAL.xcprivacy`
for historical reference only; that file is not the current target manifest.
The Release guard requires a present, parseable manifest and refuses an empty
collection declaration when `VeilBackend.plist` is bundled. It also refuses a
missing or malformed manifest. This guard checks configuration shape, not
privacy-law compliance.

The coordinator reports a production-signed archive, exported App Store IPA,
and Apple's package validation passing with the local-only manifest. That
resolves the previous source/archive mismatch concern for this release
configuration. Before submission, the owner must still answer App Store
Connect's App Privacy questionnaire against the exact archive and all embedded
SDK privacy manifests. The technical recommendation for this local-only
configuration is **Data Not Collected**: image selection, recognition,
processing and export stay on-device; no Veil account/cloud backend is
configured; and the device-only export counter is a Keychain record without a
photo, account or user identifier. Apple StoreKit payments are handled by
Apple. Confirm this recommendation against the final enabled features and
binary; it is not a legal certification or a declaration already submitted to
App Store Connect. If account/cloud features are later configured, perform a
fresh manifest, SDK, data-flow and privacy-questionnaire review. Do not copy
the historical cloud declarations into a local-only release manifest.

## Still required from the owner/legal reviewer

The app-content facts above do not supply a legal identity or public contact.
The publication builder remains fail-closed. It needs the following verified
inputs before a publication package can be produced:

- A real public HTTPS site origin and an explicit owner publication approval.
- Legal entity/provider name, effective date, public postal address, public
  support and privacy email addresses, and support availability.
- Reviewed governing-law/jurisdiction and rights language; reviewed consumer
  rights wording; and the actual local-data retention and privacy-request
  handling policies.
- Actual website host/provider and processing-region details, plus website
  request-log retention. The site is only prepared locally; no host is
  configured or deployed by this work.
- An owner determination of EU trader status. If the owner determines trader
  status applies, verified trader name, address, telephone and email are also
  required.

The Terms page now links Apple's Standard EULA, so no custom license grant or
additional license placeholder is requested. The `terms_consumer_rights`
owner field remains required; this change does not invent consumer or
jurisdiction language. Cloud is explicitly disabled for this draft. Enabling
cloud claims remains blocked pending the separate backend/privacy review and
verified provider, region, subprocessor, log, backup and deletion facts.

No owner facts, contact details, retention periods, hosting claims, trader
status, privacy URL, custom EULA, or App Store privacy declarations were
invented or published here. A generated review package remains visibly marked
as draft and is not authorization to upload or deploy it.

## Final linked-crypto inventory

The exact signed build 1.0 (5) links the system CryptoKit and Security frameworks. `nm` found no BoringSSL/OpenSSL-named symbols in the app executable; absence of those names is not a general cryptographic proof or export exemption. The archived Info.plist still has no `ITSAppUsesNonExemptEncryption` answer. See [sanitized inventory](AutonomousRelease/2026-10-26/linked-crypto-inventory.json). Classification and any binding declaration remain owner actions.
