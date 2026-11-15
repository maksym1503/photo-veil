# Veil support — publication draft

Owner must supply a public Support URL and working contact method before release. Do not publish this preparation note or unresolved placeholders. Confirm support-message/attachment retention and a privacy-request contact.

## Edit a photo
Choose a photo, then choose Background, Faces, Plates, Documents or Manual. Automatic tools suggest areas to hide; tap detected regions to change their selection. Tools can stay active together. Each tool keeps its own Blur, Pixelate or Redact settings. Clear All affects that tool; Reset edits removes all edits.

In Manual, draw rectangles, ellipses or brush strokes. Use two fingers to zoom/pan, or Move photo. Undo reverses the last edit in the selected tool. Choose Done to inspect the full result, then Share, Save to Photos or Save to Veil. The original stays unchanged; the output is a new JPEG.

Detection can miss details. Inspect faces, plates, documents and reflections yourself. For sensitive text, use solid Redact and sufficient coverage; consider hiding the whole document. Blur/pixelation are not guarantees of anonymity.

## Photo details in new copies
Choose **Remove metadata** or **Keep metadata** in the Metadata tool. After Done, review the choice and save or share; tap the summary to change it. Remove omits source location, capture date/time, camera/device details, descriptive metadata, comments and embedded previews. Keep preserves supported source details, including location when available. JPEG re-encoding cannot retain every tag: original previews, auxiliary images, opaque application data and unsupported comments are excluded; orientation, dimensions and color information are rebuilt. The choice follows Save to Photos, Share, the saved gallery copy and future cloud sync, including thumbnails. Originals stay unchanged. Basic image-format information remains, and Photos or receiving apps may add dates or identifiers.

Existing files and previously uploaded/shared copies are not rewritten. Older gallery entries without a saved choice use Remove. Metadata already removed from an older copy cannot be recovered. Gallery/cloud operational dates and identifiers remain separate from embedded photo metadata.

## Opening and saving
A selected iCloud photo may need downloading before Veil can open it. Check connectivity or choose a photo already downloaded. Try another image if decoding fails.

Save to Photos requests permission only to add the processed output. If denied, change permission in iPhone Settings, or use Share/Save to Veil. Local files use device protection; unlock the iPhone if storage is unavailable. Removing Veil removes its local gallery; keep important exports independently.

## Accounts and cloud
Editing and the local gallery work without an account. Sign-in is available only in a configured build. Signing in alone does not upload photos. Enabling sync uploads processed gallery outputs, thumbnails and minimal metadata; originals and recognized text are never uploaded. Keep can include embedded location, capture and camera details in processed uploads. Cloud storage is not end-to-end encrypted.

Turning sync off stops future synchronization, not copies already uploaded. If the preference cannot be saved, sync stays off for this session: unlock the iPhone and retry before closing Veil, because a later launch can restore the last saved preference. Signing out keeps local history. Gallery deletion queues deletion for associated cloud copies; retries need the account and sync. Delete cloud copies keeps local photos and turns sync off. Delete account removes account/cloud data; local history is deleted separately in Settings. Retry an incomplete deletion online. Provider backups follow the published policy.

## Exports and purchases
Two successful Save/Share operations are free, without registration. Editing and preview remain free; failed or cancelled exports do not count. Re-exporting the same photo counts as another operation. Veil Pro offers unlimited protected exports monthly or yearly with the same features. An eligible three-day introductory trial is available once per subscription group under Apple's rules. The paywall shows localized price and automatic renewal terms. Restore Purchases uses the purchasing Apple Account independently of Veil sign-in; manage/cancel through App Store subscription settings. Deleting a Veil account does not cancel Apple billing. Free allowance is device-local, not synchronized, and reinstall survival is not guaranteed. If usage storage is unavailable, unlock the iPhone and retry. Production products/legal URLs still require owner setup before commercial release.

## Contact support
Report the iPhone model, iOS version, Veil version and steps to reproduce. Do not send personal photos, OCR content, passwords or authentication tokens for routine support. Supply an approved, secure process before requesting any attachments. Version information appears at the bottom of Settings → Support.

## Text watermarks
Veil combines blur/redaction, metadata control and watermarking. Custom watermark text/settings stay in the current editor session and bounded Undo history; closing or replacing the photo clears them. No reusable text template, telemetry, recipe or cloud text field is created. Saving/sharing deliberately embeds the visible text in the finished photo and thumbnails; optional consented cloud sync carries those flattened copies. Removing embedded source metadata does not remove visible watermark pixels. Avoid sensitive watermark text. Watermarks can be cropped or removed and do not prove authenticity or prevent misuse.

Choose Watermark → Add watermark, edit the text or select a privacy-purpose suggestion, and drag on the image. Native style, placement, repetition, size, opacity and rotation controls are available, including accessible alternatives. Originals remain unchanged. See [watermark scope and acceptance](WATERMARKS.md).
