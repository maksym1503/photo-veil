# V4 physical-iPhone acceptance — DO NOT MERGE

Record model, iOS, app commit, configuration and approximate latency/memory behavior. Use approved test images, never upload a sensitive source for diagnostics. Simulator/unit success is not device acceptance.

- [ ] Existing V3 landing/layout/loop; Reduce Motion static, light/dark, Reduce Transparency, VoiceOver/largest text.
- [ ] PhotosPicker works without broad read authorization; local/iCloud-selected photo, portrait/landscape orientation.
- [ ] Save to Photos: first add-only prompt, allow, deny, restricted device policy, subsequent save does not re-prompt; Share and local save remain usable. Confirm no broad library read entitlement/description.
- [ ] Background on real people/objects; Low/Medium/Strong; Plates unchanged, multiple plates; large/multiple/small/edge/partial faces, zoom unchanged during analysis. Inspect misses/false positives; Manual fallback.
- [ ] Blur/Pixelate/Black and White solid redaction on detected regions, background and Manual rectangle/ellipse/brush. Inspect edges, undo, move/resize/delete, pinch/pan/fit, style/intensity changes and Done/Edit. No style change reruns Vision.
- [ ] Documents: sample card, rotated/perspective card, own-country/other-country licence, document with photo, low light/partial text. Review proposed regions, toggle, Hide all details, Hide entire document. OCR is heuristic, never universal field recognition; review every result.
- [ ] Shared/saved full-size JPEG matches preview semantics; source unmodified. Remove omits source EXIF/GPS; Keep retains supported fields, including GPS when available. Check selected sharing apps and Photos output.
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

## Remove metadata branch

- Use approved synthetic tagged JPEG/HEIC fixtures with GPS, camera, capture time, description and rotated/mirrored orientation. Choose Remove metadata, then Save to Veil, Photos and Share from editor and gallery; inspect exported JPEG bytes independently for source tags/comments/previews. Do not retain personal photos or metadata payloads as evidence.
- Verify Photos Info shows no inherited GPS/camera/capture metadata; Photos may assign its own save date/asset ID. Check visible orientation, color and redaction, including wide-gamut inputs. Original remains unchanged; local history operational dates remain.
- Exercise 12/48MP exports and legacy re-exports with Instruments peak memory/responsiveness; standard sRGB raster may add about4bytes/pixel (192MB at48MP). Record hardware/OS/configuration and do not infer this from simulator timings.
- Offline/default-local operation remains supported. Failed decode/encode must not save/share/upload source bytes; existing remote copies require separate handling, not a silent migration.

## Optional metadata export choice

- After Done, verify Remove/Keep is readable with largest text and VoiceOver; returning to editing keeps the choice, a different photo resets to visible Keep.
- Use synthetic tagged JPEG/HEIC input. For both choices, test Photos, Share, local gallery/relaunch/re-export and configured two-device sync only after the migration is approved/applied. Remove omits source tags; Keep retains supported location/capture/camera/descriptive fields. Photos may add its own dates/IDs.
- Verify source preview never reappears, edited pixels/orientation/dimensions stay correct, original remains untouched and no failed removal exports raw input. Check Keep limitations and empty metadata wording.
- Check wide-gamut/HDR appearance and 12–48MP peak memory. Older already-sanitized copies cannot recover source metadata.

### Three-pillar / watermark acceptance
- Review home/guide/About/Help as Redact, Metadata, Watermark; test Reduce Motion/Transparency and largest text.
- Add default and custom Unicode text; preview Light/Dark/Stamp on bright/dark photos; verify no clipped glyphs or unexpected line breaks. Test text limits and Cancel.
- Drag at fit/zoom/pan and after device rotation; one finger edits, two navigate; placement presets and VoiceOver position actions work. Size/opacity/rotation/repeat respond without stale output.
- Add mixed redaction plus mark, Undo within each scope, Reset/Undo, close and replace photo. Hidden original pixels must never reappear beneath watermarks.
- Inspect actual Photos/share/gallery/relaunch/cloud-compatible output with both metadata policies; visible mark survives once, originals unchanged; removal failures do not leak source metadata.
- Profile 12/48 MP portrait/landscape/HDR-origin photos: glyph edges, color, peak memory, thermal/latency and repeated marks. Compare preview placement and full-resolution output.
- Confirm entered text never appears in logs, preferences, cloud records or debug captures outside explicit synthetic testing; it remains intentionally visible in saved pixels/thumbnails.
