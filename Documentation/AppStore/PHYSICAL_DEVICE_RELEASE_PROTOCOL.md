# Physical-device release protocol — NOT VERIFIED

This is the acceptance procedure for the Veil 1.0 release candidate. No physical-device run is recorded here. Simulator, SwiftPM, StoreKit configuration-file and UI-test results do not satisfy these checks. Do not mark an item complete without a dated run record, candidate/build identity and actual-device evidence.

## Run record

Create one record per device/configuration. Keep evidence to app UI and synthetic test data; do not retain personal photos, OCR text, account credentials, access tokens or private locations.

| Field | Record |
| --- | --- |
| Status | NOT VERIFIED |
| Date / operator | — |
| Candidate commit and app version/build | — |
| Device model / iOS version | — |
| Locale / appearance / text size / VoiceOver | — |
| Network and StoreKit environment | — |
| Synthetic photo fixtures and pixel dimensions | — |
| Result bundle or sanitized notes location | — |
| Open failures / owner disposition | — |

## Gate 1 — installation, permissions and local editing

- Install the exact release-candidate build on a supported physical iPhone. Record install source, model, OS and build. Verify cold launch, force-quit/relaunch and lock/unlock.
- Open the system photo picker, select one approved synthetic photo and confirm Veil receives only the selection; do not grant broad library-read access. Confirm the app remains usable after picker cancel and when Photos access is otherwise restricted.
- Save to Photos and record the first add-only permission prompt. Test allow and deny paths. After denial, Share and Save to Veil must remain available; verify the app explains the Photos limitation without implying that it changed the original.
- Exercise Share, Save to Photos and Save to Veil separately. Confirm temporary Share output cleanup, local gallery persistence after relaunch, and that the original asset remains unchanged.
- Exercise editor cancel, Done/review/Edit, undo, reset, app switching and interruptions. Confirm the privacy-edited image—not original pixels—is used for each final export.

## Gate 2 — metadata and high-resolution photo behavior

Use owner-approved synthetic JPEG and, where supported by the picker, HEIC fixtures with known embedded GPS at the null island test coordinate, capture time, camera/device, description/comment, orientation and dimensions. `Screenshots/1.0-release/source/generate_sample.swift` documents the original synthetic document and fictional metadata used for current marketing capture; verify actual fixture bytes before each run. The smaller marketing fixture does not replace separate 12–48 MP device fixtures. Never use a personal photo or a real address as a metadata fixture.

For a portrait and landscape 12 MP source and a 48 MP source where the device supports it:

1. Open the source, apply face/plate or manual redaction plus a watermark, and test the editor at fit and zoom. Record any missed/false detections; automatic detection is fallible.
2. With **Keep** selected, export separately through Share, Photos and Save to Veil. Inspect the resulting JPEG bytes using a local metadata reader and Photos Info. Confirm the known supported source fields remain where supported, pixels/orientation/dimensions are correct, and the visible watermark is flattened once. Record what the destination adds itself.
3. Repeat with **Remove** selected. Confirm supported source GPS, capture date/time, camera/device and descriptive source fields are absent from the JPEG and absent as inherited data in Photos Info. Photos may assign its own save date, asset identifier or other destination data; record that distinction.
4. Reopen the saved gallery copy, relaunch, share/re-export, and confirm the persisted policy is respected. Existing legacy items with no policy should follow Remove. Confirm failure paths do not save or share raw input and the source photo stays unchanged.
5. Review metadata availability wording when a source has no supported fields. It must not imply Veil removed fields that were never present.

Record export latency, peak memory if Instruments is available, device temperature/throttling and any termination for 12/48 MP runs. This protocol sets no simulator-derived performance target. Do not attach source images or metadata dumps to release evidence; keep a sanitized pass/fail result and fixture identifier only.

## Gate 3 — VoiceOver, largest text and visual settings

- With VoiceOver enabled, complete photo selection, Redact, Metadata, Watermark, Done/review, Save, Share, gallery open/delete and subscription restore. Check meaningful labels, selected values, reading order, focus return and that destructive actions are distinguishable.
- Set Dynamic Type to the largest available accessibility size. Verify both metadata choices and their selected states remain visible and hittable; Watermark controls remain reachable; review Save/Share remain visible or reachable without ambiguity; gallery selection/delete and subscription plan/actions remain usable in their scroll viewport.
- Repeat key screens in Light and Dark appearance, Reduce Motion and Reduce Transparency. Look for clipped titles, low-contrast status text, animation drift, layout jumps, controls hidden behind safe areas and dialogs with unreachable actions.
- Confirm the source comparison affordance never exports the original while editing and does not cause the preview to jump or lose the selected photo.

