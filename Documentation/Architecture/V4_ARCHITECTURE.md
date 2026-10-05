# V4 architecture decision

Status: implementation decision; physical acceptance and external provisioning required. Base: V3 `72bdcb2`. No merge authorization.

## Existing boundaries
V3 normalizes orientation once, stores top-left normalized geometry, and uses PrivacyImageRenderer for both reduced-resolution preview and full-resolution export. ZoomablePhotoCanvas owns the proven UIKit transform/gesture handling. PhotoVeilHome currently owns session state, undo, async detection and rendering revisions. Preserve those contracts. Detection never reads the canvas transform.

## Decisions
- Processing: Apple Vision/Core Image, on-device. Bounded full-resolution + overlapping face tiles (at most 21 requests; about 1000-pixel crops for 12 MP images), merged before mask expansion. Reusable geometry, no repeat detection for style/strength changes. OCR strings are transient and never leave analysis.
- Editor: the current ephemeral session remains independent of persistence/auth. A single PrivacyEffect plus mask geometry supplies both preview and export. Undo includes effect/document selections. No original-image persistence.
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
