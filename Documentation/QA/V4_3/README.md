# V4.3 final composition QA

## Scope and result

Privacy categories are independent layers. Editing focus does not remove another category. Each category retains its own effect, strength and redaction color. Clear All and Undo are scoped to the edited category; cached re-entry reactivates that category without rerunning analysis. Global Reset remains separate.

The renderer evaluates one accumulated Core Image graph. Soft effects are ordered from lower to higher strength, with stable category order for ties; opaque redaction is last. A later layer never blends sharp original pixels back into an earlier concealed area. Preview, Done and all output actions consume the same layer snapshot. Region evaluation is bounded without reducing export resolution.

## Validation performed

- Core: 47 tests passed, including both opt-in Vision/composition benchmarks (no skips in this local run).
- Complete Simulator regression: all 34 cases then present passed, including existing V3/V4/V4.1/V4.2 regressions. The final additional history stress case and the composition/scoped Undo cases passed in a subsequent 3-case run. Four compact-device cases also passed, including the full-composition Save to Veil/Share workflow. Final CI runs all 35 UI cases on the final commit.
- Backend: isolated PostgreSQL ownership/Vault privilege checks passed; five deterministic account-deletion tests passed; all three Edge Functions passed Deno checking. No live backend credentials were used.
- Release: unsigned arm64 Release build succeeded. Picker access remains narrow; only the existing add-only Photos usage description is included. New fixture, delayed-analysis and fingerprint hooks are DEBUG-only.
- The three-layer workflow verifies Faces → Plates → both remain active → scoped Clear All/re-entry → Manual → Done → Save to Veil → Share. Export fingerprints verify the actual rendered output, not just selected controls. The full five-layer workflow also saves locally and presents Share.
- Renderer coverage includes every requested two-, three- and five-category combination, mixed effects, overlapping masks, preview/export equality and category removal.
- Undo stress performs more than 30 automatic edits without evicting Manual history. Pending analysis keeps Done unavailable even after changing editing focus.

## Screenshot inspection

Screenshots were rendered and visually inspected on iPhone 17 Pro (Light) and iPhone 13 mini (Dark), with a separate Larger Text case. The approved typography, symbols, menus and navigation remain unchanged. The only visual correction is intrinsic-width optical centering of the five-item tool row: visible outer margins measure 32.17 pt on the Pro and 29.5 pt on the mini. No device-specific padding is used.

| Evidence | State |
| --- | --- |
| toolbar-before-pro-light.jpg / toolbar-after-pro-light.jpg | Pro toolbar before/after |
| toolbar-before-mini-dark.jpg / toolbar-after-mini-dark.jpg | Compact toolbar before/after |
| faces-plates-pro-light.jpg | Faces and Plates simultaneously active |
| background-faces-plates-pro-light.jpg | Three automatic layers |
| mixed-three-layers-pro-light.jpg / mixed-three-layers-mini-dark.jpg | Faces Blur, Plates Pixelate, Manual Blur |
| three-layers-done-pro-light.jpg | Clean combined preview |
| full-five-layers-pro-light.jpg / full-five-layers-mini-dark.jpg | Background, Faces, Plates, Documents Redact and Manual Pixelate |
| full-done-pro-light.jpg | Five-layer clean preview |
| full-share-mini-dark.jpg | Native Share presented for the combined output |
| larger-text-mini-dark.jpg | Existing adaptive menu at Larger Text |

The combined document fixture is assembled from existing test assets. Faces (2), Plates (1) and Documents (4 proposed regions) use real Vision analysis. Background uses the explicit DEBUG-only cached-mask fixture because foreground segmentation is unavailable on this Intel Simulator; this is not evidence of real-device segmentation accuracy. No new physical-iPhone test was performed during this pass.

## Performance and limits

`composition-performance.json` records a controlled five-layer graph plus forced JPEG encoding on this Intel Mac: approximately 0.22 s at 1440×1800, 0.69 s at 4032×3024 and 3.24 s at 8064×6048. These are single-run diagnostic measurements, not iPhone latency claims. Changing focus with unchanged layer geometry/settings reuses the completed preview; cached detections are not rerun.

