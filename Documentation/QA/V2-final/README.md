# Veil V2 final focused verification

The user confirmed Background, Faces, zoom/pan and rectangular Manual editing on physical iPhone before this pass. This pass changes Plate selection, adds the missing brush pipeline, and adds Done/Edit preview. The existing detector, foreground compositing, canvas transforms and rectangle gestures are preserved.

## Corrections

- Yellow dashed outlines represent detected plate candidates, including unselected ones. They were not proof of a populated blur mask. Plate selection previously relied on raw touch callbacks competing with UIScrollView navigation. A dedicated UIKit tap recognizer now toggles the same selection set consumed by region rendering and export. Selected candidates have a solid outline/fill; strength changes reuse their image-space masks. The detector is unchanged. Simulator assertions compare actual rendered-image fingerprints after selection and between Low and Strong.
- The pencil/navigation toggle previously enabled rectangle creation only. No freehand stroke model or mask existed. The explicit Paint blur control now records normalized top-left image points and a proportional brush width. Round-capped paths populate the shared Core Graphics mask, which Core Image uses for both live previews and original-resolution exports. Touch samples are coalesced with one brush render in flight. A completed stroke is one undo step. Rectangle editing retains its existing gestures and handles.
- Done hides all detection/manual overlays and on-image controls while retaining the processed photograph and camera transform. Edit restores the existing state. Hidden bottom controls retain their layout height, preventing a fit/zoom jump. Share exports the same regions, strokes and masks used by preview.

## Executed verification

- `swift test`: 12 tests, zero failures. Includes plate pixel rendering and Low/Strong difference, painted pixels at all three strengths, sharp pixels outside a stroke, coordinate transforms, rectangle rendering, foreground mask polarity and scaled masks.
- Xcode 26.6, iPhone 17 Pro Simulator, iOS 26.5: eight UI tests passed in `/tmp/veil-final-verified.xcresult`. Covers real face/plate detection, plate selection/strength, brush draw/undo/zoom/pan, rectangular create/move/resize/delete/undo, zoomed rectangle creation, mode switching, clean preview/Edit, and native share sheet.
- Final Done/Edit control gives each title a distinct SwiftUI identity so the previous title cannot linger during preview transitions. The Plate and brush flows were rerun after this adjustment.
- Unsigned generic iPhone build passed. This is a compilation check, not a physical-device run.
- `render-parity.json`: Plate, Faces, rectangular Manual and brush Manual preview/export pixels match exactly for deterministic fixtures before JPEG encoding. Each differs from its original. Low and Strong plate output pixels differ. Shared files remain original-size JPEG at quality 0.98.
- Simulator screenshots inspected for visible plate/brush blur, zoom attachment, clean preview without editing overlays, and readable compact controls. Representative screenshots are beside this document; full screenshots remain in the result bundles and CI artifacts.

## Runtime limits

No new physical-device run was performed here. The user supplied positive physical validation of the preserved functionality. This Intel Simulator still cannot run foreground instance inference and returns the existing Manual fallback for both person/car fixtures; background mask semantics remain covered by pixel tests and prior user validation.
