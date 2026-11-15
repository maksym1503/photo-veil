# ADR-014: New and legacy device export allowances

Status: accepted ·2026-11-15 · CTO: configured `cto`, gpt-6-astra/low
Decision authority: Maksym (explicit product approval), Root (technical integration).
Supersedes ADR-007's universal two-export threshold and ADR-013's pending migration gate.

New users receive exactly one successful free export. Valid existing version1
Keychain records retain their count and allowance of two. Pro access, products,
prices/trials and Restore remain unchanged. The same main-actor UUID reservation
continues to gate Photos, Veil and Share; only destination success consumes a use.

Store a version2 record with `completed` and `limit` (1 or2), using the existing
service/account, nonsynchronizing, WhenUnlockedThisDeviceOnly Keychain protection.
Decode valid v1 counts0/1/2 as v2 in memory with limit2; never reset counts.
Preview observation is read-only. Persist the normalized record during the existing
pre-admission write probe; failures block free admission. Retain successful dirty
usage in memory and retry before another free admission. Count and effective limit
publish in one snapshot, so editor/gallery presentation and authorization agree.
Only confirmed exhausted non-Pro state receives Quiet Lattice; unknown/unavailable
access stays protected; verified Pro is clean even if usage storage is unavailable.

Only Keychain `errSecItemNotFound` means new (count0/limit1). Corrupt, unsupported,
boolean/noninteger or inconsistent records and other Keychain failures fail closed.
An old installation without a surviving record is indistinguishable from new,
including never-exported or Pro-only installations; it receives one export. No
install-date, gallery/account proxy, new identifier or tracking is introduced.
This unavoidable edge is covered by the owner's explicit simple-migration approval.

Alternatives: no change misses the approved policy; global limit1 removes legacy
remaining uses; an additive v1 field is dropped by old writers and can restore two
uses. Explicit v2 makes old binaries reject unknown records safely. Rollback must
therefore use a v2-aware binary; do not delete records to downgrade. A backend or
billing SDK adds cost/privacy/identity complexity without resolving absent history.
No new provider, dependency, paid service or backend change.

Existing limitations remain: per-device persistence, uncertain reinstall survival,
and the process-death gap between external destination success and Keychain commit.
No atomic cross-service guarantee is invented. Test seeds operate only under DEBUG,
explicit UI-testing plus a valid UUID namespace, on absent test records. They never
read/write the owner's production quota and are forbidden in Release resources/code.

Validation: new1/legacy0/1/2, strict decoding and v2 roundtrip, failed migration probe,
dirty success/retry/relaunch, cancellation, concurrent reservations, duplicate
completion, Pro/expiry, native Save/Share cross-path blocking, subscription lifecycle,
Vision/normalized region/Undo/preview-export regressions, release-resource guard.
The missing dedicated Design Agent is recorded for follow-up; owner-approved visual
assets and completed independent visual review satisfy this internal beta checkpoint.
Internal TestFlight archive/upload is explicitly authorized; public submission,
live listing replacement and protected-main merge remain unauthorized.
