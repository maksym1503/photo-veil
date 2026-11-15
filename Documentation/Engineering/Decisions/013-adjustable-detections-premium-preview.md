# ADR-013: Adjustable detections and premium preview

Date: 2026-11-14. CTO: read-only `gpt-6-astra`; authority: Lead / Maksym.
Status: geometry and preview presentation accepted; one-export migration proposed pending owner decision.

Production 1.0(7) is behaviorally reconciled from the owner's release statement,
matching retained candidate commerce-policy/test hashes, ADR-007/010 and the
subsequent build7 release record. The archived binary is unavailable locally;
this is not independently reproduced binary provenance. Preserve all existing
uncommitted release work, signing, product IDs and README's V4 acceptance gate.

Reuse normalized top-left geometry, the UIKit canvas, scoped history and the
single preview/export layer renderer. Cached detection identities remain stable.
Adjustments do not invoke Vision. Faces, plates, document details and whole-document
boundaries retain independent geometry. One completed gesture creates one undo
entry; category undo restores only that category's geometry and selection.

Keep the main-actor export lease, destination success callbacks, Keychain service
and `free-exports-v1` account, v1 format and decoding of historical counts 0/1/2.
The proposed new admission threshold is one; do not reset or reduce prior usage.
Applying it to existing count-one users removes their unused second export and
requires the pending explicit owner decision. No schema/backend migration.

Commerce preview marks belong to presentation, separately from user-authored
watermarks and shared rendered/exported pixels. Repeated, noninteractive marks
cover the visible photograph through zoom/pan, mode/final-preview changes and
async render publication. Shared observable usage and verified StoreKit access
control visibility. Unknown usage must not expose clean processed previews;
verified Pro removes marks without changing edits. No screenshot interception.

Alternatives: keeping current behavior misses release intent; a backend quota,
billing SDK or second renderer adds privacy/maintenance cost without resolving
local success accounting. Native reuse requires no dependency/provider activation.

Risks: historical two-export expectations; touch arbitration; stale async previews;
initial entitlement/storage loading; separate document coverage indices. Existing
success-first accounting cannot atomically commit external Photos/Share success
and Keychain across process death (ADR-007). Device allowance is not per account.

Validation: normalized geometry/edges, multiple regions, scoped undo/cache,
preview/export parity, historical usage 0/1/2, cancellation/failure/concurrency,
dirty storage, native StoreKit trial/restore/expiry and presentation transition
coverage. Independent review and QA precede owner acceptance. No merge, upload,
distribution or App Store modification is authorized. Three marketing directions
and two preview concepts must be saved for owner review; final marketing production
waits for explicit selection.

## Interaction validation follow-up

The first native PR run exposed a product interaction failure: a plate's visible
corner drag did not commit while face resize and the other five UI smokes passed.
Automatic regions now use UIKit's one-touch pan recognizer and a tap recognizer
that requires the pan to fail, rather than competing raw touch and native tap
recognition. The existing manual gesture handling remains. Corner hit areas scale
with small region dimensions to preserve a draggable body; explicit VoiceOver
resize actions remain available. This is a bounded canvas interaction correction,
not a geometry/rendering architecture replacement. Retain the failed run separately
from corrected execution; do not claim its 94/95 result was green.

A stronger native assertion then exposed move-vs-resize misclassification when
classifying from the pan's later recognition location. A small native pan subclass
now records the actual first touch and resets it with the recognizer lifecycle.
Hit classification uses that point; normalized updates/commits remain native.
Possible and active pans are cancelled on source, coverage, geometry or layout
changes. Independent Reviewer reassessed and accepted this bounded correction.


## Approved visual refinement and preview integration — 2026-11-14

Maksym selected **Editorial Calm** and **Quiet Lattice** for further development,
explicitly withholding final asset/release approval. Produce five photographic,
actual-UI screenshot candidates and light/dark redacted preview evidence for review.

CTO (`gpt-6-astra`) approved preview presentation independently of migration.
Keep the existing two-export threshold and ledger identity/schema unchanged until
Maksym decides existing-user treatment. Derive presentation from actual limit,
not a hardcoded count. `loadSnapshot` is read-only and retains dirty success in
memory. Verified current Pro wins even if usage is unavailable. Known remaining
allowance is clean. Exhausted/unknown usage plus unknown entitlement shows an
opaque checking cover, avoiding both clean edited-frame leakage and an unverified
Pro watermark. Verified free plus exhausted usage shows the lattice; unavailable
usage uses honest access-unavailable messaging, never claims the allowance was used.

Preview-specific entitlement state is independent of advertising/product loading.
Epoch + existing revision checks reject scans preceding invalidation. Leaving active
state, relevant unverified updates and fresh scans invalidate preview readiness.
Synchronous native notification covers canvas/gallery before SwiftUI reconciliation
and before the app-switcher privacy shield is removed. A completed current scan
removes protection or shows the pattern immediately, without changing export access.

The noninteractive native lattice remains in screen coordinates, clipped to the
visible photograph through zoom/pan/layout. It is separate from custom user
watermarks, Core Image layers, exported bytes, thumbnails and persisted gallery.
One accessible element labels it; no repeated announcements or screenshot hacks.
The compact Preview Mode notice opens the existing StoreKit paywall; it never
opens automatically. No backend, provider or dependency changes.

Validation: pure state/epoch/read-only dirty-ledger cases; native Pro purchase,
restore, expiration and revocation assertions; exhausted real-success UI flow,
mode/Undo/zoom/pan/final preview/relaunch and gallery presentation; matching
underlying export fingerprints; light/dark actual redacted photo captures.
This accepts the technical preview integration, not migration or final publishing.


## Owner-directed final review — 2026-11-15

The owner explicitly requires lattice marks **only** for confirmed exhausted
allowance without verified Pro. This supersedes the earlier unavailable-usage
lattice choice above. `.exhausted` alone is marked; `.checking` and `.unavailable`
receive opaque photo protection, with unavailable access retaining honest storage
error/restore guidance. Verified current Pro and known remaining usage are clean.
A shared `protectsPhoto` property supplies both canvas and gallery bindings. No
quota threshold, usage identity/schema/history, entitlement, geometry, renderer or
export contract changes. CTO accepted this bounded correction; policy assertions
cover all four presentation states. Screenshot captures now demonstrate solid plate
redaction and genuine moved/resized Documents detections, without Manual fallback.
