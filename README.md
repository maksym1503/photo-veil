# Veil

A focused, private photo utility: choose a photo, blur sensitive areas, export. Image analysis and rendering run locally with PhotosUI, Vision and Core Image. No account, backend, analytics or persistent edit library is included.

## Build

Open `PhotoVeil.xcodeproj`, choose the `PhotoVeil` scheme and an iPhone Simulator. The bundle identifier is `com.maksym1503.veil`; MaxLab uses `veil://` to detect and launch it.

## Current MVP

Background blur uses Vision foreground instance masking (people, vehicles and other subjects) and falls back to manual selection when a subject mask cannot be made. Face detection uses Vision face rectangles. Likely plates come from recognized text boxes filtered by shape and blur automatically, with tap-to-toggle selection; manual drawing is always available. Export writes a high-quality JPEG and opens the iOS share sheet.

## V3 review

V3 adopts native navigation, glass controls on iOS 26 with iOS 17+ fallbacks, consistent Faces/Plates selection, a visual landing screen and native Settings. App Store preparation and missing owner inputs are tracked in [the checklist](Documentation/AppStore/APP_STORE_CHECKLIST.md). Public links are centralized in `VeilPublicLinks` and omitted until configured. No login or analytics is included.
