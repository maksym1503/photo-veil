# ADR-005: Explicit photo metadata choice

Status: accepted, 2026-10-10 · CTO: gpt-6-astra (read-only) · Authority: Lead under explicit owner request.
Supersedes ADR-004's mandatory-removal policy; its fail-closed removal boundary remains.

After Done, show a native Remove metadata / Keep metadata choice. Keep is visibly selected for each new photo (owner-requested polish, 2026-10-11); returning to editing retains the choice within that session. Snapshot the choice with the rendering request. Originals remain unchanged.

Capture an immutable supported-metadata snapshot from imported picker bytes before pixel normalization; hold it in memory only and clear with the session. A private, neutral `PhotoExport` carries encoded bytes, actual dimensions and policy to every destination. Remove uses the existing pixel-only opaque sRGB encoder, failing closed. Keep uses native ImageIO with supported GPS, capture, camera/lens and descriptive fields; normalize orientation and dimensions, exclude original previews, opaque MakerNotes/application payloads and auxiliary images. JPEG encoding cannot preserve every source-format tag or original image representation. Never silently switch a failed Keep operation to Remove.

Persist an optional local item policy (missing legacy policy means Remove). Gallery exports and future uploads follow that saved choice. A backward-compatible cloud metadata column carries the policy across devices; download applies it. Prepare an additive SQL migration locally only. Unknown policies fail decoding rather than authorizing preservation. Already stored/delivered files are not rewritten. Metadata already removed from an older copy cannot be recovered.

Alternatives: mandatory removal conflicts with the request; a UI-only switch loses intent on gallery/cloud paths; copying arbitrary source metadata can expose original previews or incorrect geometry. Native ImageIO avoids dependencies. Existing actors/detached work own encoding; there is no new service or concurrency architecture.

Acceptance: both policies tested with synthetic tagged photos; metadata field presence/absence, all orientations, actual dimensions, omitted source previews, gallery relaunch/re-export, cloud round-trip and legacy default, invalid input/failures. Native UI selection and export flows, Release and existing test inventory remain required.

Owner authorization: explicit request approves this reversible privacy choice. No additional owner decision for local work. Cloud migration deployment, production configuration, signing/distribution and V4 merge remain owner-gated.
