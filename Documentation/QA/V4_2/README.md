# V4.2 — targeted physical-device feedback

Existing `feature/veil-v4`, Draft PR #4. Do not merge; another physical-iPhone review is required. The approved V4.1 editor layout, typography, effects and account state are preserved.

## Before evidence

Captured the running V4.1 landing and **actual visible Gallery delete confirmation** before changing either surface. The screenshot reproduces the reported issue: the destructive confirmation is an upper popover, although the initial toolbar trash is correctly at the bottom. The dialog modifier was attached to the photo viewer rather than the bottom action; iOS 26's native adaptation anchored it near the viewer's top. Its outside-tap dismissal also provided no Cancel button; the capture harness's attempt to tap Cancel failed after successfully capturing the required state. This is recorded rather than treated as a passing baseline test.

`before-landing.jpg`, `before-gallery-delete-action.jpg`, `before-gallery-delete-confirmation.jpg` were actually inspected. Full native PNGs: `/tmp/veil-v42-before.xcresult` attachments. Committed JPEGs are reduced to a maximum 1300-pixel dimension to bound repository size; no UI or images were reconstructed.

## Implementation

- Landing removes the principal Veil title and outer hero card/clip/pill. The same code-native portrait fills the available page width, with semantic light/dark background gradients blending its top/bottom into the screen. Native Choose Photo, headline and privacy reassurance remain. The 2.2-second conceal/reveal transitions, 1.4-second holds and static Reduce Motion alternative are unchanged.
- One shared automatic selection lifecycle separates detection status/cache from applied selection. Clear All retains cached geometry; re-entry activates it. Documents uses its existing chosen coverage. Background clears only the effect; Manual clears all shapes/strokes with Undo. Partial Face/Plate selections now clear together; Hide all remains available after clearing.
- Successful zero results: `No faces detected. Try Manual.`, `No plates detected. Try Manual.`, `No documents detected. Try Manual.` Failures use `Couldn’t detect <category>. Try Manual.` Background fallback uses `Background unavailable. Try Manual.` The small status capsule sits within the photo, above the controls, expires after six seconds (ten with VoiceOver), announces once, and has no motion transition. It does not block interaction or insert a control row. Pending analysis produces no zero-result message.
- Single and bulk deletion use the same native compact sheet with semantic destructive action and explicit Cancel. Accessibility sizes use a larger detent. Local-only copy states removal from this iPhone; linked items explain cloud deletion when sync resumes. The existing protected-file deletion and tombstone semantics are unchanged. Trash placement is unchanged.
- Returning to an in-flight analysis now keeps the progress indicator and Done disabled state tied to the selected tool’s detecting status, separately from preview rendering. A DEBUG-only delay test lets real Vision finish after leaving/re-entering Faces; it does not fake detections.
- No account/backend changes.

## Physical review

1. Landing in light/dark: no top-center title or outer rectangular hero; portrait blends into the page, text readable, Choose Photo obvious. Watch two full blur/reveal cycles; check static Reduce Motion and Larger Text scroll access.
2. Faces/Plates/Documents: activate → active; Clear All → inactive; remain and toggle individual regions; leave for Manual → return → all cached regions active. Repeat ten times; canvas transform must not move.
3. Background: Clear All restores unmodified background; Undo restores effect; leave/return reapplies cached mask. Check real-device segmentation (Simulator fallback is not proof of success).
4. Manual: rectangle + ellipse + brush → Clear All → empty; Undo restores all.
5. Photo with no faces/plates/documents: no message while detecting; concise transient feedback after zero results, then disappears. Switch tools during analysis; late messages must not appear for the old tool.
6. Gallery: open saved photo → bottom trash → **bottom confirmation** → Cancel keeps photo; Delete removes it. Repeat with multiple selected photos and Larger Text. Confirm cloud wording only after a real item is linked during the separate owner setup task.
7. Recheck PhotosPicker, Save to Photos/Veil, Share, effects, strength, zoom/pan, Done/Edit and preview/export parity.

## Executed verification

