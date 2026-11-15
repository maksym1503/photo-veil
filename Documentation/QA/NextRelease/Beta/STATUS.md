# Vail1.1(8) internal beta checkpoint

Branch `feature/vail-1-1`. Owner authorizes normal App Store Connect distribution
archive/upload to existing internal group only. No public review submission, live
listing replacement, additional testers or protected-main merge.

Migration implemented per ADR-014; Developer Commerce14/14 and final expanded
Commerce16/16 pass. Independent Reviewer P1 test finding corrected/rechecked.
CTO architecture/count-maintenance decisions recorded separately. Full release QA
is running with frozen production/test source; no upload has occurred yet.

Configured `qa` (gpt-6-luna/medium) performed inventory/workflow preflight and
PR/Integration compilation, then reached its usage limit (retry availability15:49).
Root performs serialized native execution during that limit; results are not
misrepresented as independent QA-agent execution. No paid credits activated.
All current native outcomes and original failures will be retained here.

Production prerequisite changes retained in the dirty workspace from1.0 are
included as dependencies of the1.1 branch commit. Hash comparison confirms app
authentication, metadata storage, Photos saving, renderer, account and library
files match the retained1.0 candidate. Backend/deployment work outside this app
release remains unstaged and preserved; see prerequisite provenance.

Known migration edges: absent legacy record is indistinguishable from new; no
owner Keychain/history reset. v2-unaware downgrade fails closed. Existing external
success-to-Keychain process-death gap and device-local persistence remain.

Public/V4 owner/backend gates remain; physical iPhone acceptance is the purpose
of this beta. Source/binary/commit/TestFlight evidence will be appended after QA.

Implementation commit `38fc89e` includes the integrated app and required existing
production prerequisites. Staged whitespace audit found historical patch-context
whitespace and the unchanged production MetadataSafeJPEG final blank line; those
source/evidence bytes are preserved. This is not a product/test failure.

Signing guard initially rejected staged owner-local team settings. The unpublished
commit was corrected by sanitizing only the Git index; the working project was
verified byte-identical before/after. Team stays local for the approved archive.

QA resumed after its stated limit window. Root's full PR execution passed102/102
(95core+7UI); QA independently ran the strict102-case execution verifier. Current
Integration153 compatibility matrix is executing serially under the QA role.
Draft PR: https://github.com/maksym1503/photo-veil/pull/7; implementation commit
38fc89e28d9d3f1efc8a7490d9a943d7e7864ea5 pushed. No merge.

## Initial Integration failure and corrected candidate

The first26.5 shard stopped after a deterministic fixture failure in V43Composed:
it saved once then expected native Share under the new one-use allowance. The
product correctly gated that second admission. Native bundle is incomplete after
SIGINT; preserve original raw bundle/log without claiming inspected failure images.
Independent Reviewer audited all output/relaunch paths, identified the composed,
full-composition and custom-watermark tests needing explicit UUID legacy0 fixtures,
and rechecked all three fixes with no assertions removed.

The stopped run is not a green matrix. A fresh complete PR/matrix is required on
the corrected source. Since no completed frozen matrix was transferred, the
lossless archive compression and exact one-LF source cleanup were applied BEFORE
that fresh candidate. New full QA will use its own source/build fingerprints;
there is no claim that the original candidate's bytes equal this revision.
