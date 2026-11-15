> Current owner confirmations (2026-10-28): public publisher Maksym Bilyi, Poland; Support/Privacy veil.app.support@proton.me; final legal content and Cloudflare publication explicitly approved. The deployed pages have been verified at https://veil-legal.pages.dev/privacy, /terms and /support. Owner reports the new Paid Applications Agreement accepted, DAC7 completed and DSA Active. These replace historical requests below for identity/email, publication approval and public URLs; do not request those approvals again. No residential address or telephone was approved for Cloudflare publication, and Apple trader classification has not been changed. App Review private contact fields, content-rights attestation, App Privacy publication and physical-device/Sandbox acceptance remain separate gates.

# Owner-only facts and attestations still needed

The commercial approval is complete and already applied: approved monthly and
yearly price schedules, plus the three-day introductory offer for 175
storefronts beginning 2026-10-26 with no scheduled end date. **Do not request
that approval again.** This document lists only the remaining owner/legal
decisions and facts. Keep private identity and contact values out of the
repository; enter them in the owner-controlled App Store Connect or hosting
forms.

## Required owner inputs

1. **Publisher identity and monitored contact.** Confirm the legal seller and
   privacy controller name, any address required for the public policy and
   storefront, and dedicated public privacy/support emails with honest support
   availability. Supply the required monitored App Review contact name, email
   and phone directly in App Store Connect. None has been supplied in source.

2. **Public policy site.** Choose the owner-controlled HTTPS origin and host;
   verify processing-region/transfers and request-log retention from the real
   host configuration. Review the effective date, jurisdiction/consumer-rights
   language, privacy-request handling, and actual retention policy for local
   gallery files, temporary share files, and the device-only export-count
   Keychain record. Temporary-file cleanup runs at share completion or a later
   launch; app termination can delay it. Keychain state may survive app
   removal. The current review ZIP is visibly draft-only and has not been
   published. The app's Privacy Policy URL is unset and blocks purchases.

3. **App Privacy questionnaire.** The signed local-only archive contains an
   empty `NSPrivacyCollectedDataTypes` array. Technical recommendation for this
   release configuration: **Data Not Collected**, because photo selection,
   OCR/detection, editing and exports remain on-device; there is no configured
   Veil backend/account in the archive; the free-export count is a device-only
   Keychain record without a photo, account or user ID; and Apple processes its
   own StoreKit transactions. Confirm this against every embedded SDK/privacy
   manifest and the exact enabled archive, then enter the answers in App Store
   Connect. This is an engineering recommendation, not an owner declaration or
   legal certification. Reassess if backend/account features are enabled.

4. **Export compliance.** Technical inventory for the local-only archive:
   platform HTTPS/TLS, iOS Keychain and file-protection services, plus
   Apple CryptoKit SHA-256 hashing for nonce/fingerprint uses; the inspected
   application does not implement its own encryption algorithm. The
   `ITSAppUsesNonExemptEncryption` key is not set in the app plist. Owner must
   answer Apple's current export-compliance questions for this exact build and
   determine whether any export-compliance documentation or declaration is
   required. Do not treat this inventory as an exemption decision.

5. **EU trader and agreements.** Decide trader/not-trader status for the
   applicable EU workflow. If trader, provide verified public trader name,
   address, phone and email in App Store Connect. The account owner must
   verify current Developer Program/Paid Apps agreement acceptance, banking
   and tax readiness, and any applicable DSA workflow directly in Apple’s
   systems; API availability does not prove acceptance.

6. **Other required App Store attestations.** Review the already-filled factual age-rating draft and configured category/territories; confirm the copyright/seller field, content-rights declaration and final required review fields using verified facts. Supply
   review contact in App Store Connect. A production-signed archive and valid
   IPA do not satisfy these owner attestations or authorize public distribution. Internal TestFlight preparation/upload is separately authorized by the current task.

## Confirmed boundaries

- Apple's Standard EULA is the current app Terms URL and is the selected
  standard agreement; the old live `endUserLicenseAgreement` value was null.
  No custom EULA text is requested.
- Cloud/account sign-in is unavailable in the current local-only archive. Do
  not publish cloud-provider, sync, retention or account-deletion claims for
  this release.
- Prices and introductory-offer setup are already owner-approved/applied as
  stated above. StoreKit supplies localized prices, and trial visibility still
  depends on Apple's offer availability and eligibility response.
- TestFlight and App Review notes below are drafts. Do not paste private owner
  contact data, invent reviewer credentials, publish the policy ZIP, or infer
  release authorization from archive validation.
