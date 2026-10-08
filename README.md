# Veil — V4 draft

A photo privacy utility with on-device Vision/Core Image processing and native iPhone controls. Core editing, Share, Save to Photos and local Private Gallery work without an account. Optional Apple/Google accounts and processed-output cloud sync require real owner setup; signing in does not enable uploads.

## Build

Open `PhotoVeil.xcodeproj`, select `PhotoVeil` and an iPhone Simulator. The default build needs no backend configuration. Existing local signing settings stay local. Bundle: `com.maksym1503.veil`; `veil://` remains the launch scheme. iOS 17+.

## Capabilities

Background, Faces, Plates, Manual rectangle/ellipse/brush and heuristic Documents use normalized image geometry and one Gaussian/Pixelate/Solid preview/export renderer. Original-image face tiles improve recall without changing zoom; automatic detection remains fallible. Save to Veil keeps only explicit processed outputs in protected file-backed history. PhotosPicker remains selection-scoped; Save to Photos requests add-only permission on invocation.

## Review and setup

[Architecture](Documentation/Architecture/V4_ARCHITECTURE.md), [backend setup](Documentation/Backend/BACKEND_SETUP.md), [App Store preparation](Documentation/AppStore/APP_STORE_CHECKLIST.md), [physical-device checklist](Documentation/QA/V4/PHYSICAL_DEVICE_CHECKLIST.md). Public legal/support links live in `VeilPublicLinks` and remain hidden until configured. No analytics, tracking, password system or original-image cloud uploads. Cloud storage is not end-to-end encrypted.

Run `swift test` for deterministic core tests, the Xcode scheme for UI regressions, `python3 scripts/test_backend_policies.py` for isolated PostgreSQL policy tests, and `deno test --allow-env supabase/functions/tests` for mocked server deletion behavior. Real Supabase/provider integration is a separate owner validation gate. See backend setup for exact commands.

**Do not merge V4** until owner physical acceptance and configured-backend review. V3 on main remains approved and stable.