## Gate 4 — two local exports and subscription behavior

### Device-local free allowance

Use a clean test device state and record whether the Keychain export counter already exists. The two included successful Save/Share operations are device-local: the nonsynchronizing, device-bound Keychain count does not roam to another device/account and can survive app removal. Do not assume reinstall resets it or use an undocumented reset to create a false pass.

- Verify two successful outputs can be made without an account or subscription. Include distinct destinations and a repeat export of the same photo.
- Verify cancel, failed save/share, editor preview and failed payment do not count as a successful output.
- Verify the next successful export reaches the Veil Pro gate. Cancel/dismiss the purchase sheet and confirm the export did not occur and gallery/editor data remains intact.
- On another physical device, verify the free counter is independent while the same Apple subscription entitlement can unlock Pro after StoreKit refresh/restore. Do not describe the free count as shared or account-wide.

### StoreKit Sandbox plans and lifecycle

**Production App Store Connect status for the yearly product, storefront prices, introductory offers and legal URLs is NOT VERIFIED.** Do not treat the local StoreKit configuration as proof of production product availability. This section is blocked until the owner confirms both real products in the intended subscription group and supplies an authorized Sandbox test account/device setup. Do not use production Apple Account credentials in test notes.

- Fetch exact product IDs `vail.pro.monthly` and `vail.pro.annual`; record the product display name, localized price, renewal period and whether the product can be purchased. Confirm both are auto-renewable products in the same `Photo Privacy Pro` group with the same unlimited-export feature level.
- On an eligible Sandbox account, purchase monthly and separately yearly. Verify the app grants access only after a verified entitlement, after force-quit/relaunch, after Restore Purchases, and on a second device signed into the same Sandbox Apple Account. Verify the app never grants access from an unverified transaction.
- Verify the UI shows the actual localized price, period, renewal and cancellation terms before purchase. An introductory CTA may be shown only when StoreKit confirms the customer is eligible and that product carries the intended exact three-day offer.
- Test subscription-group offer eligibility: use one eligible account to start the three-day introductory offer on one plan, then verify switching to the other plan does not present another free trial when the account is ineligible under the configured group offer rules. Also test an account that is ineligible from the start. Record the account state and StoreKit response, not personal account data.
- Cancel renewal through Apple’s subscription management, then test continued access through the paid term and loss of access after expiry. Verify current entitlement after app relaunch and Restore Purchases.
- Test billing retry and grace period only when Apple’s Sandbox controls produce a verified grace state. Confirm access during the verified grace window, then expiry when that state ends. Do not infer grace from a UI message alone.
- Exercise refund/revocation using Apple’s supported Sandbox testing path. Confirm revoked entitlement removes Pro access after StoreKit updates, and confirm free/local gallery content is preserved. Record any timing behavior without arbitrary sleeps.
- Repeat purchase, cancellation, expiry and restore after force-quit/relaunch. Reinstall only on a controlled test device; confirm StoreKit entitlement can be restored and note that the local free-export Keychain counter may survive app deletion.

**Current status: NOT VERIFIED on physical hardware or Apple Sandbox.** Unit/UI automation, simulator StoreKit tests and local `.storekit` configuration evidence do not complete this gate.

## Gate 5 — release decision record

| Acceptance area | Status | Evidence / issue |
| --- | --- | --- |
| Physical device identity and release-candidate build | NOT VERIFIED | — |
| Picker scope, add-only Photos prompt and denial path | NOT VERIFIED | — |
| Keep/Remove metadata bytes and Photos Info | NOT VERIFIED | — |
| 12 MP and 48 MP behavior / memory | NOT VERIFIED | — |
| VoiceOver and largest accessibility text | NOT VERIFIED | — |
| Two device-local free exports and third-export gate | NOT VERIFIED | — |
| Monthly and yearly production products | NOT VERIFIED | — |
| Eligible three-day offer / one group eligibility | NOT VERIFIED | — |
| Renewal, cancellation, expiry, grace, refund and restore | NOT VERIFIED | — |
| Same-account cross-device Pro entitlement | NOT VERIFIED | — |
| Owner review of unresolved failures and submission evidence | NOT VERIFIED | — |

Do not replace these statuses based on simulator or automated test results. The owner must record actual-device results and explicitly accept the release before submission. This protocol is not merge, distribution, TestFlight or App Store approval.
