# Veil privacy policy — V4 preparation draft

Not legal advice; do not publish placeholders.
Developer/controller: **[REAL LEGAL ENTITY]**. Contact: **[REAL PRIVACY CONTACT]**. Effective date: **[CONFIRM DATE]**. Jurisdiction/rights: **[LEGAL REVIEW]**.

## Local editing and local gallery
Veil processes chosen photos and recognizes faces/text on your device. The system picker grants access only to selected photos; Apple may retrieve selected iCloud Photos assets. Veil does not request broad photo-library read access. Save to Photos asks for add-only permission when you invoke it. Share lets you choose a recipient whose own policy applies.

Source photos remain unchanged and are not automatically uploaded or saved in Veil. Recognized OCR strings are transient; Veil neither stores nor uploads them. Explicit Save to Veil keeps a newly rendered processed JPEG, thumbnail and minimal date/dimension/style metadata in protected local files, excluded from device backup. Local history is removed through Settings or app removal. Temporary sharing files are cleaned after the share sheet closes or on the next launch; cleanup can be interrupted by termination.

Choose **Remove metadata** or **Keep metadata** in the Metadata tool. After Done, review the choice and save or share; tap the summary to change it. Remove omits source location, capture date/time, camera/device details, descriptive metadata, comments and embedded previews. Keep preserves supported source details, including location when available. JPEG re-encoding cannot retain every tag: original previews, auxiliary images, opaque application data and unsupported comments are excluded; orientation, dimensions and color information are rebuilt. The choice follows Save to Photos, Share, the saved gallery copy and future cloud sync, including thumbnails. Originals stay unchanged. Basic image-format information remains, and Photos or receiving apps may add dates or identifiers.

Existing files and previously uploaded/shared copies are not rewritten. Older gallery entries without a saved choice use Remove. Metadata already removed from an older copy cannot be recovered. Gallery/cloud operational dates and identifiers remain separate from embedded photo metadata.

## Optional accounts and cloud gallery
Accounts are optional; editor, local saving and export work without login. Apple/Google and the configured Supabase service process identity identifiers, provider-supplied email (including Apple relay addresses), optional name and authentication/session data to provide your account. Veil does not require a name, password form or duplicate email profile record. Device session credentials use device-bound Keychain storage.

Signing in does not by itself enable photo synchronization. Explicitly enabling sync uploads processed gallery outputs, thumbnails and minimal edit metadata to private account storage. Originals/source asset files and OCR are not uploaded. Keep can include embedded location, capture and camera details in processed uploads. Finished outputs may contain details you did not redact: review them before saving/sharing. Storage uses HTTPS and ownership access controls; it is **not end-to-end encrypted**. The cloud operator and backups can be part of the data-processing chain.

Cloud processor/region: **[CONFIRM SUPABASE PROJECT REGION, DPA AND SUBPROCESSORS]**. Provider/server access logs, IP/security records, backup retention and international transfers: **[CONFIRM REAL CONFIGURATION/LEGAL BASIS/RETENTION; DO NOT CLAIM ZERO SERVER LOGS]**. Veil adds no analytics, advertising or tracking SDK/service.

## Subscriptions and free exports
Veil uses verified Apple purchase information to determine Pro access independently of optional Veil sign-in. Apple processes payments; Veil does not receive payment-card details. No purchase data is uploaded to a Veil billing server. Two successful Save/Share operations are free. A separate device-only, nonsynchronizing Keychain record stores a schema version and count, without photo identifiers, fingerprints, recognized text, watermark text or account information. It is excluded from migration/backup and can survive app deletion; reinstall survival is not guaranteed. Deleting gallery history or a Veil account does not reset it or cancel Apple billing. Free usage is not synchronized between devices. Apple subscriptions can be restored using the purchasing Apple Account. **[CONFIRM FINAL APP PRIVACY PURCHASE-HISTORY DECLARATION AND PUBLISH LEGAL LINKS BEFORE RELEASE]**.

## Retention and deletion
Turning sync off stops future synchronization, not copies already uploaded. In-flight transfers may have begun. If Veil cannot save the preference, synchronization stays off for the current session and Veil asks you to retry before closing; the last successfully saved preference can apply on a later launch. Signing out keeps local history. Gallery deletion removes local files/metadata and queues cloud deletion if the item was associated with your account; cloud retries require login/sync. Minimal remote deletion tombstones remain for cross-device convergence until account deletion. **[CONFIRM/PUBLISH TOMBSTONE AND ABANDONED-UPLOAD RETENTION POLICY]**.

Delete cloud copies keeps local photos and disables sync. Delete account closes cloud writes, revokes Apple tokens where used, removes gallery files/metadata/profile and Auth identity; failures require a retry, rather than claiming success. Local history is a separate Settings action. Apple revocation refresh tokens are stored through managed Vault until account deletion; they are not inside the app. Backups/provider/legal retention: **[CONFIRM TIMEFRAMES, EXCEPTIONS AND REQUEST PROCESS]**.

## Your choices and limitations
You control selected photos, local saves, Photos permission, sharing, optional account/sync and deletion. Automatic detection and blur/pixelation can miss or preserve identifying details. Manual and complete solid redaction are available; no anonymity or payment-card certification guarantee is made.

Data access/export/objection/erasure and regional rights: **[CONFIRM ACTUAL PROCESS AND CONTACT]**. Support correspondence/public websites: **[CONFIRM COLLECTION AND RETENTION]**. Apple platform diagnostics are governed by Apple settings/policies; no custom Veil telemetry service is added. Policy changes will use a revised effective date.

## Text watermarks
Veil combines blur/redaction, metadata control and watermarking. Custom watermark text/settings stay in the current editor session and bounded Undo history; closing or replacing the photo clears them. No reusable text template, telemetry, recipe or cloud text field is created. Saving/sharing deliberately embeds the visible text in the finished photo and thumbnails; optional consented cloud sync carries those flattened copies. Removing embedded source metadata does not remove visible watermark pixels. Avoid sensitive watermark text. Watermarks can be cropped or removed and do not prove authenticity or prevent misuse.

Choose Watermark → Add watermark, edit the text or select a privacy-purpose suggestion, and drag on the image. Native style, placement, repetition, size, opacity and rotation controls are available, including accessible alternatives. Originals remain unchanged. See [watermark scope and acceptance](WATERMARKS.md).
