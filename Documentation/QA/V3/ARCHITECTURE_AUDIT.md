# Bounded V3 consistency review

Scope: presentation, Faces/Plates interaction, release hygiene, privacy and obvious consistency risks. The blur renderer, Vision requests, normalized geometry mapper and editor gesture algorithms were preserved.

## Fixed

- Faces initialized selected indices; Plates initialized only candidates. Both now initialize all detector-returned indices as selected. Plate heuristics are unchanged; returned OCR boxes can include unrelated text, so every candidate remains independently reversible. No artificial confidence score or separate unvalidated threshold was introduced.
- Detection rendering now shares one neutral solid/dashed corner routine. Manual outlines no longer tint the photo orange.
- Both modes use the same Clear all / Blur all action and selection haptics. `Plate` remains the internal raw value so UI identifiers and diagnostic filenames stay compatible; the user-visible label is `Plates`.
- Native toolbar replaced duplicated custom navigation circles. Glass/material fallbacks and mode press motion live in `VeilPresentation.swift`.
- Largest accessibility text sizes cramped the compact row. Secondary controls now stack vertically and tools use a native menu at sizes 3–5, with menu interaction regression coverage.
- Detected-region VoiceOver button activation was missing; dedicated accessibility elements now call the existing selection actions.
- Debug builds explicitly define `DEBUG`. Fixture loading/evidence output are compiled out of Release; the Release resource exclusion removes UI test JPEGs. Signing-team edits remain local.
- Version/build now resolve from Xcode settings rather than duplicate hard-coded Info.plist values.

## Preserved / deferred

- Preview and export still share `PrivacyImageRenderer`, normalized regions, strokes and background masks. No second rendering path was introduced for the new visual system.
- Done keeps the hidden control area's layout footprint to preserve the canvas transform. Recovering this blank area for a full-height final viewer would require a carefully tested viewport transition; it is intentionally deferred.
- Faces/Plates have separate async Vision operations and selected sets. A generic detection model would be a broader refactor without a present need; not implemented.
- Foreground detection cannot run reliably on this Intel Simulator; keep device verification as the acceptance gate.
- Export JPEGs remain in temporary storage for system sharing and may persist until OS cleanup. Do not claim immediate deletion or zero disk writes. Dedicated export lifecycle cleanup is a potential future change and should account for asynchronous share extensions before deleting files.
- OCR plate heuristics are shape-based and can include non-plate text. Auto-selecting their results fulfills the requested interaction; it does not make detection infallible. Manual is available for missed regions.
- No dead experimental controls, network SDKs, analytics flags or account code found. Diagnostic geometry values remain internal and do not transmit data.
