> Build6 update2026-10-28: first listing screenshot replaced with the real cleaner home capture at `Screenshots/1.0-build6/en-US/listing/appstore-01-home.jpg`; all six ordered images are COMPLETE. Remaining five images/copy unchanged. Advertising is inactive, so no active-ad or changed collection claim is added. See the focused build6 report.

> Autonomous authorization2026-10-26 now approves reversible draft listing updates. English copy below was revised for clarity, factual limits and Apple Standard EULA; exact read-back is recorded in AUTONOMOUS_RELEASE_HANDOFF.md. Earlier approval-hold notes are historical.

> Verified autonomous update 2026-10-26: title, subtitle, promotional text, keywords and the description below match the English draft listing. Six original, rights-cleared running-app screenshot compositions are uploaded, ordered and delivery-COMPLETE. See [current handoff](AUTONOMOUS_RELEASE_HANDOFF.md) and its sanitized readbacks. No final App Review submission occurred.

# App Store listing — English (United States)

Prepared copy for owner review, not a submitted listing. The app’s in-app name and bundle remain **Veil** (`CFBundleDisplayName` / `CFBundleName`); the owner-approved App Store product-page name is **Blur, Watermark & Metadata**. The selected name is 26 characters (not 25), within Apple’s 30-character app-name maximum. Store metadata, commercial offers, App Review responses and legal URLs must be finalized against the live App Store Connect record before submission.

The length checks below are generated from the fenced copy by `LegalSite/validate.py audit`. Apple currently limits name/subtitle to 30 characters, promotional text to 170 characters, description to 4,000 characters, and keywords to 100 bytes. Use the linked Apple references in [APP_STORE_CONNECT_CHECKLIST.md](APP_STORE_CONNECT_CHECKLIST.md) to recheck limits before release.

## App name — 26 / 30 characters

```text
Blur, Watermark & Metadata
```

## Subtitle — 23 / 30 characters

```text
Photo privacy, your way
```

## Promotional text — 164 / 170 characters

```text
Blur or redact faces, plates and document details. Choose whether to keep supported photo metadata, add a custom watermark, then review a new copy before you share.
```

## Keywords — 91 / 100 UTF-8 bytes

```text
redact,redaction,faces,plates,documents,EXIF,geotag,location,stamp,overlay,background,share
```

No app-name or subtitle word is repeated in the keyword field. Do not add competitor names, unsupported claims, or keywords for cloud, OCR, or account features that are unavailable in the release.

## Description — 2,781 / 4,000 characters

