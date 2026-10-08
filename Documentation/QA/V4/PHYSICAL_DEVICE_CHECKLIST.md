# V4 physical-iPhone acceptance — DO NOT MERGE

Record model, iOS, app commit, configuration and approximate latency/memory behavior. Use approved test images, never upload a sensitive source for diagnostics. Simulator/unit success is not device acceptance.

- [ ] Existing V3 landing/layout/loop; Reduce Motion static, light/dark, Reduce Transparency, VoiceOver/largest text.
- [ ] PhotosPicker works without broad read authorization; local/iCloud-selected photo, portrait/landscape orientation.
- [ ] Save to Photos: first add-only prompt, allow, deny, restricted device policy, subsequent save does not re-prompt; Share and local save remain usable. Confirm no broad library read entitlement/description.
- [ ] Background on real people/objects; Low/Medium/Strong; Plates unchanged, multiple plates; large/multiple/small/edge/partial faces, zoom unchanged during analysis. Inspect misses/false positives; Manual fallback.
- [ ] Blur/Pixelate/Black and White solid redaction on detected regions, background and Manual rectangle/ellipse/brush. Inspect edges, undo, move/resize/delete, pinch/pan/fit, style/intensity changes and Done/Edit. No style change reruns Vision.
- [ ] Documents: sample card, rotated/perspective card, own-country/other-country licence, document with photo, low light/partial text. Review proposed regions, toggle, Hide all details, Hide entire document. OCR is heuristic, never universal field recognition; review every result.
- [ ] Shared/saved full-size JPEG matches preview semantics; source unmodified, no source EXIF/GPS copied. Check selected sharing apps and Photos output.
- [ ] Gallery: explicit Save to Veil, thumbnail grid/date, full image, share/Photos, deletion/multi-delete, relaunch persistence and storage count/usage; no account required; failed/locked storage does not destroy old files.
- [ ] App-switcher snapshots hide both editor and presented Gallery; lock/unlock and sheet interruptions recover without visual glitches.
- [ ] 12 MP and 48 MP photos: picker normalization, face tiles, document OCR, effect preview, export/JPEG encode, thumbnails and scroll. Record time and Xcode memory peak; test repeated operations without growth/termination. Gallery grid must load thumbnails, not every original-size image.
- [ ] Configured Apple: first auth/Hide My Email, returning auth without name/email, cancellation, restoration, revoked credential, sign out offline; local gallery kept. Optional name, no forced personal fields.
- [ ] Configured Google: consent/PKCE/callback, cancellation, restored session, provider failure. Verify no Photos/Drive scope.
- [ ] Sign-in alone does not upload. Explicit sync consent covers existing processed outputs; originals/OCR absent in storage/logs. Disable/sign out during transfer; existing cloud copies remain until deleted.
- [ ] Two devices and two accounts: processed files/metadata sync, retry/kill mid-upload, stale token, pagination, deletes during sync and remote deletion wins. A never reads/writes B metadata/storage through real APIs.
- [ ] Offline/backend unavailable: choose → edit → Done → Share/Photos/local save still works; sync failure is a status, not lost work.
- [ ] Delete cloud copies vs Delete local history vs Delete account are distinct. Account deletion removes files, profile, metadata, Auth identity and Vault token, revokes Apple; failures retry and never show false success. Local history stays.
- [ ] Final signing/entitlements/provider configuration, published legal/support links and correct App Privacy answers reviewed. Owner explicitly approves V4 before any merge.
