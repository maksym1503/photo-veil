# ADR-006: Three privacy pillars and native text watermarks

Status: accepted · Date: 2026-10-11 · CTO: gpt-6-astra (read-only) · Authority: Lead under the owner's explicit product request.

**Problem:** Veil's presentation and editing focus are concealment-first. Add first-class watermarking without compromising existing redaction, metadata choices or reliable export.

**Decision:** Keep pillar focus (Redact, Metadata, Watermark) separate from existing automatic/manual categories. Use an immutable, Equatable, bounded watermark value with normalized image-space center/size, rotation, opacity, native text style and single/repeated layout. Render a tightly bounded transparent Core Text tile and source-over composite it after all privacy layers in the same Core Image graph, with one completed-image materialization. Preview/cache/export snapshot includes watermark state. Failed enabled rendering blocks export; no unwatermarked fallback. Blank text is explicitly rejected at UI commit; core empty text is a no-op. Text/geometry/repetition limits prevent unbounded work; nonfinite/invalid state fails rendering.

**Interaction/state:** Explicit Add applies a useful default. Direct one-finger image-space dragging plus placement presets; two fingers continue navigation. Accessible native alternatives cover size, opacity, rotation, style and repetition. One committed text/slider/drag change creates one scoped watermark undo record. Global Reset/undo includes watermark; other category undo cannot restore old watermark state. Session replacement/close clears text and queued previews.

**Data lifecycle:** Only flattened processed output is persisted locally/shared/optionally synced; no watermark text preference, logging, recipe, new index field or backend migration. Existing gallery re-export retains visible marks without reapplying them. Remove/Keep metadata remains independent; Keep remains the default for new sessions. Originals stay unchanged. Saved/shared pixels intentionally expose entered watermark text; watermarking is a usage cue, not a guarantee against removal or misuse. Debug evidence must exclude custom-watermark images/text; approved synthetic test text is explicitly gated.

**Alternatives:** No change misses the requested pillar. Third-party editors add dependencies and lifecycle risk. A screen-only overlay breaks export parity. Persisting editable recipes/templates expands privacy/storage scope without an immediate requirement.

**Performance:** Keep the current serialized preview actor and revision/session guards. Avoid full-frame watermark bitmaps; bound glyph tiles and repetition. Do not re-encode between editing stages. Existing final JPEG encoder and protected output lifecycle remain. Physical 12–48 MP color/memory/gesture acceptance remains required.

**Acceptance:** Deterministic native tests for watermark-only and combined output, redaction overlap, normalized transformation/rotation/repeat/clipping, Unicode/invalid/empty input, preview/export parity, cancellation, scoped/global Undo, local persistence/re-export and both metadata policies. Native UI checks for direct positioning, text/defaults, deletion/Undo, accessible controls and all existing V4 regressions. Release fixture exclusion remains enforced. Extend existing test layers and inventory, no new test architecture/provider.

**Operations/reversibility:** Native Apple frameworks, no dependency/service/billing/signing changes. Feature/state changes are locally reversible. No owner input needed for these technical choices. Persistent custom templates/cloud recipes, production rollout/configuration/distribution and V4 merge retain owner gates.

Research: [Darkroom](https://darkroom.co/help/export/watermark) pairs direct dragging with placement anchors and focused adjustments; [ZLImageEditor](https://github.com/longitachi/ZLImageEditor) demonstrates native text stickers/gesture coordination. Review ideas only; no copied implementation/assets. Rendering uses [Core Text](https://developer.apple.com/documentation/coretext) and [Core Image compositing](https://developer.apple.com/documentation/coreimage/ciimage/composited(over:)).