- 42 core tests passed, including the opt-in real Vision benchmark and three shared selection-lifecycle tests.
- Five focused modern-phone UI tests passed: real Faces/Plates/Documents cached activation, all Manual shapes/strokes clear/Undo, Background controlled cached-mask clear/Undo/export, actual empty Vision results and Gallery cancel/delete.
- Five narrow-phone/dark UI tests passed: Gallery accessibility deletion, zero-result feedback, final bottom confirmation, repeated animation and XXXL landing scroll/action access.
- Reduce Motion was enabled through the actual Simulator preference and independently verified as `Static blurred portrait`; the screenshot was inspected. The preference was restored afterward.
- Three Deno checks, five mocked deletion tests and isolated PostgreSQL ownership/Vault cleanup checks pass. These are unchanged backend regressions, not provisioning or live cloud/provider validation.
- The complete 29-test UI suite passed with zero failures (`/tmp/veil-v42-regression.xcresult`), retaining all V3/V4/V4.1 regressions. The subsequent pending-state fix additionally passed two targeted UI tests on the final source (`/tmp/veil-v42-pending.xcresult`), bringing coverage to 30 unique UI tests; CI runs the complete 30-test suite. Native eight-round tool/effect/Gallery stress and 40 ms state stress passed. Automation includes XCTest idle waits and DEBUG parity PNG work; its elapsed time is not a device frame-rate claim.
- Final unsigned iPhone Release build passed. Add-only usage text remains; broad Photos read text is absent. Test photos, synthetic blank/mask fixtures, delay/stress flags and selection-count diagnostics are excluded from Release. No backend config is bundled.
- Actual final iPhone 17 Pro light/dark landing screenshots were inspected after installing the final source build. Both blend into their semantic page backgrounds, with readable headline/action and no top-center title. Simulator appearance and Reduce Motion preferences were restored after QA. A temporary extra visual Simulator was removed; the owner’s existing Simulators were not deleted.

Background effect clear/Undo/export uses an explicitly controlled cached-mask fixture to test activation independently of Intel Simulator segmentation support. Real Vision is used for Faces/Plates/Documents and empty-scene feedback; real-device Background success remains on the physical checklist. No claim of 100% detection is made.

Full PNG/result evidence is local in `/tmp/veil-v42-focused.xcresult`, `/tmp/veil-v42-compact.xcresult` and `/tmp/veil-v42-motion.xcresult`; committed JPEGs are representative reduced copies. Contacts composed solely for local inspection are not committed. The main before/after Gallery confirmation, all three zero-result messages and Background failure, all three real detection lifecycle sequences, Background clear control, Manual menu, modern light/dark and small dark landing/confirmation, XXXL top/action and static Reduce Motion screenshots were actually inspected. The first landing iteration showed a subtle top boundary; the final gradient starts at the exact semantic screen background color to blend it away.

The first complete-suite attempt still expected the old permanent Background fallback sentence. That assertion was updated to the new transient feedback, retaining fallback/canvas checks; the suite was restarted. No functional test was removed.


## Representative files

| Evidence | Captured state |
| --- | --- |
| `before-landing.jpg` / `after-landing.jpg` | iPhone 17 Pro light, original card/title → integrated portrait |
| `after-modern-landing-dark.jpg`, `after-small-landing-dark.jpg` | Final modern/narrow dark composition |
| `after-largest-landing-dark-top.jpg`, `after-largest-landing-dark-action.jpg` | Narrow XXXL hero/top and scrolled, reachable primary action |
| `after-landing-reduce-motion-dark.jpg` | Actual Reduce Motion setting, static blurred portrait |
| `before-gallery-delete-confirmation.jpg` / `after-gallery-delete-confirmation.jpg` | Actual upper popover → native bottom confirmation |
| `before-gallery-delete-action.jpg` / `after-gallery-delete-action.jpg` | Initial trash remains at the bottom |
| `after-small-gallery-confirmation-dark.jpg` | Narrow/dark bottom confirmation |
| `after-empty-{faces,plate,documents}.jpg`, `after-small-empty-documents-dark.jpg` | Real Vision zero-result feedback |
| `after-background-unavailable.jpg`, `after-background-clear-control.jpg` | Actual fallback; controlled cached-mask clear control |
| `after-{faces,plate,documents}-{active,cleared,reactivated}.jpg` | Cached category activation lifecycle |
| `after-manual-clear-menu.jpg` | Rectangle + ellipse + brush, existing menu with Clear All |

Native sheet sizing uses [SwiftUI presentation detents](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)); unlike the old viewer-attached confirmation, its bottom presentation does not depend on a popover anchor. Latest CI status is kept in PR #4 checks and the handoff rather than frozen into this report.
