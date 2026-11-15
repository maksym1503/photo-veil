# Install and test Vail1.1(8)

Availability is confirmed separately in the final beta status. Once available:

1. Open TestFlight on the iPhone using the Apple Account already enrolled in
   **Veil1.0 Internal Acceptance**. Open **Blur, Watermark & Metadata**.
2. Select1.1/build8 if needed and tap Update/Install. Update in place; do not
   uninstall, reset Keychain, clear app history or change signing identities.
3. Launch Vail. Existing saved photos should remain; note allowance messaging.

## Priority checks

- Faces/Plates/Documents: select a detected region, drag its body, resize its corner,
  zoom/pan using two fingers, then Undo. Check independent nearby regions. In
  Documents, compare Details and Entire Document coverage. Detection can miss
  details; inspect suggestions before sharing.
- Effects/export: try Blur, Pixelate and solid Redact; compare Done and a permitted
  saved/shared output for the same placement/size/quality. Original remains intact.
  Verify custom user watermark export intentionally remains visible.
- Metadata: use a non-sensitive photo with known location. Choose Remove and
  inspect the exported copy's source location; also check Keep. Receivers/Photos
  may add their own dates/IDs; exact source JPEG tags are not promised.
- Allowance: a recorded legacy count1 keeps its remaining second export; after
  success another Save/Share opens Pro and shows Quiet Lattice. Cancelled Share
  and failed Photos save must not use allowance. Try editor and gallery paths.
  New-user1 is verified automatically with isolated test namespaces. For manual
  verification use a separate device with no Vail quota record, never erase the
  owner's existing data or invite another tester without authorization.
- Pro: inspect actual Apple prices/terms and trial eligibility, purchase/restore
  through the TestFlight testing environment, confirm clean preview and further
  exports. Relaunch and Restore again. Apple controls eligibility and verification;
  local StoreKit automation is not server Sandbox/device acceptance.
- Appearance/accessibility: inspect both device Light/Dark appearances, large text,
  VoiceOver region actions and Unlock Clean Exports. Dismiss paywall and continue
  editing/inspecting the marked preview without repeated prompts.

## Known migration limits

A legacy installation without a surviving record receives the new1-export policy.
Quota is device-local, not account-synced; reinstall persistence is not guaranteed.
After a v2 record is written, old1.0 cannot decode it and fails closed for free
exports. Returning to1.0 can therefore block free exports until a v2-aware build
is installed; do not delete the quota to work around it. Save success and Keychain
commit are not atomic across a process kill. Quiet Lattice reduces screenshot
usefulness but cannot prevent circumvention.

Report device/iOS version, operation and observed behavior using synthetic or
non-sensitive photos. Do not attach customer photos, recognized private text,
receipts or account credentials. Public release remains a separate owner approval.

Before public release, prepared1.1 public-copy alignment must replace historical
two-free-export wording in the live legal/listing content; that publication is
not part of this internal-beta distribution.
