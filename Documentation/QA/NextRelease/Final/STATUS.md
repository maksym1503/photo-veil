# Vail 1.1 final public-release checkpoint

Owner explicitly authorized protected merge, App Review submission and automatic
public release after Apple approval on 2026-11-15. This supersedes the prior
internal-beta-only boundary; it does not waive required protected checks.

## Final candidate

Code `eafbee29883ac1d588168baa624e6dda7e5f46ee`, version1.1/build9,
[PR7](https://github.com/maksym1503/photo-veil/pull/7).
The final notice reads “Go Pro to save & share clean photos.”, centered with8pt
stack spacing, preserving caption styling and the native subscription button.
No quota, entitlement, rendering or export behavior changed in this refinement.

Reuse the accepted [comprehensive beta QA](../Beta/STATUS.md): PR102,
Integration153, Commerce31 and97unique SwiftPM methods. For the final copy only,
`testRefinedEditorialAndPreviewJourney` and
`testRefinedEditorialDarkAppearanceJourney` each passed1/1, with explicit actual
Light/Dark simulator appearance; Light restored. These actual photographic
journeys retain Vision Documents adjustment/Undo and real successful exports.
Full native results remain at `/tmp/vail11-public-final/{light,dark}.xcresult`.
Actual redacted previews: [Light/day](light-day.png),
[Light/night](light-night.png), [Dark/day](dark-day.png),
[Dark/night](dark-night.png). Independent reviewer inspected all four: no visual
findings, readable centered text, consistent typography/colors/spacing, no control
clipping or overlap. No dedicated Design agent configuration was found or claimed.

Root coordinated and ran targeted UI/build/signing validation. Configured CTO
(Astra/low) consulted on the repeated hosted CI budget failure; Developer
(Luna/medium) implemented the bounded scheme change; independent Reviewer
(Sol/medium) reviewed actual code/CI and screenshots with no findings.
[ADR015](../../../Engineering/Decisions/015-pr-build-scope.md) records the narrow
PR build scope correction. Canonical102-case plan, serial execution, exact inventory
verification and20minute job ceiling are unchanged. No rerun-until-green or bypass.

Signed Release archive and normal App Store Connect IPA passed strict distribution
signature, provisioning, privacy/resource and test-asset guards. Version1.1/build9,
bundle `com.maksym1503.veil`, team `88QTXB3NUA`, non-internal-only distribution.
[Sanitized signing evidence](signed-release.json). Existing owner-local signing
fields, keychain state/search list and unrelated backend work preserved.

## App Store preparation

New1.1 draft `b5740f44-75ba-40d4-9f83-5aed1f8c98d8` uses AFTER_APPROVAL.
Five approved Editorial Calm1320×2868 opaque RGB JPEGs uploaded to its en-US
Apple APP_IPHONE_67 set, without changing1.0 live screenshots. Description/What's New explain
one successful export for new installations and preserved recorded legacy usage.
Existing subscription IDs/products/prices/trials unchanged. Public privacy/terms/
support copy is aligned at the existing veil-legal.pages.dev deployment
`53e0c9ca-978b-41b5-a71d-6adff6d913d3`; successful deployment and byte-identical
public readback verified. Source retained in
[Release1.1/LegalSite](../../../AppStore/Release1.1/LegalSite/).

## Protected merge and distribution

All three required checks passed on eafbee2. Hosted Apple
[run43759223532](https://github.com/maksym1503/photo-veil/actions/runs/43759223532)
verified all102 required cases with no missing/skipped/expected failures; pipeline
wall time1004.36seconds, whole Apple job17m24s within20minutes. Actual build log
contains neither legacy UI nor hosted Commerce test build products. The narrow
scheme correction is now measured rather than speculative. Strict protection and
enforced administrators remain unchanged. PR7 merged normally at
`3cf6dadc480ce4e05b1e2d12e8b22878e585ac3f`; no override. Source/project/resources
of merged main match the archived candidate commit. Build9 processed VALID / APP_STORE_ELIGIBLE and is attached to1.1. The existing
internal group was assigned, with no tester invitations or membership changes.

## Apple submission readback

Submitted2026-11-15T21:00:31.25Z, submission
`382c4e33-ea43-4379-a995-4e461ef2bfd9`, state WAITING_FOR_REVIEW.
[Authoritative status](review-status.json). Version1.1 is WAITING_FOR_REVIEW,
releaseType AFTER_APPROVAL, attached build9 VALID. Version1.0 remains READY_FOR_SALE:
**1.1 is not live yet**. Apple review/availability is the external remaining step;
no further routine owner authorization is needed. Check App Store Connect review
status and version readback after Apple acts; never infer publication from submission.

[Readiness validation](app-store-validation.json): zero blocking errors. Warnings
are existing optional subscription promotional images, unused vail.pro.yearly
metadata, and expired cached web session (three web-only assertions unverified).
API review submission was accepted; no account login or commercial settings were
changed. [Five screenshot readbacks](screenshots-readback.json) are COMPLETE and
match approved local checksums. API supplied no optional upload checksums; local
IPA SHA256 and successful Apple processing retained without inventing remote
checksum verification. Existing physical-device/performance and migration caveats
remain as documented in the accepted beta evidence; no new product issue found.
