# Veil — App Store preparation

Status: preparation only. Nothing submitted to App Store Connect. V3 must remain unmerged until the owner completes physical-iPhone visual QA.

## Ready

- Identity retained: `com.maksym1503.veil`, display name **Veil**, `veil://` launch scheme. iPhone only, iOS 17+, portrait orientation explicitly declared.
- Version/build have one source: Xcode `MARKETING_VERSION=1.0`, `CURRENT_PROJECT_VERSION=3`; Info.plist resolves those values. Increment build for subsequent uploads.
- Existing local `DEVELOPMENT_TEAM` edits preserved, excluded from V3 commits. No provisioning credentials or signing team added to repository.
- Existing universal 1024 × 1024 app icon is opaque; asset compilation succeeds. Native launch screen, immediate photo picker entry, no account/onboarding gate.
- Picker-scoped import (`PhotosPicker`, `.images`). No broad Photos authorization, camera, microphone, location or photo-library usage descriptions are required by the current code. System sharing exports a new image; the app does not call PhotoKit to save directly.
- Apple-only runtime frameworks: SwiftUI, UIKit, PhotosUI, Vision, Core Image, ImageIO, CryptoKit. No runtime package dependencies, ad SDKs, analytics, tracking, networking client or backend.
- Source audit: processing and detection are on-device. No photos uploaded to Veil servers. iCloud Photos may download a selected original through Apple's picker; destinations selected in the share sheet may upload the exported copy. These are not Veil uploads.
- Bundled `PrivacyInfo.xcprivacy`: no tracking, tracking domains or collected data. No required-reason APIs were identified in app source (no UserDefaults/AppStorage, file timestamp queries, disk-space queries, boot-time queries or active keyboard queries). Normal image file reads/writes do not justify adding invented required reasons. Repeat the audit if dependencies or storage behavior change.
- Suggested App Privacy response: **Data Not Collected**, subject to developer verification of the final distributed binary and configured public website practices.
- Original untouched. Export uses the same `PrivacyImageRenderer` and image-space edit state as preview, at full source resolution; new high-quality JPEG omits source EXIF/GPS metadata. JPEG is opaque and lossy; HDR/wide-gamut fidelity is not guaranteed.
- Native grouped Settings/About/Help and photo privacy explanation. Unconfigured legal/contact links are hidden, never replaced by fake destinations.
- Native toolbar, Share symbol, system sheets/menus, glass styles on iOS 26, material/bordered fallbacks on iOS 17–25. Neutral selected treatment plus accessibility selected traits; detection on/off differs by solid/dashed corners and actual blur rather than color alone.
- Dynamic Type text, two-column tool layout at larger text and a native tool menu at the largest accessibility sizes, scrolling landing/legal screens, minimum 44-point control targets, Reduce Motion handling for press/landing animation, opaque Reduce Transparency control fallback. Detected face/plate accessibility elements have actual activation callbacks.
- Debug fixture loading and image evidence output gated by `DEBUG`; Debug explicitly defines it. Release excludes the three UI test JPEG fixtures. See QA report for runtime coverage and limits.

## Needs developer input

- Publish the reviewed Privacy Policy at a real public HTTPS URL; set `VeilPublicLinks.privacyPolicy` in `Sources/PhotoVeil/VeilPresentation.swift`, and enter it in App Store Connect.
- Supply real support website/contact, set `VeilPublicLinks.support`. App Store support URL must provide a usable contact method. No email/domain/legal entity has been invented.
- Decide whether to publish separate Terms. If used, review the draft, publish it and set `VeilPublicLinks.terms`. Separate terms are not a substitute for the applicable App Store license agreement.
- Confirm developer/legal entity name, jurisdiction, effective dates, applicable consumer rights and support contact; obtain legal review of drafts as needed.
- Confirm availability of the App Store name (recommendation: **Veil: Photo Privacy Blur**), final category (recommendation: Photo & Video), age-rating questionnaire, pricing, territories, copyright and content rights.
- Confirm build/version history in App Store Connect, app registration, signing/provisioning, distribution certificate and team. Perform a signed device archive, Xcode Validate App and final privacy report before uploading. Unsigned Simulator/Release builds do not validate distribution signing.
- Prepare actual iPhone screenshots from the approved physical-device design; review blur strength and detections on real photos. Do not represent illustration/fixtures as a guarantee of automatic anonymization.
- Complete VoiceOver hands-on device review, maximum accessibility text sizes, oldest supported iOS/device behavior and physical-device background Vision coverage. iOS 26 Simulator lacks some foreground-model support.
- Confirm export/sharing destinations, metadata omission, offline operation and memory behavior with very large photos on physical iPhone.
- No App Store Connect submission, account system, purchases or analytics were added.

## References reviewed

- [Apple HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Apple: Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple: Required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple: Photos picker privacy](https://developer.apple.com/videos/play/wwdc2023/10107/)

Draft documents are preparation material, not legal advice. Do not publish placeholders.
