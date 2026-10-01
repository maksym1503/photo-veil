# Veil V2.1 verification

PR #2 remains open for physical iPhone validation. These results do not certify a physical device.

## Root cause and correction

The old canvas used full image pixel dimensions as a zoomed UIView's frame. Its initial UIScrollView scale was the aspect-fit ratio (often much less than 1). When selecting a mode added the contextual toolbar, layout assigned the full pixel frame again while that transform was still active. UIKit then derived a different, enlarged bounds size. The bounds/source comparison caused repeated layout changes; the fit ratio and user zoom were coupled. This could turn a fit photo into a massively enlarged, displaced canvas.

The canvas now gives the zoom view aspect-fit bounds at user zoom 1. UIScrollView owns zoom/pan, exclusively. The contextual row retains a constant height. Mode changes, analysis results, blur rendering and region selection only update image content/overlays. Genuine viewport changes preserve the image point at the center and user zoom; loading a new source and explicit Fit reset to zoom 1. No transformed frame is assigned. Double-tap returns to Fit.

Manual regions are normalized image rectangles. The photo and overlay share one zoom view. One finger draws/moves/resizes; two fingers pinch/pan; the hand control permits one-finger navigation. Faces and Plate accept taps and native navigation without manual handles. Face oval rings were replaced with small corner marks. Cached manual handles are drawn only in Manual.

Background uses VNGenerateForegroundInstanceMaskRequest, without a person-only assumption. White selects the original sharp foreground; black selects blurred environment. The previous extra inversion was removed. Empty/full masks are rejected. Preview and export share the same cached mask; export scales that mask instead of rerunning segmentation. Region masks, blur radius, mask feathering and corner sizes scale with image resolution. Previews avoid a separate JPEG recompression.

## Executed checks

- Unsigned generic iPhone (iphoneos/arm64) build passed; this is a build check, not a physical-device run.
- Swift package: 10 tests, 0 failures. Includes top-left manual coordinates, letterboxing, zoom/pan mapping, mask polarity and vertical alignment, full-resolution mask scaling, blur-strength scaling, empty/full mask rejection and selected plate pixel rendering.
- iPhone 17 Pro Simulator, iOS 26.5, Xcode 26.6: six UI scenarios passed (faces, plate, manual editing/export, repeated mode switching, person background/fallback, car background/fallback).
- Faces test uses actual Vision face detection. No injected face rectangles. CPU execution is used only on Simulator because its GPU inference context cannot be created on this Intel Mac.
- An additional UI test passed for manual creation after pinch and pan: its accessibility frame matches the actual dragged screen rectangle within 2 points, and normalized image coordinates stay unchanged on return to Fit. Seven UI tests passed across the two runs.
- Manual runtime test covers create, move, resize, delete, undo, zoom/pan, Fit and native share sheet. It checks that camera movement never mutates normalized image coordinates.
- Mode switching checks user zoom and pan (within half a display point for native pixel rounding) before/after each analysis/mode update, and checks stale manual handles are absent.
- `render-parity.json`: Faces, Plate and Manual preview/export renders are pixel-identical for the deterministic fixtures, before JPEG encoding. The actual shared images are JPEG at quality 0.98, original dimensions and aspect ratio.
- Screenshots in this directory were inspected for full-photo fit, selected face blur, absence of circular face controls, plate blur, manual handles, region alignment after zoom/pan, and fallback copy. Full original screenshots and runtime details are in the local xcresult bundles.

## Background verification limitation

Both the person and car/environment fixtures were run. The Intel Simulator cannot create the foreground instance inference context, even with CPU execution. Both returned the visible Manual fallback and kept the camera stable. The automatic sharp-person/blurred-environment and sharp-car/blurred-street results, and their exports, were NOT visually verified here. The composite contract and scaled-mask export behavior are covered by pixel tests. Foreground segmentation still requires real iPhone validation.

## Physical iPhone acceptance gate

Install the HEAD of `feature/veil-v2-editor` with the PhotoVeil scheme. Verify initial Fit and repeated Faces → Manual → Plate → Background → Faces switching, including after pinch/pan. Verify face tapping and all-faces selection; plate tapping; manual creation while zoomed, movement, resizing, deletion and export; Background on both person/environment and car/environment photos; Original comparison; and exported images. Background must preserve the primary subject sharply. A failed analysis must offer Manual. PR #2 must not be merged until this validation is confirmed.
