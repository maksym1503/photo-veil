# Vail1.1 internal beta

Owner explicitly authorized normal App Store Connect archive/upload and distribution
to the existing internal TestFlight group; no public review submission, listing
replacement, new testers or protected-main merge. Target1.1(8), bundle
`com.maksym1503.veil`, preserved team88QTXB3NUA. Fresh ASC audit confirms1.0 is
READY_FOR_SALE and latest uploaded build7. No1.1 upload existed before this work.
The version-scoped next-build endpoint suggests1; choose8 to continue the existing
monotonic production build series. Production URLs/configuration are preserved.

## Changes since1.0(7)

- Move and resize automatic Faces, Plates and Documents regions, retaining
  normalized geometry, independent regions, scoped Undo, zoom and shared export.
- One successful free export for new installations; preserve recorded legacy
  two-export allowances/counts. Photos, Veil and Share share admission/success
  accounting. Cancelled/failed outputs do not consume a use. See ADR-014.
- Quiet Lattice premium previews after actual exhaustion, with Preview Mode
  explanation and Unlock Clean Exports using the existing native StoreKit paywall.
  Verified Pro stays clean/unlimited. Original/source and paid export bytes stay
  free of preview marks; custom user-created watermark exports remain intentional.
- Editorial Calm five approved App Store designs prepared locally, validated at
 1320×2868 RGB JPEG; `Marketing/AppStore/NextRelease/UploadReady/en-US`. No live
  listing changes. Existing independent visual review plus owner approval satisfies
  this beta checkpoint; dedicated Design agent configuration remains a follow-up.

## Migration and test boundaries

Same Keychain service/account, device-only accessibility and non-sync strategy.
Valid v1 count0/1/2 retains limit2 exactly; new absent record limit1. Corrupt or
inaccessible records fail closed. Legacy installations with no surviving record
are indistinguishable from new and receive one. Do not clear/reinstall/reset owner
Keychain or photo history to simulate new users. Test only isolated UUID namespaces.
Old1.0 binaries reject the v2 record; rollback requires a v2-aware binary.
Existing local StoreKit products `vail.pro.monthly`/`vail.pro.annual`, pricing,
trials, subscription group and Restore remain unchanged. No backend/provider setup,
production secret, signing identity or bundle change. Physical owner iPhone
acceptance is the purpose of this internal beta; public-release/V4 gates remain.

## Current status

**Available:**1.1(8) is processed VALID / APP_STORE_ELIGIBLE and IN_BETA_TESTING
in the existing internal group, membership unchanged. All comprehensive local
QA, signed archive and exported-IPA checks passed. See the [final checkpoint](../QA/NextRelease/Beta/STATUS.md)
for exact counts, actual review findings, CI limitations, install steps and migration caveats.

## Distribution preflight references

Existing Apple Distribution identity and matching App Store provisioning profile
were verified through the established encrypted release keychain and existing
recovery item; no key material or password was printed/exported. Preflight search
list was unchanged and the dedicated keychain relocked. Archive/export will use
temporary command-line signing overrides with search-list restoration in finally.
Normal export explicitly sets `testFlightInternalTestingOnly=false` and disables
Xcode automatic build-number changes. Apple upload requirements checked2026-11-15:
[upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
requires Xcode26+ for iOS; installed26.6 satisfies that build requirement. No
archive or upload occurs until comprehensive release QA/resource checks pass.
