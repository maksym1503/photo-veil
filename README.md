# Veil

A focused, private photo utility: choose a photo, blur sensitive areas, export. Image analysis and rendering run locally with PhotosUI, Vision and Core Image. No account, backend, analytics or persistent edit library is included.

## Build

Open `PhotoVeil.xcodeproj`, choose the `PhotoVeil` scheme and an iPhone Simulator. The bundle identifier is `com.maksym1503.veil`; MaxLab uses `veil://` to detect and launch it.

## Current MVP

Background blur uses Vision person segmentation and falls back to manual selection when a subject mask cannot be made. Face detection uses Vision face rectangles. Plate suggestions come from recognized text boxes filtered by shape and require confirmation; manual drawing is always available. Export writes a high-quality JPEG and opens the iOS share sheet.