Final PR CI is the required merge gate. Owner-controlled authentication provisioning remains a separate setup task. No account/backend UI or configuration changes were made in V4.3. Local DEVELOPMENT_TEAM overrides are excluded from commits.

## Final stress-test stabilization

The hosted attempt at `920090b` was slow but still progressing. Its cancelled runtime artifact recorded 29 passing UI cases and two timeout cases. The rapid-selection case did not reach its final completion marker; the Undo-history case timed out waiting for its initial render before the retention loop, while its subsequent Undo/selection assertions passed. This evidence does not establish an Undo-state corruption bug.

Two unnecessary costs were identified: cancelled detached preview tasks could continue synchronous Core Image evaluation concurrently, and DEBUG evidence capture performed six PNG encodes per published preview on the main thread. Preview evaluation now runs through one actor, skipping cancelled queued work and discarding cancelled in-flight output. The existing revision guard still controls publication; export uses the unchanged shared renderer. DEBUG evidence is encoded/hashed once off the main thread before publishing completion. Original fixture evidence is written once.

The exact production per-category history policy is now `ScopedUndoHistory`, with unchanged capacity and global-Reset semantics. Core tests perform 1,000 edits for each of Background/Faces/Plates/Documents and verify all 30 Manual snapshots survive in order. A deterministic blocked-render test queues 500 obsolete requests, cancels them, and verifies only the running request and latest request evaluate pixels; the latest output exactly matches export.

Native UI stress keeps two rapid cycles at the original 40 ms cadence, including an actual Manual region so effect changes affect pixels. The Undo UI case analyzes once, creates and verifies a Manual edit, performs representative cached clear/re-entry cycles, and checks both selection state and exact restored automatic-layer pixel fingerprint. Neither test timeout was increased. Focused tests passed locally in approximately 17 and 28 seconds.

Final local validation: all 50 core tests passed with both opt-in benchmarks enabled; all 35 UI cases passed in 1,281 seconds; Release build, PostgreSQL ownership/Vault checks, five Deno deletion cases and Edge Function checks passed. The two affected cases also passed in the full run (approximately 16 and 28 seconds). Final CI remains the merge gate and is reported in the PR handoff. No UI design, image effects, detection algorithms, account configuration or signing overrides were changed by this stabilization.

## Documents analysis synchronization

Hosted run `37637398123` passed both stabilized stress cases and 34/35 UI cases. The remaining Documents case timed out in its generic 45-second render wait, followed by its 10-second region wait. Its downloaded screenshot and accessibility hierarchy still showed `detectionInProgress` approximately 57 seconds after activation. A later hierarchy, approximately 105 seconds after activation, showed four active detail regions and `processingComplete`; whole-document redaction and Share subsequently succeeded. This was a completed test run returning exit 65, not a workflow timeout.

The document pipeline already executes image preparation and synchronous Vision requests in a detached task. Rectangle/document localization, transient OCR and face geometry are published together on the main actor, followed by rendering. No document-processing or presentation code was changed. The UI case now waits for the actual first detected region, which cannot exist until analysis publishes its result, with a 120-second cap scoped only to real asynchronous document analysis and supported by those measured hosted timings. It then asserts pending analysis is absent and separately uses the unchanged 45-second render wait. Empty or failed detection cannot satisfy the region predicate. There are no sleeps, fixture substitutions, skipped cases or CI timeout changes.

The test also asserts details Blur/Redact differ, whole-document coverage changes pixels, toggling the whole region off/on restores exactly the previous rendered fingerprint, and analysis runs only once. Existing multi-layer renderer/export, pending-versus-empty state and cached-selection tests remain intact. The focused Documents run passed in 36.364 seconds; its details-blur and whole-document-redaction screenshots were rendered and inspected. Real Vision remains covered in this UI test and the opt-in core diagnostic, which was rerun locally.

Final Documents stabilization validation: all 35 UI cases passed locally (Documents 34.591 s), all 50 core cases passed with opt-in Vision/composition benchmarks enabled, unsigned Release build passed, PostgreSQL ownership/Vault checks passed, and all five Deno deletion tests plus Edge Function checks passed. No implementation, UI, provider configuration or workflow changes accompany this test-only stabilization. Final hosted checks remain the merge gate.