```text
Prepare photos for sharing—on your terms.

Blur, cover or pixelate sensitive details. Add a visible text watermark. Choose whether location and other supported photo details travel with your new copy.

THREE PRIVACY TOOLS

REDACT VISIBLE DETAILS
Review suggested faces and likely number plates, soften a background, or cover information with a rectangle, ellipse or brush. Adjust the effect, compare with the original and undo changes as you work.

CONTROL PHOTO METADATA
Keep supported source details or remove them before export. Keep is selected by default, including location when available. Remove omits supported source location, capture date, camera/device details, descriptive fields, comments and embedded previews.

ADD A VISIBLE WATERMARK
Write your own text, move it directly on the photo and choose a style. Adjust size, opacity, rotation and repetition for a photo or document copy.

REVIEW, THEN SHARE
Inspect the edited copy before sharing, saving to Photos or keeping it in Veil’s private local gallery. Your original stays unchanged. The chosen metadata policy follows the saved copy and its later gallery exports.

LOCAL PHOTO EDITING
Photo processing and text recognition run on your iPhone. No Veil account is required. Veil adds no ads, analytics or tracking.

TWO EXPORTS INCLUDED
Try every editing tool and preview without using an export. Your first two successful Save or Share operations are included; failed or cancelled operations do not count. Each further successful output—including another destination or another export of the same photo—requires Veil Pro.

UNLIMITED EXPORTS WITH PRO
Monthly and yearly auto-renewable plans unlock the same unlimited protected photo exports. Eligible customers can receive a three-day free trial when offered by Apple. After the trial, the plan renews at its displayed localized price and billing period unless cancelled. Manage subscriptions in your Apple Account settings. To avoid renewing a trial, follow Apple’s guidance to cancel at least 24 hours before it ends. Restore Purchases uses the Apple Account used to subscribe.

IMPORTANT LIMITS
Automatic suggestions can miss details. Blur and pixelation do not guarantee anonymity; inspect the full result and use solid Redact with enough coverage for sensitive information. A watermark is visible text, not proof of authenticity or protection against editing.

Exports are JPEG copies. Re-encoding cannot preserve every source tag or auxiliary image, even with Keep selected. Orientation, dimensions and color information are rebuilt; receiving apps may add their own dates or identifiers. Removing metadata does not hide visible details or watermark text.

Terms of Use (Apple Standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

**Publication checks, not listing copy:** Both canonical subscriptions are READY_TO_SUBMIT in Photo Privacy Pro, at 12.99 PLN monthly / 99.99 PLN annual, with configured eligible three-day offers across the same 175 storefronts. Apple Standard EULA is linked in the description and app. A real approved Privacy Policy URL and Support URL are still missing; do not invent URLs or publish placeholders. The current build's legal purchase gate remains closed. See the handoff for final-binary and owner compliance requirements.

The description intentionally does not advertise account login or cloud sync: this release configuration has no approved Privacy Policy or Support URL and no configured backend. Add a reviewed, accurate optional-sync paragraph only after the actual providers, Supabase project, consent flow, retention and deletion behavior are configured and validated. Never describe this local-processing statement as meaning the image can never leave the phone: the user can explicitly Share, save, or later opt in to cloud sync in a configured release.

## Copyright

```text
© 2026 [LEGAL OWNER NAME — OWNER MUST SUPPLY]
```

Do not replace the owner placeholder with an assumed person or company. Confirm rights to every listing screenshot, icon, font and example image.

## Suggested category

**Primary: Photo & Video** is configured and read back in App Store Connect. No speculative secondary category was added.

## Feature bullets

- Blur, pixelate or cover faces, plates and document details.
- Choose whether supported source metadata is kept or removed from each new copy.
- Add and position a visible text watermark, with style and repeat controls.
- Review the finished image before saving, sharing or keeping it in the private gallery.
- Make two successful Save or Share exports without an account; Veil Pro unlocks unlimited protected photo exports.

## Screenshot sequence and caption copy

Final uploaded screenshots are in `Documentation/AppStore/Screenshots/1.0-release/en-US/listing/`, rendered reproducibly by `Screenshots/1.0-release/source/render_listing.swift` around actual 1320×2868 app captures. The original AppKit-generated fictional document needs no external photo/model license. Old rights-uncertain people/car candidates were not used. All six delivery states, order and local MD5 hashes were read back from Apple.

| Order | Screen shown | Exact rendered title |
| --- | --- | --- |
| 1 | Home hero with the three tools | **Redact. Metadata. / Watermark.** |
| 2 | Manual solid redaction over fictional document details | **Choose what / to cover.** |
| 3 | Metadata choice with Keep selected | **Supported details. / Your choice.** |
| 4 | Visible custom text watermark | **Add a visible / text watermark.** |
| 5 | Final review and Save / Share actions | **Review the copy / before sharing.** |
| 6 | Private Gallery with processed copies | **Keep edited copies / in Veil.** |

The overlay text must not imply guaranteed anonymity, complete metadata removal when Keep is selected, or proof of authenticity from a watermark. The screenshot and caption together must match the visible state.

## App Review notes — draft, not submitted

Use [APP_REVIEW_NOTES_DRAFT.md](APP_REVIEW_NOTES_DRAFT.md) and update it against the final commerce-capable build. No reviewer login is required. Current build 1.0 (5) intentionally disables purchase completion until a real public Privacy Policy URL is configured; do not describe it as ready for final subscription review. No reviewer credentials or contact details are invented.

See [APP_STORE_CONNECT_CHECKLIST.md](APP_STORE_CONNECT_CHECKLIST.md) for current completed configuration and remaining owner fields, and [AUTONOMOUS_RELEASE_HANDOFF.md](AUTONOMOUS_RELEASE_HANDOFF.md) for evidence and release gates.
