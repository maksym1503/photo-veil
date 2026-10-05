# V4 QA evidence

Branch: `feature/veil-v4`, based on approved V3 `72bdcb2`. **Draft only; do not merge.**

## Automated checks

- macOS Swift suite: 35 tests, 34 deterministic passed, one real-Vision benchmark intentionally opt-in/skipped in ordinary CI. Geometry, mask/effect parity, bounded face tiles/NMS, document geometry, protected gallery persistence, permission states, mocked auth and sync behavior.
- iPhone 17 Pro / iOS 26.5 Simulator: full 17-test suite, preserving all ten V3 tests and adding Pixelate/ellipse/undo/export, Documents, local Gallery relaunch/share/delete, zoom-independent small-face detection, safe unconfigured account, PhotosPicker and add-only Save to Photos.
- Additional dark-mode accessibility run: six targeted UI tests with Reduce Motion and Reduce Transparency enabled, including Accessibility XXXL tool/strength menus. Screenshot review caught and corrected wrapping strength text and oversized manual icons.
- Unsigned generic-device Release build. This validates compilation/resources, not owner provisioning or App Store submission.
- Actual SQL migrations exercised with two authenticated roles in an isolated PostgreSQL cluster: metadata and private Storage owner isolation, closed-account write gate, service-only Vault RPC privileges and transactional token cleanup. The minimal Auth/Storage/Vault schema is a **test shim**; its token storage is not real Vault encryption. Run `python3 scripts/test_backend_policies.py` locally or the dedicated CI job.
- Three Deno endpoint type checks and five HTTP-mocked deletion tests: unauthenticated requests, body ownership spoofing, retryable storage failure, gate/storage/identity ordering and failed Apple revocation. `deno test --allow-env supabase/functions/tests`.

Configured provider/cloud integration was **not run**: no project, Apple capability, Google OAuth client or production secrets were supplied. Follow [backend setup](../../Backend/BACKEND_SETUP.md) for real two-user tests and deployment. Simulator Background can use the documented manual fallback when native segmentation is unavailable.

## Detection and performance

Opt-in command: `VEIL_RUN_DETECTION_BENCHMARK=1 swift test --filter DetectionBenchmarkTests`. Fixtures are deterministic composites of the existing face fixture, at different sizes/edges; they are not a broad accuracy dataset. Raw results: [detection-performance.json](detection-performance.json).

| Fixture | Placed faces | V3 preview pass | V4 merged | V4 requests | V4 seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| Large + medium, 3200×2400 | 3 | 3 | 3 | 5 | 0.40 |
| Small landscape, 4032×3024 | 4 | 1 | 2 | 21 | 0.72 |
| Small portrait, 3024×4032 | 3 | 1 | 2 | 21 | 0.68 |
| Edge / partial, 4032×3024 | 4 | 0 | 4 | 21 | 0.56 |

Visual inspection found no obvious final duplicate/false-positive boxes on these composites. Some very small faces remain missed; Manual is required. Tile bounds are mapped into original coordinates and deduplicated before privacy padding. UI zoom is not an input. Results are **Mac Vision measurements**, not physical-iPhone latency or a 100% recall claim.

Synthetic card: one boundary and four detail regions, ~0.96 s warm. OCR proposes text geometry, not universal document/field classification. Full-document hiding remains the safer broad option.

JPEG export timings include materializing the rendered image and encoding: 12 MP Blur 0.41 s / Pixelate 0.22 s / Redact 0.19 s; 48 MP 1.58 / 0.80 / 0.66 s. Synthetic images on Intel Mac; device memory, thermal behavior and photographic complexity are not established by these numbers. Gallery decodes thumbnails rather than every full image; detector crops are processed serially and capped. Measure peak app memory and cold/warm latency on a physical iPhone before acceptance.

## Visual evidence

Native Simulator captures in this directory show landing, settings/privacy, add-only permission, gallery states, account-unconfigured state, small faces, document detail/whole redaction and Pixelate ellipse. The `dark-` captures include Reduce Motion/Transparency and the corrected Larger Text layout. UI result bundles contain the full original V3 screenshot sequence, including clean preview/share, masks, pan/zoom and mode switches. CI uploads its result bundle as `veil-runtime-results`.

All UI fixtures are DEBUG-only resources and excluded from Release. An unused legacy QAStreet asset was removed. Screenshots are documentation, never app resources. VoiceOver labels/identifiers and non-color selected-state traits are exercised through accessibility queries; real VoiceOver navigation, contrast under outdoor conditions and older supported iOS fallback controls require device inspection.

## Physical acceptance

Use [PHYSICAL_DEVICE_CHECKLIST.md](PHYSICAL_DEVICE_CHECKLIST.md). No V4 physical test was performed by this agent. Apple/Google, add-only denial/restriction, cross-device history/deletion, document variety, 48 MP memory and final export quality remain required checks. No merge authorization is implied by green CI.
