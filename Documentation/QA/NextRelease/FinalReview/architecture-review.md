# Architecture / CTO findings — 2026-11-15

Actual role: configured `cto` (`.codex/agents/cto.toml`, gpt-6-astra, low),
explicitly invoked in the existing `/root/preview_cto` thread before the bounded
presentation correction and again for critical review. It implemented no code.
Root remains Engineering Lead; no duplicate Lead or nested agents were created.

## Reviewed change and result

CTO inspected the four production-file changes against the task-start snapshot:
`CommercePolicy.swift`, `PhotoVeilHome.swift`, `VeilGallery.swift`, and
`VeilPresentation.swift`. No blocking architecture findings were returned.

- Verified current Pro takes priority and receives clean presentation. Only a
  confirmed exhausted non-Pro state receives the lattice. Unknown/checking or
  unavailable state retains opaque protection in both editor and gallery; the
  unavailable notice does not claim the allowance was consumed.
- Shared `protectsPhoto` supplies existing canvas/gallery presentation bindings.
  No new rendering pipeline, persisted format, entitlement authority or navigation
  architecture was introduced. ADR-013 records the strict exhausted-only rule.
- Detection geometry, normalized region adjustments, category-scoped Undo,
  composition/rendering, zoom, native invalidation and export authorization are
  unchanged from this task's starting source. The renderer has no lattice input;
  the preview overlay remains outside exported/saved pixels.
- StoreKit verification/Restore/trial eligibility and usage history, limit,
  identities, schema and reservations are unchanged. Migration remains owner-gated.
- The CTA label sizing correction retains the native action style, action and
  accessibility identifier. CTO accepted the bounded fix subject to actual native
  measurements; final native evidence reports150.33 ×58 points and hittable true.

## Review finding resolved

The original capture helper moved then resized, but its first assertions did not
independently prove move-vs-resize behavior. CTO requested stronger evidence.
The revised helper separately asserts origin-only move, size-only resize, Undo
geometry and rendered restoration, single cached analysis, one Documents region,
and no Manual rectangles/strokes. CTO rechecked and accepted that test correction.
Both final native light/dark capture cases subsequently passed.

Actual dark UI must be produced and verified, not inferred from a launch argument.
CTO accepted explicit simulator appearance control around separate test invocations;
QA confirmed real dark pixels and restored Light (the preboot getter was unknown,
so exact restoration of an unobservable initial value is not claimed).

## Scope and remaining gates

[Baseline comparison](baseline-comparison.json) and [source hashes](final-source-hashes.json)
prove project/signing, renderer, geometry, StoreKit and ledger files were preserved.
[Task patch](task-only.patch.gz) includes files for which the initial snapshot retained
full text; the additional Commerce policy assertions are independently inspected
in the current test file and identified in the source hashes.

No approval of the missing dedicated Design Agent, irreversible migration, complete
release validation, signing, distribution or publication is implied. See the
separate Reviewer and QA reports for actual visual/native evidence and limits.
