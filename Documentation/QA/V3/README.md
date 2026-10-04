# Veil V3 visual and regression QA

The owner approved V3 after physical-iPhone testing. The final revision only loops the existing landing portrait demonstration; no App Store submission was performed.

## Executed checks

- Final landing revision: 2.2-second blur/reveal transitions with 1.4-second holds, unchanged layout. Repeated clear/blur cycles were visually inspected in Simulator captures and a recording. Reduce Motion remained statically blurred across captures more than one cycle apart. The first-launch/Settings/Privacy UI test and all 12 core tests passed (`/tmp/veil-v3-landing-loop.xcresult`).

- Xcode 26.6 / iOS 26.5, iPhone 17 Pro Simulator: the complete ten-test UI regression suite passed in `/tmp/veil-v3-complete.xcresult`. Covers real Vision Faces/Plates, immediate plate blur, individual/bulk toggle, Low/Strong pixel changes, rectangle create/move/resize/delete/undo, freehand/undo, zoom/pan/fit, mode switching, Done/Edit, overlay-free preview and system export.
- Smaller iPhone 17e Simulator, dark appearance: Faces, Plates and first-launch/Settings/Privacy tests passed in `/tmp/veil-v3-dark-tests.xcresult`.
- iPhone 17 Pro, `accessibility-large` text with Reduce Motion, Reduce Transparency, Differentiate Without Color and increased contrast Simulator preferences enabled: first launch, Settings, About, back navigation and Privacy passed in `/tmp/veil-v3-accessibility-fixed.xcresult`. Long content scrolls rather than truncating. Simulator preferences were restored after this pass.
- An older hosted run exposed a stale native toolbar title during repeated Done/Edit transitions: the export helper inferred state from that title and toggled back into editing. Restored the V2 title identity guard and made export tests use the actual Export control as the preview-state indicator.
- Largest text uncovered cramped strength/bulk controls and truncated tool labels on iPhone 17e. Fixed with vertical secondary controls and a native tool menu for Dynamic Type accessibility sizes 3–5. Sizes 1–2 use two columns; standard text retains four modes. A new `testLargestTextToolAndStrengthMenus` passed in `/tmp/veil-v3-largest-discovered.xcresult`, using the UIKit preferred-text-size launch argument with the Simulator itself reset to normal text. It verifies strength selection and switching from Plates to Manual through the menus. Final light and dark largest-text screenshots were inspected after this fix.
- `swift test`: 12 geometry and renderer tests passed. No renderer, detector or image-space geometry rewrite.
- Unsigned generic iPhone Release build passed. Bundled manifest validated; Release bundle excludes the three fixture JPEGs and fixture/evidence code is gated by DEBUG. Distribution signing/archive validation remains an owner step.
- `render-parity.json`: Faces, Plates, rectangular Manual and freehand Manual exported render pixels match their previews exactly before JPEG encoding for the fixtures, and differ from the originals. The fixture dimensions are below the 1800-pixel preview cap; larger-image scaling parity remains covered by existing renderer tests rather than this byte comparison.
- Exported fixture JPEGs retain full image dimensions. Inspection found generated orientation/resolution/dimension metadata and no GPS data; code creates fresh JPEG data from rendered pixels and does not copy source EXIF/GPS metadata. This is not a claim that JPEG files contain no metadata at all.
- Manifest/source/symbol audit found no tracking, analytics, network client or third-party runtime dependency and no app use of required-reason API categories. Temporary exports can remain until OS cleanup; no claim of immediate deletion.

## Visual review coverage

| State | Evidence / result |
| --- | --- |
| First launch | `light-first-launch.png`, `dark-first-launch.png`: portrait blur illustration, concise hierarchy, Choose Photo, local-processing reassurance |
| Photo loaded | `light-initial-two-people-car.png`: photo dominates; native top navigation and compact labeled tools |
| Background requested | `light-background-person-fallback.png`, `light-background-car-fallback.png`: this Intel Simulator returns the existing manual fallback; actual blurred Background must be reviewed on physical iPhone |
| Faces / multiple faces | `light-faces-all-blurred.png`, `light-faces-selective.png`, `dark-faces-all-blurred.png`: both detected faces start blurred; individual toggle works |
| Plates | `light-plate-auto-blurred.png`, `dark-plate-auto-blurred.png`: detected plate blurred immediately, matching face corner vocabulary |
| Multiple plates | Available fixture has one plate; no multiple-plate visual claim. Selection code iterates all returned indices; still needs a multi-plate physical fixture |
| Manual rectangle | `light-manual-blurred.png`, `light-manual-moved-resized.png`: neutral outline; existing handles and image-space gestures retained |
| Manual freehand | `light-freehand-blurred.png`, `light-freehand-clean-preview.png`: visible stroke blur, no editing overlays after Done |
| Done / clean preview | Faces/Plates clean-preview light/dark screenshots: Edit and primary Share symbol; editor overlays disappear, photo transform retained |
| Settings / About / Privacy | Light/dark Settings and Privacy; `accessibility-about.png`: native grouped lists, no fake legal/contact links |
| Larger Text / largest Text | `accessibility-*.png`: scrolling text, readable controls; largest size switches to menus without truncated tool names |
| Reduce Motion | Looping portrait demonstration becomes a static blurred portrait; press scale disabled. Preferences enabled during accessibility run |
| Reduce Transparency / contrast | Accessibility screenshots: opaque fallback control surfaces, native system settings adaptation |
| Differentiate Without Color | Neutral selected backgrounds and accessibility selected traits; blur plus solid/dashed detection corners communicate state without hue |

Screenshots are native Simulator captures. Full test attachments remain in the result bundles and hosted CI artifacts; representative PNGs are committed beside this report.

## Quality reference and retained tradeoffs

Gamefy's `WorldMotion.swift`, native presentation implementation and light-mode QA screenshot were inspected for feedback timing, hierarchy, spacing and restrained interaction polish. Veil borrows that level of intention and Reduce Motion handling, while using current native iOS toolbars/glass and a photo-first utility structure. No Gamefy product metaphor or gamification was introduced.

Done retains the hidden controls' layout footprint so it does not change the canvas transform. This leaves bottom space in clean preview, especially with landscape images; a full-viewport transition is deferred because stable zoom/pan matters more than a risky geometry change in this design pass.

VoiceOver detection button labels, state values, hints and activation callbacks were fixed and exercised through accessibility-based UI automation. Hands-on spoken VoiceOver review on physical iPhone remains required. Manual drawing still requires direct spatial interaction. iOS 17–25 fallback appearance and actual foreground Vision on physical hardware were not run locally because only the iOS 26.5 Simulator runtime is installed.

Hosted CI status for the exact PR head is shown on the PR. Physical visual acceptance is complete; real public URLs, legal/entity details and distribution validation remain in [the App Store checklist](../../AppStore/APP_STORE_CHECKLIST.md).
