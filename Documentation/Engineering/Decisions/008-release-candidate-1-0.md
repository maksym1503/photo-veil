# ADR-008 — Commercial 1.0 release preparation

Accepted 2026-10-13 after read-only CTO review. Preserve existing uncommitted work, production identifiers, signing/team settings, rendering/export contracts and V4 owner acceptance gate.

Use **Blur, Watermark & Metadata** as the owner-approved App Store listing name. Retain compact Home Screen/in-app Veil branding, `com.maksym1503.veil`, `veil://`, internal target names and `vail.pro.monthly` / `vail.pro.yearly`. The App Store Connect group display name is **Photo Privacy Pro**; it is not an entitlement identifier. Set marketing version 1.0 and local build 5, incrementing the existing local build 4. Build 5 remains provisional until the owner checks existing App Store Connect uploads.

Correct the local Apple test runner to retain normal simulator ad-hoc signing: the success-only free-export counter uses Keychain, which unsigned application hosts cannot validate. Add the existing VeilCommerce plan. Default StoreKit-containing plans to installed iOS 26.1, where native configuration activation was verified; fail clearly if unavailable. Keep explicit destination overrides and newer-runtime PR coverage. Do not alter signing identities, register providers or activate CI services.

Preserve Keep metadata as the default, fail-closed Remove, original preservation, flattened watermark exports, verified Apple entitlements and two successful free output operations. No new backend, dependency, account requirement or data-format migration. Legal links remain unset until approved real HTTPS destinations exist; never bypass the purchase gate to make a candidate appear commercially ready.

Prepare fresh native tests, real screenshot assets, local legal-site source and a current status-led handoff. Simulator builds/unsigned archives are compile evidence; signed archive, physical-device, sandbox/cross-device, public legal, App Store Connect and V4 owner acceptance remain distinct release gates. No upload, submission, deployment or production activation is authorized.

## Native test isolation amendment — 2026-10-13

The first full135 Integration invocation passed133 and failed two hosted StoreKit cases while the UI target ran on another clone. Grace missed both intermediate/final expectations; concurrent refresh stalled in XCTest wait machinery and reached the existing600s execution allowance. Spindumps do not establish a user-code deadlock or prove GPU contention. Keep that failed evidence; causal specificity remains unresolved.

CTO approved one unchanged serial Commerce comparison and serial execution of the complete Integration plan to isolate hosted StoreKit/system UI on this host. Keep all135 cases, native StoreKit, existing assertions and timeouts. This increases wall time; a targeted pass cannot supersede the full-plan failure. No retry, skip, simulated entitlement or production runtime change substitutes for full serial acceptance.

The first physical attempt stopped before execution because the scheme's four test targets have no team set. The existing app-only development archive succeeded. CTO approved a command-local `DEVELOPMENT_TEAM` override selecting the existing app team for one device-test comparison, without persisting signing changes or enabling provisioning updates/registration/certificate/profile creation. Missing runner provisioning remains a blocker. Harden VeilDevice to require an explicit physical `platform=iOS` destination: its historical implicit simulator selection must not masquerade as device acceptance.

## Local runtime compatibility matrix amendment — 2026-10-13

The unchanged serial 26.1 run completed 135 cases: 125 passed, ten UI cases failed after native OCR termination. A minimal standalone real-Vision executable reproduced the same SIGBUS outside Veil on 26.1; the unchanged plate-editing case passed on 26.5. This establishes runtime-dependent reproduction, not a complete crash root cause. Native StoreKit configuration activation remains blocked on installed 26.5.

CTO approved a **local** compatibility matrix: 126 non-StoreKit Integration cases on 26.5 and eight native StoreKit cases plus the real-trial UI case on 26.1. Keep plans, IDs, assertions, timeouts and production processing unchanged. A strict local aggregator requires all 135 unique expected cases, assigned runtime passes, zero skips/retries and matching source/build fingerprints. Each assigned shard must pass completely. Preserve both failed full-plan runs; report matrix acceptance separately, never as a successful single-runtime Integration run. Existing CI/default behavior is not rewritten; its known runtime limitations remain documented.

Final local acceptance: both assigned native invocations exited0; strict aggregation verified135/135 unique cases, exact runtimes, one execution each, zero failures/skips and allfour equal source/build fingerprints. Independent CTO evidence review confirmed. Sanitized evidence: `Documentation/AppStore/Evidence/Release-1.0/compatibility-matrix/`. Original single-runtime failures and external gates remain open in the QA report.

## Vail1.1 inventory maintenance —2026-11-15

CTO accepted bounded maintenance of the existing local compatibility matrix after
reconciling current inventory. Final inventory163, separate PR102 (95core+7UI),
Commerce31 (16core+8hosted StoreKit+7UI). Canonical local Integration153 unique
cases =144 on26.5 +9 on26.1, excluding7 separately run PR UI and2 opt-in macOS
profiles. Preserve the same explicit membership/shard boundaries, source/build
fingerprints, exact case-set and one-run validation, zero failures/skips and runtime
checks. Only count guards/report totals change; no provider/test-layer redesign.
This matrix is not a single-runtime Integration pass. Run both macOS profiles and
Release validation separately; physical owner acceptance follows internal beta.
