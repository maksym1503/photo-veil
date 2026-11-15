# Veil — V4 draft

A privacy photo editor built around blur/redaction, metadata control and watermarks, with on-device Vision/Core Image/Core Text processing and native iPhone controls. Core editing, Share, Save to Photos and local Private Gallery work without an account. Optional Apple/Google accounts and processed-output cloud sync require real owner setup; signing in does not enable uploads.

## Build

Open `PhotoVeil.xcodeproj`, select `PhotoVeil` and an iPhone Simulator. The default build needs no backend configuration. Existing local signing settings stay local. Bundle: `com.maksym1503.veil`; `veil://` remains the launch scheme. iOS 17+.

## Capabilities

Background, Faces, Plates, Manual rectangle/ellipse/brush and heuristic Documents use normalized image geometry and one Gaussian/Pixelate/Solid preview/export renderer. Session-only custom text watermarks support direct placement, native styles, size/opacity/rotation and repeated patterns. They render above the privacy layers into every output; gallery/cloud retain flattened pixels, never an editable text recipe. [Watermark scope](Documentation/AppStore/WATERMARKS.md) and [ADR-006](Documentation/Engineering/Decisions/006-three-pillar-watermark.md) describe limits. Original-image face tiles improve recall without changing zoom; automatic detection remains fallible. Save to Veil keeps only explicit processed outputs in protected file-backed history. Choose Remove metadata or Keep metadata in the Metadata tool. Done reviews that choice before saving or sharing. The choice follows saved gallery copies, Photos, Share and future cloud sync. Keep preserves supported source fields; original previews and unsupported tags cannot survive JPEG re-encoding exactly. Older gallery entries use Remove. Originals stay unchanged, and Photos/receivers may add dates and IDs. [Metadata choice](Documentation/Engineering/Decisions/005-optional-photo-metadata.md) documents the boundary. PhotosPicker remains selection-scoped; Save to Photos requests add-only permission on invocation.

## Review and setup

[Architecture](Documentation/Architecture/V4_ARCHITECTURE.md), [backend setup](Documentation/Backend/BACKEND_SETUP.md), [App Store preparation](Documentation/AppStore/APP_STORE_CHECKLIST.md), [physical-device checklist](Documentation/QA/V4/PHYSICAL_DEVICE_CHECKLIST.md). Public legal/support links live in `VeilPublicLinks` and remain hidden until configured. [App Store readiness](Documentation/AppStore/RELEASE_READINESS.md) records remaining owner gates; [Native freemium implementation](Documentation/AppStore/MONETIZATION_IMPLEMENTATION.md) allows one successful export for new installations, preserves previously recorded two-export allowances, then requires verified Veil Pro access. [Migration contract](Documentation/Engineering/Decisions/014-new-and-legacy-export-allowances.md). Monthly/yearly StoreKit products and local tests are prepared; production purchasing needs published legal links and owner App Store Connect setup. No analytics, tracking, password system or original-image cloud uploads. Cloud storage is not end-to-end encrypted.

Run `swift test` for deterministic core tests, the Xcode scheme for UI regressions, `python3 scripts/test_backend_policies.py` for isolated PostgreSQL policy tests, and `deno test --allow-env supabase/functions/tests` for mocked server deletion behavior. Real Supabase/provider integration is a separate owner validation gate. See backend setup for exact commands.

**Do not merge V4** until owner physical acceptance and configured-backend review. V3 on main remains approved and stable.
