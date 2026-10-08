# V4 architecture decision

Status: V4 physical design accepted; final composition regression and CI gate before merge. External provider provisioning remains separate. Base: V3 `72bdcb2`.

## Existing boundaries
V3 normalizes orientation once, stores top-left normalized geometry, and uses PrivacyImageRenderer for both reduced-resolution preview and full-resolution export. ZoomablePhotoCanvas owns the proven UIKit transform/gesture handling. PhotoVeilHome currently owns session state, undo, async detection and rendering revisions. Preserve those contracts. Detection never reads the canvas transform.

## Decisions
- Processing: Apple Vision/Core Image, on-device. Bounded full-resolution + overlapping face tiles (at most 21 requests; about 1000-pixel crops for 12 MP images), merged before mask expansion. Reusable geometry, no repeat detection for style/strength changes. OCR strings are transient and never leave analysis.
- Editor: the current ephemeral session remains independent of persistence/auth. Each privacy category owns independent PrivacyEffectSettings and active geometry. The selected tool is editing focus, not a render filter. A shared layer snapshot supplies both preview and export. Undo is scoped to the edited category; the separate Reset edits command remains global. No original-image persistence.
- Local persistence: file-backed processed JPEG + small thumbnail under Application Support/Veil/History/<UUID>. An actor owns versioned Codable metadata and atomic writes. SwiftData was evaluated: useful for complex queries but adds schema/container dependencies for a small flat gallery. Versioned metadata is easier to exercise in macOS CI and supports explicit migrations. Database blobs are avoided. Protected, backup-excluded storage; no silent migration prompt for V3 users (V3 has no persistent gallery).
- Identity: optional official Supabase Swift Auth with secure Keychain storage, native AuthenticationServices Apple token exchange, supported Google OAuth/PKCE browser flow. No password or mandatory profile form. Persist minimal optional display name; provider handles identity. Account entry offers value, never gates the editor.
- Cloud: private Supabase Storage + Postgres metadata, RLS owner checks. Explicit opt-in per account; only processed gallery outputs/thumbnails, never originals/OCR. Local save completes first. Serialized sync, stable item UUID/object paths, retryable upserts, persisted deletion tombstones. Remote processed results download to local protected files. Deletions propagate; metadata is authoritative. Disable/sign out halts sync, retains local files. Account deletion is a server-authenticated operation that removes storage before deleting identity; retries must be safe.
- UI: V3 landing/editor remain primary. Gallery/account are secondary native surfaces; adaptive tool menu prevents five cramped buttons. Final preview offers Save to Veil, Save to Photos and Share.

## Backend comparison
| Option | Fit / tradeoff |
| --- | --- |
| CloudKit | Strong native private iCloud database/storage with low operations. iCloud identity is not an Apple/Google-auth gallery identity; independent Google and future non-Apple clients complicate this product. |
| Supabase (selected) | Managed Postgres, explicit inspectable RLS, private Storage, Apple token exchange + Google OAuth, cross-platform clients. Requires project/provider/redirect setup, policy tests, region/retention choices and server-side deletion. Team must manage migrations and provider configuration. |
| Firebase | Mature Apple/Google auth and storage; Firestore is workable at this scale. Adds a separate rules/data model and multiple SDK products; less direct SQL ownership/migration visibility for this small team. Billing/storage setup also needs owner input. |

Supabase wins on the requested identity model, inspectable relational ownership and future client flexibility, rather than on speculative scale. No image-processing backend, realtime subscription, custom cryptography or enterprise infrastructure.

## Security / data flow
Local editor: picker-selected bytes → normalized pixels → Vision geometry → shared renderer → temporary share / add-only Photos / explicit protected gallery save.
Optional cloud: explicit consent + authenticated session → processed JPEG/thumbnail and non-sensitive dimensions/style/timestamps → private user namespace. Provider identifiers and optional display name are account data. No originals, OCR strings, analytics or tracking. HTTPS and access control are not end-to-end encryption; operator and backup access must be disclosed.

PhotosPicker remains selection-scoped with no read authorization. Save to Photos requests `.addOnly` on invocation, with a localized usage description. Denied/restricted states do not block Share or local saving.

## External requirements / acceptance
No invented project, key, domain, legal owner or provider ID. The default build is unconfigured and local-only. Account/cloud availability requires the documented owner setup and real cross-user integration testing. Sign in with Apple capability and account deletion/revocation setup must be validated before release. Physical small-face/performance measurements are mandatory; Simulator recall is not a promise of complete detection.

