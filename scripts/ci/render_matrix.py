"""Generate the reviewable matrix from the audited per-test inventory."""
import json, re
from pathlib import Path
root = Path(__file__).resolve().parents[2]
rows = json.loads((root/'Documentation/CI/test-inventory.json').read_text())
head = '''# Test inventory and layer assignment

Baseline before migration: **50 core + 35 UI methods**. All remain represented. Added methods are marked in the baseline column. PR has 48 core + four UI; Integration repeats those core tests plus two real Vision + all 35 legacy UI cases. The two AppKit performance methods run in the macOS integration profile. One real-device case supplements these plans. Counts overlap; no test is deleted or implicitly skipped.

Each entry records the protected behavior, boundary sensitivity and merge role. “Vision” means real analysis is exercised, not that state/render assertions intrinsically require Vision. App-owned menus/confirmation sheets are not system UI. Runtime categories: short <10 seconds typical; long environment-sensitive. Exact measured timings belong in PERFORMANCE_BASELINE.md. The JSON inventory and plan membership are enforced by scripts/ci/validate.py.

| Test | Behavior protected | Type | Deterministic | Real Vision | System UI | Layer | Blocks PR | Runtime | Flakiness / sensitivity | Baseline |
|---|---|---|---|---|---|---|---|---|---|---|
'''
for r in rows:
    vals=[f"`{r['id']}`",r['behavior'],r['current_type'],r['deterministic'],r['real_vision'],r['system_ui'],r['layer'],r['blocks_pr'],r['runtime'],r['flakiness'],r.get('baseline',False)]
    head += '| ' + ' | '.join(str(v).replace('|','/') for v in vals) + ' |\n'
head += '''
## Backend / security (parallel GitHub layer)

These do not consume iOS Simulator capacity. All block PR and use disposable fixtures/mocked HTTP; real production credentials are not required.

| Test / check | Behavior | Type | Deterministic | Vision / System UI | Layer | Blocks PR | Runtime | Flakiness |
|---|---|---|---|---|---|---|---|---|
'''
for name in re.findall(r'Deno.test\("([^"]+)"', (root/'supabase/functions/tests/deletion_test.ts').read_text()):
    head+=f'| `{name}` | {name} | Deno + mock HTTP | Yes | No / No | Backend | Yes | short | None known |\n'
head+='''| `ownership.sql` | User A cannot read/insert/update/delete user B metadata/files/profile; own upload allowed; deletion gate prevents writes/reopening | SQL/RLS in disposable PostgreSQL | Yes | No / No | Backend | Yes | short | Schema shim lacks managed service integration; deployed two-account acceptance also required |
| `vault_privileges.sql` | Client cannot read/write provider credentials; service role can; auth deletion removes credential and Vault secret transactionally | SQL privileges | Yes | No / No | Backend | Yes | short | Same disposable shim limitation |
| `DeviceCIContractTests` (five Python tests) | Approved artifact SHA, positive executed case count, honest provider failure, no private URLs/credentials in evidence; no network | Python + mock HTTP | Yes | No / No | Backend | Yes | short | None known |
| Migration application | Both committed migrations apply on clean disposable schema | PostgreSQL | Yes | No / No | Backend | Yes | short | Service-specific extensions separately verified during owner deployment |
| Deno check | All three Edge Function entry points typecheck | Static | Yes | No / No | Backend | Yes | short | Dependency download availability |
| Inventory/plan/secret-pattern validation | Every Swift test assigned; no missing legacy UI; required plan contents; no tracked private keys/JWTs | Python/static | Yes | No / No | Backend | Yes | short | Pattern scan is defense in depth, not a comprehensive secret audit |

## Guarantee mapping

- High-volume rapid state/renderer cancellation: `testCancelledPreviewQueueSkipsObsoleteWorkAndLatestMatchesExport` plus representative PR composed UI; retained rapid rendered-state integration.
- Automatic history cannot evict Manual: `testHighVolumeAutomaticHistoryCannotEvictAnyManualSnapshot` (all categories, beyond capacity), PR Undo/pixel restoration; retained UI stress.
- Independent layers, scoped Clear All, cache/re-entry, pending vs zero: DetectedPrivacySelectionTests + composed/empty PR smokes + all V4.2/V4.3 integration tests.
- Mixed styles, overlaps, full composition, preview/export: native PrivacyImageRendererTests all-layer matrix and pixel checks + PR Done/local-save fingerprint + full-resolution legacy Share/Save workflows.
- Documents detection correctness: native `testRealDocumentProducesBoundariesAndDetails` and retained `testDocumentDetailsAndWholeRedaction`; deterministic PR details/whole/cache UI uses only substituted analyzer geometry.
- Photos/Share/animations/accessibility: retained named integration tests, provider capability pilot and explicit owner iPhone release checklist.
- Accounts/cloud boundaries: deterministic existing core mocks and backend/RLS tests; real provider acceptance waits for separate owner configuration, not faked here.
'''
(root/'Documentation/CI/TEST_MATRIX.md').write_text(head)
