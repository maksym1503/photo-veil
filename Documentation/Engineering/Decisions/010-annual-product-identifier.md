# ADR-010 — Match the annual product to App Store Connect

Accepted 2026-10-26 following CTO review and read-only resource verification. Preserve the dirty working tree, existing signing, bundle identifier, gallery/metadata contracts and two-successful-export allowance.

The canonical paid products are `vail.pro.monthly` and `vail.pro.annual` in Photo Privacy Pro (group22471223). Live Apple annual resource6822764295 has ONE_YEAR duration. The earlier `vail.pro.yearly` resource6822760203 belongs to obsolete Photo Privacy Yearly (group22475732); identify it but do not delete or mutate it.

Change only the canonical StoreKit identifier, local test fixture and explicit tests/current instructions. Keep internal `yearlyID`/Plan.yearly/customer-facing Yearly terminology: those describe duration, not an Apple identifier. Entitlement filtering, purchases, updates and restoration all use the central allowlist. Do not add a legacy entitlement alias. Evidence supporting first-release status: owner context, paginated Apple version history contains only1.0 PREPARE_FOR_SUBMISSION, no builds, no beta groups, and all three products MISSING_METADATA. This is prelaunch reconciliation, not removal of a known customer entitlement. If contrary purchase/release evidence emerges, stop and obtain an explicit compatibility decision.

No Keychain/gallery/account schema migration: the device allowance contains only version/count; Pro access derives from verified Apple transactions. Preserve historical evidence/ADRs with their original identifiers; this ADR supersedes earlier product-ID setup instructions.

Live monthly Poland price14.99PLN differs from owner target12.99; annual99.99 matches. Both have no introductory offers; annual availability is missing. Prepare exact price/trial changes locally, but do not alter prices, offers, availability, agreements, signing or submission state without the applicable owner approval. Safe draft localization/equal-feature level reconciliation is reviewed separately before any write. Marketing proposals and screenshot rights are not automatically approved by successful technical validation.

Acceptance: native annual load/purchase/trial/group eligibility/restart/restore/revocation tests, free-export regression tests and Release build. Preserve prior failed single-runtime QA evidence; local StoreKit testing is not Apple Sandbox or distribution acceptance.


CTO separately approved the prelaunch annual service-level2→1 correction and exact approved en-US group display name in draft metadata. Read-backs confirm level1 and PREPARE_FOR_SUBMISSION group version. Price/offer/availability and obsolete records were untouched. Fresh Commerce finished22/23 (monthly renewal event wait failed); annual migration/restore tests passed. Preserved logs do not identify an infrastructure cause, so no policy rerun was performed. Unsigned arm64 Release/test-isolation passed; distribution/owner gates remain.