## References and dependencies reviewed
- [Apple Photos access levels](https://developer.apple.com/documentation/photos/phaccesslevel), [CloudKit](https://developer.apple.com/documentation/cloudkit).
- [Supabase official Swift SDK, MIT license, actively maintained](https://github.com/supabase/supabase-swift): inspect pinned release source, secure storage, PKCE, examples. Use the official SDK to avoid custom token-refresh/OAuth infrastructure. No Google SDK is required for supported provider OAuth.
- [Apple provider](https://supabase.com/docs/guides/auth/social-login/auth-apple), [Google provider](https://supabase.com/docs/guides/auth/social-login/auth-google), [Storage ownership policies](https://supabase.com/docs/guides/storage/security/access-control).
- [Firebase Apple authentication](https://firebase.google.com/docs/auth/ios/apple), [Google authentication](https://firebase.google.com/docs/auth/ios/google-signin).

Native Core Image already supplies blur/pixelation/compositing; an editor/helper dependency would not reduce complexity. Keep Apple frameworks for image processing. Exact dependency versions/licenses and final operational limits are recorded in Backend setup and QA.

V3 rendering semantics remain active-tool based: selecting another tool switches the active automatic mask set, rather than combining independently styled automatic tools. Effect/strength apply to the active session; editable originals and per-region mixed-effect stacks are future options, not silently added to cloud history.

## V4.2 automatic-tool lifecycle

`DetectedPrivacySelection` separates cached analysis status (`idle`, `detecting`, successful count, failure) from active selected indices and activation intent. Faces, Plates, Documents and Background share it; their geometry/mask caches remain in the existing editor session. Background represents a successful foreground mask as one selectable privacy effect.

Entering an automatic tool from another tool is fresh activation intent: cached regions are selected again, without another Vision request. Clear All deactivates only that category and keeps analysis cached. Clearing while analysis is running suppresses activation when it finishes. Manual Clear All removes its rectangles, ellipses and strokes; Undo restores them. Documents re-entry retains the chosen Details/Entire Document coverage and activates that geometry. Individual region toggles continue to alter only selection. Existing preview/export renderer and image-space geometry are unchanged.

Zero results and failures are distinct cached outcomes. Only a completed analysis (or re-entry to its cached outcome) produces transient feedback. A late result from a tool no longer selected cannot display that tool's feedback. Replacing/closing the photo cancels feedback and per-session tasks. Background's existing Manual fallback remains, now with concise transient feedback. No image/OCR data is included in diagnostics or feedback.


## V4.3 composable privacy layers
Background, Faces, Plates, Documents and Manual remain active together. Cached analysis, active selection, per-category effect settings and editing focus are separate. Re-entering an automatic tool activates its cached geometry without affecting other categories; Clear All affects only the selected category. Manual undo never restores old automatic selections. An undo during pending analysis also restores activation intent, so a late result cannot undo the user's removal.

Both preview and all export destinations consume `renderLayers`. Rendering builds one Core Image graph, with one final CGImage materialization. Soft effects run from lower to higher strength; equal-strength ties use Background → Faces → Plates → Documents → Manual. Solid redactions run last, in category order. Every stage filters/blends the accumulated image, never the original. Foreground mask white pixels retain the accumulated result, including earlier face/manual privacy. Overlapping solid regions retain solid coverage (later solid colors win); subsequent soft effects cannot soften or reveal a redaction. Preview and export share normalized masks, effect parameters and composition order; only resolution differs.

Analysis results arriving after a tool switch still update the composition. Done/export waits for all requested analyses, preventing an in-flight background or face layer from being omitted. Unchanged layer snapshots reuse the completed preview, avoiding a render for focus-only switches. Source replacement/global reset invalidate that reuse. Auth/network state does not participate in any of these contracts.

Gallery/cloud metadata retains the existing coarse `effect` tag (Redact if present, otherwise Pixelate if present, otherwise Blur); it is not an editable layer recipe. This preserves the existing schema contract. The persisted JPEG contains the entire composition, regardless of that summary tag.

A Reset edits undo snapshot expires when a new edit begins, so a later category undo cannot replace newer selections with an old global snapshot. Core Image intermediate caching is disabled: unchanged previews are reused at the session boundary, without retaining large full-resolution intermediate surfaces across exports.

Region effects request only their selected bounding rectangle plus the feather halo from Core Image; filter inputs remain the full accumulated image so blur/pixel sampling quality and coordinates are unchanged. Background still spans the image. This avoids evaluating every region filter over a 48 MP image and keeps the same shared composition graph for preview/export. See [Apple’s intermediate cache option](https://developer.apple.com/documentation/coreimage/cicontextoption/cacheintermediates).

Undo retains up to 30 edits per category, so repeated automatic edits cannot evict Manual history. Cached re-entry with an unchanged selection creates no undo record; reactivation after a clear or partial selection remains an undoable edit.
