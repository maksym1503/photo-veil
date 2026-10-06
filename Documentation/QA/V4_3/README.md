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
