# Veil privacy policy — V4 preparation draft

Not legal advice; do not publish placeholders.
Developer/controller: **[REAL LEGAL ENTITY]**. Contact: **[REAL PRIVACY CONTACT]**. Effective date: **[CONFIRM DATE]**. Jurisdiction/rights: **[LEGAL REVIEW]**.

## Local editing and local gallery
Veil processes chosen photos and recognizes faces/text on your device. The system picker grants access only to selected photos; Apple may retrieve selected iCloud Photos assets. Veil does not request broad photo-library read access. Save to Photos asks for add-only permission when you invoke it. Share lets you choose a recipient whose own policy applies.

Source photos remain unchanged and are not automatically uploaded or saved in Veil. Recognized OCR strings are transient; Veil neither stores nor uploads them. Explicit Save to Veil keeps a newly rendered processed JPEG, thumbnail and minimal date/dimension/style metadata in protected local files, excluded from device backup. Local history is removed through Settings or app removal. Temporary sharing files are cleaned after the share sheet closes or on the next launch; cleanup can be interrupted by termination. Source EXIF/GPS metadata is not copied; generated JPEG dimension/orientation metadata can remain.

## Optional accounts and cloud gallery
Accounts are optional; editor, local saving and export work without login. Apple/Google and the configured Supabase service process identity identifiers, provider-supplied email (including Apple relay addresses), optional name and authentication/session data to provide your account. Veil does not require a name, password form or duplicate email profile record. Device session credentials use device-bound Keychain storage.

Signing in does not by itself enable photo synchronization. Explicitly enabling sync uploads processed gallery outputs, thumbnails and minimal edit metadata to private account storage. Originals/source asset files and OCR are not uploaded. Finished outputs may contain details you did not redact: review them before saving/sharing. Storage uses HTTPS and ownership access controls; it is **not end-to-end encrypted**. The cloud operator and backups can be part of the data-processing chain.

Cloud processor/region: **[CONFIRM SUPABASE PROJECT REGION, DPA AND SUBPROCESSORS]**. Provider/server access logs, IP/security records, backup retention and international transfers: **[CONFIRM REAL CONFIGURATION/LEGAL BASIS/RETENTION; DO NOT CLAIM ZERO SERVER LOGS]**. Veil adds no analytics, advertising or tracking SDK/service.

## Retention and deletion
Turning sync off stops future synchronization, not copies already uploaded. In-flight transfers may have begun. Signing out keeps local history. Gallery deletion removes local files/metadata and queues cloud deletion if the item was associated with your account; cloud retries require login/sync. Minimal remote deletion tombstones remain for cross-device convergence until account deletion. **[CONFIRM/PUBLISH TOMBSTONE AND ABANDONED-UPLOAD RETENTION POLICY]**.

Delete cloud copies keeps local photos and disables sync. Delete account closes cloud writes, revokes Apple tokens where used, removes gallery files/metadata/profile and Auth identity; failures require a retry, rather than claiming success. Local history is a separate Settings action. Apple revocation refresh tokens are stored through managed Vault until account deletion; they are not inside the app. Backups/provider/legal retention: **[CONFIRM TIMEFRAMES, EXCEPTIONS AND REQUEST PROCESS]**.

## Your choices and limitations
You control selected photos, local saves, Photos permission, sharing, optional account/sync and deletion. Automatic detection and blur/pixelation can miss or preserve identifying details. Manual and complete solid redaction are available; no anonymity or payment-card certification guarantee is made.

Data access/export/objection/erasure and regional rights: **[CONFIRM ACTUAL PROCESS AND CONTACT]**. Support correspondence/public websites: **[CONFIRM COLLECTION AND RETENTION]**. Apple platform diagnostics are governed by Apple settings/policies; no custom Veil telemetry service is added. Policy changes will use a revised effective date.
