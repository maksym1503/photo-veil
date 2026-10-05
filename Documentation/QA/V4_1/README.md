# Veil V4.1 — physical feedback follow-up

Continue `feature/veil-v4`, Draft PR #4. No merge. The owner’s V4 physical-device findings are the reason for this pass; another iPhone review is required.

## Findings and fixes

### Gallery

Captured and visually inspected the running V4 Gallery before changing product code. On the current iOS 26.5 Simulator the old delete button was **already at the bottom**; the reported top placement was not reproduced here. The old implementation inserted/removed a conditional individual toolbar item alongside a separate safe-area status view. V4.1 makes the root bottom `ToolbarItemGroup` persistent, keeps navigation at the top, and puts selection count plus semantic destructive trash in that native bottom group. No manually positioned floating button. The first after screenshot caught a truncated count; that was fixed and recaptured. Accessibility XXXL also exposed a clipped large title and oversized selection marker. Accessibility sizes now use an inline title and one-column grid; selection uses a restrained symbol plus the semantic selected trait. A real edge tap verifies the native trash action is reachable at the edge of a 44-point target; its smaller accessibility frame describes the visible control, not the full hit area.

Found an additional real failure in the previous PR CI artifact: a completely blank Gallery Share sheet. Two separate URL/presentation states allowed the sheet to be created without an item. Both Gallery and editor now present `.sheet(item:)` from one URL-bearing value. The URL exists when the sheet is constructed and its temporary file is removed when dismissed. The existing Share test was retained, not weakened.

### Editor/effects root cause

The old horizontal tool ScrollView used five intrinsic-width labels with only a minimum cell width, variable SF Symbol bounds and no common icon/label baseline boxes. Its effect row changed intrinsic size (`Redact · Black`) while removing the strength control; async Documents results inserted additional text into another unconstrained row. Each of several neighboring controls also owned its own glass/button treatment. These state-dependent layout proposals and native menu/control updates produced moving geometry rather than a stable toolbar contract.

This is a **source/layout finding**, not proof of an undocumented SwiftUI identity or SF Symbols bug. The complete progressive corruption reported on hardware was not reproduced in the initial three-round Simulator baseline. No unstable `ForEach` identity was found. The implementation fixes the structural causes, rather than adding offsets or animation workarounds to individual labels.

V4.1 uses stable mode IDs, equal-width tool cells, fixed icon/label alignment boxes and a consistent selected surface. The existing Reduce Motion-aware press enlargement remains. Effect style and its parameter occupy consistent slots; Redact color replaces intensity in the parameter slot. Contextual tool controls occupy one fixed row. One native system glass/material panel groups those controls instead of independently resizing glass buttons. Larger Text uses native menus and vertically arranged effect controls. Detection state no longer inserts helper text into the control geometry.

### Work during switching

Background and Plate analysis previously had no in-flight task guard; an unavailable Background result was not cached. Repeated selection could duplicate Vision work. Both now use per-session task guards/results, including negative Background results; Faces/Documents retain their existing guards. Clearing/replacing a photo cancels tasks. Effect/strength changes reuse geometry/masks; selecting the current value is a no-op. Cancelled queued preview tasks exit before Core Image work, while already-running synchronous renders can finish and are rejected by the existing revision check. The brush coalescer is preserved. No renderer, geometry or Vision algorithm rewrite.

DEBUG-only test counters contain only request counts, never image/OCR/account data. The final stress test verifies one analysis-pipeline invocation per tool after warm-up and no additional requests during repeated tool/style switches. Simulator automation timing includes XCTest/menu delays and is not a claim about physical-device frame rate.

## Screenshot evidence

Baseline captured from running V4 (`7dc7e47`) before product edits, using `testV41RenderedControlsAndGallery` and a clean local gallery. After screenshots come from actual Simulator test runs. The committed JPEGs are reduced copies of original XCTest PNG attachments to keep the repository small; no controls/photos were reconstructed or retouched. Full-resolution originals remain in local xcresult bundles and CI artifacts.

| Evidence | Device / appearance | States |
| --- | --- | --- |
| `before-*.jpg` | iPhone 17 Pro, normal text, light | Gallery normal/selected; five tools; three effects; ellipse controls; initial stress |
| `after-*.jpg` | iPhone 17 Pro, normal text, light | Corresponding final controls, selected gallery, final stress; account availability and disabled provider preview |
| `compact-*.jpg` | iPhone 13 mini, dark | Representative Manual/Pixelate/Redact, Gallery, final stress; full tool sequence in xcresult |
| `largest-*.jpg` | Narrow iPhone, accessibility XXXL | Adaptive tool/parameter menus, Manual controls, Blur/Pixelate/Redact, Gallery normal/selection |

## Verification results

