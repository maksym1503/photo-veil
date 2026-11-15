# ADR-015: Scope the PR build to its canonical plan

Accepted2026-11-15 after configured CTO consultation; owner authorizes merge/public
release, requiring genuine protected CI success. Existing job cancels at20minutes
after setup/build consumes~12minutes. The scheme demonstrably builds unrelated
legacy UI and hosted Commerce test targets, while VeilPR executes only core+PR UI.

Add a shared VeilPR scheme building app/core/PR UI only, referencing the unchanged
canonical VeilPR.xctestplan; select it only for that plan. Other plans/archive keep
PhotoVeil. Preserve102case exact verifier, serial execution,180second case ceiling,
20minute job budget, artifacts, required job names and branch protection. Add a
focused infrastructure assertion for scheme membership/plan. Verify actual hosted
build omits unrelated products and executes all102 successfully. Improvement is
plausible, not yet measured or guaranteed.

No-change leaves required check blocked; cache alone cannot guarantee cold-run
completion and adds provenance complexity. Split build/test jobs are a larger
fallback needing same-run artifact/toolchain checks and fresh CTO consultation.
No budget inflation, skipped cases, administrator bypass or replacement green.
Reuse accepted release matrix for unchanged functionality. UI copy gets targeted
Light/Dark captures; final Release/signing validation remains required. No new
provider, dependency, privacy or data change; no further routine owner approval.
