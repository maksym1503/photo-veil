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