- **39 core tests passed**, including the opt-in real Vision fixture benchmark (`VEIL_RUN_DETECTION_BENCHMARK=1 swift test`). This includes configuration parsing, project-scoped session keys, mock auth lifecycle, gallery persistence/deletion, geometry/detection merging, effects and preview/export semantics.
- **All 19 tests in the full UI suite at that stage passed** on iPhone 17 Pro. This retained all V3/V4 tests and added native provider rendering and eight-round tool/effect stress. Subsequent focused tests add parameter/color switching, accessibility Gallery deletion and rapid rendered-state changes: **22 unique UI tests now pass across full and targeted runs**. The new stress tests also pass on the narrow phone.
- Native stress compares every tool cell's frame against its initial frame, checks selected state, unchanged canvas transform, effect/parameter separation and one cached analysis-pipeline invocation per tool. Multi-delete saves two local outputs while signed out, selects both and deletes through the native bottom action.
- A complementary DEBUG-only script drives the real selection actions for 12 rounds at 40 ms intervals without XCTest idle waits. Its first attempt timed out while parity instrumentation encoded/hashed/wrote PNGs on the main thread. That unrelated instrumentation is disabled only for this layout script; all parity tests retain it. The rerun passes and the actual final screenshot is inspected (`compact-rapid-state-final.jpg`). This is not a physical-device frame-rate claim.
- Three Edge Functions pass Deno checks; all five mocked server deletion tests pass. PostgreSQL ownership, private namespace, Vault privilege and cleanup tests pass against an isolated disposable database. Hosted Supabase/real Storage HTTP authorization is **not** validated without owner configuration.
- Unsigned Release build passes. Release has add-only Photos usage text, no broad Photo Library read usage text, no backend config, no bundled test JPEGs and no DEBUG account/analysis diagnostics.

Local evidence bundles: `/tmp/veil-v41-before.xcresult`, `/tmp/veil-v41-full.xcresult`, `/tmp/veil-v41-compact.xcresult`, `/tmp/veil-v41-parameters.xcresult`, `/tmp/veil-v41-final-compact.xcresult`, `/tmp/veil-v41-gallery-adaptive.xcresult`, `/tmp/veil-v41-rapid-fixed.xcresult` and `/tmp/veil-v41-rapid-modern.xcresult`. The initial narrow Gallery target-size assertion incorrectly equated visible AX bounds with hit area; it was replaced by an actual successful edge tap. The parameter stress in that same run passed. These local bundles are not committed; CI uploads runtime results.

Visual inspection included actual full-resolution Gallery before/after, all tools/effects across the captured sequence, dark narrow contact sheets plus full screenshots, accessibility menus/Gallery, account local/provider-preview states and populated native Share. Background segmentation falls back to Manual on this Intel Simulator: that screenshot is fallback evidence, not proof of real-device Background segmentation. Reduce Motion/Transparency behavior was preserved in source; another physical-device check is listed below.

The previous ARM-hosted CI attempt failed before acquiring a runner (no app build/test steps ran). Workflow now uses the standard supported `macos-26-intel` runner; tests are unchanged. See [official runner images](https://github.com/actions/runner-images#available-images). Final CI status is reported on PR #4 rather than frozen into this document.

## Account readiness

The inspected checkout has no `Configuration/VeilBackend.plist`, so the shipped local test build has no Auth client. The Apple entitlement source exists but the default `VEIL_ENTITLEMENTS_FILE` is empty. Supabase project/provider/dashboard state cannot be verified without owner setup. V4.1 keeps local features usable and displays product-level local availability instead of a developer error. DEBUG-only closed diagnostics identify the missing/invalid configuration without printing values.

With valid public configuration Google controls appear; Apple additionally follows the capability flag. A DEBUG-only disabled provider rendering fixture tests those same native controls without an Auth client, fake credentials or a successful-login simulation. Live Apple/Google, hosted Storage and deletion/revocation remain owner-required. See [ordered backend setup](../../Backend/BACKEND_SETUP.md).

## Physical-device review

- Gallery: save two images, relaunch, Select both; trash remains at bottom, Cancel/Close at top. Confirm/cancel bulk deletion; open a saved photo and Share.
- Editor: repeat all five tools and Blur → Pixelate → Redact → Blur rapidly; change intensity/color/shape. Check alignment, selected state and responsiveness during initial Vision work.
- Check normal and Larger Text, light/dark, narrow display, Reduce Motion and Reduce Transparency. No tool should shrink below a comfortable target or cover the photo unexpectedly.
- Verify rectangle/ellipse/brush, undo, pan/pinch/fit, Done/Edit, clean preview, Share, Save to Photos and Save to Veil. Inspect exported result against preview.
- Verify small background faces, Plates and Documents still behave as in physically approved V4. Background’s Simulator fallback does not validate real-device segmentation.
- After owner setup: native Apple including Hide My Email, Google browser cancellation/callback, relaunch restoration/profile, offline sign-out, explicit sync consent, two-account isolation, cloud deletion and account deletion/revocation. Local history must survive sign-out/account deletion.
