# V4 CI migration validation — 2026-10-08

No product UI, effects, geometry or authentication behavior was redesigned. The production change is the analysis interface delegating to the existing Vision functions; fixture implementations and isolated test storage are DEBUG-only.

| Validation | Result | Evidence |
|---|---|---|
| VeilPR, iPhone 17 Pro / iOS 26.5 | 52 passed, 0 failed/skipped | `/tmp/veil-layered-pr-first.xcresult` |
| Final wrapper: VeilPR, iPhone 13 mini / Dark / iOS 26.5 | 52 passed, 0 failed/skipped; 232.51 s end-to-end | `/tmp/veil-layered-pr-final/Tests.xcresult`, summary/tests/timing/phases JSON |
| Tightened empty-state AX query | focused test passed; query checks any matching pending indicator, not only activity-indicator node type | `/tmp/veil-layered-pr-focused.xcresult` |
| VeilIntegration, iPhone 17 Pro / iOS 26.5 | 85 passed, 0 failed/skipped; native execution 1,382.129 s | `/tmp/veil-layered-integration/Tests.xcresult`; full existing 35 UI methods retained |
| macOS complete core + opt-in profiles | 50 passed, 0 skipped; 10.163 s tests | `/tmp/veil-layered-mac-core.log`; `/tmp/veil-v4-diagnostics/measurements.json`, `v43-composition.json` |
| Backend | ownership/RLS + Vault privilege/deletion scripts passed; three Deno entry points typechecked; five Deno tests passed | `/tmp/veil-layered-backend.log` |
| CI adapter security contracts | five Python tests passed without network/provider credentials | `python3 scripts/ci/test_infrastructure.py` |
| Release iOS build | passed; test analyzer/launch configuration and fixture JPEGs absent | `/tmp/veil-layered-release.log`; `scripts/ci/check_release.py` |
| Unsigned Release archive | passed; app archived, test bundles excluded; fixture exclusion passed | `/tmp/veil-layered-archive.log`, `/tmp/veil-layered-release-archive.xcarchive` |
| Final shared-budget PR plan | 52 passed, zero skipped; 167.90 s end-to-end; unchanged 180 s case ceiling | `/tmp/veil-layered-pr-budget/Tests.xcresult`; exact inventory passed |
| Serial PR plan, iPhone 17 Pro / Light | 52 passed, zero skipped; 287.10 s end-to-end including cold package/build setup | `/tmp/veil-layered-pr-serial/Tests.xcresult`; native inventory guard passed |
| First hosted layered pilot | 51/52 native; backend/security passed; merge blocked | Run 37738927381; Faces render pending after fixture analysis; see performance baseline |
| Native executed inventory | Exact 52/85 identifiers and all destinations passed; wrong-plan result rejected | `scripts/ci/verify_execution.py` against both native bundles |
| Inventory / plans / staged secret and signing guardrails | 92 Swift methods assigned; all 85 baseline methods retained; no staged signing team/private keys/server keys | `python3 scripts/ci/validate.py` |

Native real Vision tests: Documents 9.283 s; faces/tiled mapping 4.163 s. Five-layer render + JPEG profile: 1440×1800 0.081 s; 4032×3024 0.282 s; 8064×6048 1.215 s on this local Intel Mac. These are measurements, not iPhone/hosted latency promises.

The full Integration app/core/legacy UI sources correspond to commit `8ccdd22` (unchanged by the subsequent CI/documentation commit). The new PR test's pending-indicator query was subsequently tightened and revalidated in isolation. Full hosted gate evidence belongs to the final GitHub workflow run at the pushed SHA; its exported timings and final PR handoff are authoritative. See PERFORMANCE_BASELINE.md for the cancelled overlapping local pilot and wrapper-edit diagnostic; neither is hidden or counted as a passing measurement.

Xcode Cloud, a managed signed archive/TestFlight distribution, and vendor physical-device execution have **not** been activated or claimed as validated. Existing owner physical-iPhone approval remains separate evidence. Release acceptance requires exact-candidate integration and physical system-flow checks as defined in TESTING_STRATEGY.md. No build/fixture was uploaded to a real-device vendor during this task. Backend provider setup is unchanged.
