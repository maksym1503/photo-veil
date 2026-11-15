# CTO / architecture record

Configured `cto` (gpt-6-astra/low), `/root/quota_cto`, read-only. Before
implementation accepted ADR-014's same-Keychain v2 count+limit migration, v1
legacy2/new-absent1, read-only preview, pre-admission write probe, failure/dirty
success handling and coherent published snapshot. Owner's explicit policy approval
closes the prior migration gate. No further owner architecture decision required.
Separately accepted bounded stale local-matrix count maintenance with unchanged
membership/runtime splits/fingerprints/one-run checks and explicit count guard;
ADR-008 records153Integration/102PR/31Commerce. No new provider or test layer.
No implementation or tests were performed by CTO.

## Evidence/formatting maintenance decision

GitHub repository-security caught valid archived patch-context whitespace plus one
preexisting extra terminal blank line in MetadataSafeJPEG.swift. CTO independently
inspected all three patch files and that source ending. Accepted: finish frozen
behavioral QA; losslessly/deterministically gzip archives with raw-hash verification;
remove only the extra final LF in worktree and commit. Verify every other compiled
source/test/config input unchanged, retain separate tested/final fingerprints, then
run final-commit PR CI and final Release build/guard. No complete matrix repeat is
needed for that mechanically proven nonfunctional-only delta. Do not claim matrix
ran on the final raw SHA; index-only source cleanup was rejected. No CI weakening.

## Hosted PR cancellation and internal-beta boundary

CTO classified initial run43727405001 as job-budget cancellation with incomplete
coverage, not green and not demonstrated product failure (95core+6UI passed,
final UI in progress). Reason for remote slowness is unproven. It blocks merge,
not by itself the expressly authorized internal beta. No old-job rerun, timeout
inflation or CI redesign. Genuine cleanup gets normal new-revision CI.

Internal upload may proceed only with strict local PR,153 matrix, Commerce, both
macOS profiles and final Release/archive checks passed; proven EOF-only delta;
final repository-security/backend checks passed; no unresolved product/security
finding. Record incomplete hosted Apple coverage if it recurs. Physical/system-UI
acceptance and public release qualifications remain separate; PR7 stays unmerged.
