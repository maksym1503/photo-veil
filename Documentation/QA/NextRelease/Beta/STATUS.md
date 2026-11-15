# Vail1.1(8) — available for owner internal TestFlight testing

Apple processing **VALID**; audience **APP_STORE_ELIGIBLE**; internal state
**IN_BETA_TESTING**. Build ID `10c35696-91a3-42b1-84dc-392aac8c9060` is explicitly
assigned to existing **Veil 1.0 Internal Acceptance**. Its one tester membership
is unchanged. Server-side installation access is verified; installation of this
build on the owner's physical iPhone has not been observed or claimed.
[Authoritative sanitized read-back](testflight-readback.json).

The build is normal App Store Connect distribution, eligible for later customer
submission; `testFlightInternalTestingOnly=false`. No public/external beta review,
App Store review submission, live screenshot/listing replacement or main merge.
Live App Store version1.0 remains READY_FOR_SALE. No new testers invited.

## Code and product behavior

Code commit [2e4d3ee](https://github.com/maksym1503/photo-veil/commit/2e4d3ee4d01d89796ef34279f977f0343b63ed49),
[draft PR7](https://github.com/maksym1503/photo-veil/pull/7), branch `feature/vail-1-1`.
Later evidence-only commits do not alter compiled source. Owner-local signing team
values remain local; all other project bytes match the committed configuration.
Existing unrelated backend/deployment work is preserved and not committed here.

| Cohort | Effective allowance / preview |
| --- | --- |
| New genuinely absent Keychain record | Exactly1 successful free Save or Share; subsequent clean outputs require Pro |
| Valid legacy v1 count0/1/2 | Preserve count and original limit2, including count1's remaining second export |
| Verified current Pro | Unlimited clean exports and clean previews; unused quota is not consumed |
| Exhausted non-Pro | Editing continues with Quiet Lattice and native Preview Mode / Unlock Clean Exports |
| Unavailable/checking access | Protected image while verification/access resolves; no invented allowance |

Same Keychain service/account/device-only protection; no usage reset or gallery
identity proxy. Photos, Veil and Share use one shared UUID reservation and count
only destination success; cancellations/failures do not consume a use. Atomic
published record keeps preview and authorization limits consistent. ADR-014
records migration and downgrade caveats. Automatic Faces/Plates/Documents move/
resize, normalized coordinates, cache, scoped Undo and one renderer/export path
are preserved; Documents Details/Entire Document remain distinct.

## Final QA and archive evidence

| Check | Actual result |
| --- | --- |
| Full PR |102/102; strict exact-case verification |
| Full Integration compatibility matrix |153/153 unique:144on26.5 +9on26.1; exact one-run membership, zero failures/skips/expected and matching before/after source/build hashes |
| Full Commerce |31/31:16core+8hosted StoreKit+7UI; strict verification |
| SwiftPM |95passed in default run with2 documented opt-in skips; separate explicit macOS profile run2/2 passed;97unique package methods executed/pass |
| Actual Dark |1/1; explicit simctl Dark, actual pixels inspected, Light restored and verified |
| Unsigned Simulator Release |Build/resource/privacy guard passed |
| Production archive + exported IPA |Distribution signatures, strict verification, provisioning, version/bundle, resource/privacy guards passed; correct normal export flags |

All162 automated inventory methods have passing coverage across these overlapping
suites. The single physical-device inventory method/system acceptance is reserved
for owner beta validation, not claimed run on a Simulator. See [full QA scope and
original failure classification](qa-results.md), [validation](validation.json),
[matrix](matrix-result.json), [signed artifact](signed-release.json) and native
summaries under `results/`. The source fingerprint still matched final QA after
archive/export; the working project and keychain search list were restored exactly,
and the dedicated signing keychain relocked. No signing assets created/registered.

Initial fixture failure is retained, not called green. Independent review found
three legacy multi-output tests needing explicit isolated fixtures; all assertions
remain, fixes were rechecked, and the fresh complete matrix passes. Archived
patches are losslessly compressed with verified raw hashes. The initial global
provisioning override hit a Swift Crypto resource bundle; app-target-only signing
resolved it with no product/credential change. [Archive history](archive-attempts.json).
API offered no optional upload checksums; local IPA SHA256 is retained and Apple
processing VALID confirms accepted delivery. No checksum verification is invented.

Hosted Apple PR checks hit their20minute job budget with incomplete coverage and
are **not green**. Final code repository-security/backend pass. CTO accepted
internal beta based on strict full local QA; hosted CI qualification still blocks
merge. No old-job retry, budget inflation or provider activation. [CI history](ci-history.json).

## Actual roles and owner review

- Root: Engineering Lead, integration, additional tests/copy, signed release and
  authorized internal upload. During QA's temporary usage cap, ran the older PR;
  QA subsequently executed the fresh final-source run independently.
- Configured `cto` (gpt-6-astra/low): architecture/migration, count maintenance,
  evidence cleanup and internal-beta gate decisions. [Findings](architecture-review.md).
- Configured `developer` (gpt-6-luna/medium): record/Keychain/coordinator migration
  and original Commerce refactor; focused14/14 passed before expanded validation.
  [Implementation record](developer-implementation.md).
- Configured `reviewer` (gpt-6.1-sol/medium): independent actual source/test review,
  complete multi-output audit, fix rechecks and lossless evidence verification.
  [Findings](reviewer-findings.md). No remaining code-review blockers.
- Configured `qa` (gpt-6-luna/medium): final native matrix/PR/Commerce, real Dark
  capture, SwiftPM/macOS and unsigned Release/resource checks. [Results](qa-results.md).

No nested agents or parallel native UI sessions. Dedicated Design configuration
remains unavailable; owner explicitly accepted the completed independent visual
review and all five designs for this internal beta. No fabricated participation.

## Owner installation and remaining acceptance

Open TestFlight with the Apple Account already enrolled in the existing group,
select **Blur, Watermark & Metadata**, choose1.1/build8 if needed, then Update/Install
in place. Do not erase existing history/Keychain to simulate a new user.
[Manual feature/install checklist](OWNER_TEST_CHECKLIST.md).

Known limits: absent legacy records cannot be distinguished from new; quota is
per-device and reinstall survival is not guaranteed. A free-export attempt can
write v2 even when later cancelled without consuming usage; old1.0 cannot decode
that record and may block free exports until a v2-aware build is installed. The
existing external-success-to-Keychain process-death gap remains. Watermarks cannot
prevent screenshot circumvention completely.

Physical iPhone/Sandbox, VoiceOver, gesture feel, system Photos/Share and large-photo
memory/color/performance remain owner checks. Public1.1 legal/listing copy alignment
is prepared locally, not published. README's V4/backend/owner gate and explicit
public release/merge authorization remain required. Stop at this internal beta.

[Five approved individual upload-ready screenshots](../../../Marketing/AppStore/NextRelease/UploadReady/README.md)
remain local and byte-identical to the approved Editorial Calm JPEGs. Quiet Lattice
and fresh actual UI evidence are retained under `captures/`; no live assets changed.
