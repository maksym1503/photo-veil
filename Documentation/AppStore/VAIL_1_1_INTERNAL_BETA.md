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

Implementation reviewed independently; migration/test fixture findings resolved.
Comprehensive native validation is in progress; upload has not yet occurred.
See `Documentation/QA/NextRelease/Beta/` for final evidence and status.
