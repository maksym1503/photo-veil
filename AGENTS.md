# Veil engineering instructions

Maksym is CEO/Product Owner. Follow his product intent; make routine engineering
choices autonomously. Preserve existing uncommitted work, especially signing and
DEVELOPMENT_TEAM changes. Inspect git status before edits; never reset unrelated work.

Route each task by risk, not file count:
- FAST: small, isolated, reversible work. One coordinator implements and validates;
  no CTO, ADR or subagents required.
- STANDARD: root acts as Engineering Lead. Inspect code, state acceptance criteria,
  implement directly or delegate bounded implementation when useful. **Spawn an
  independent reviewer** after implementation; address findings and validate.
- ARCHITECTURE: **delegate to CTO before substantial implementation**, record a short
  ADR, resolve any owner gate, then implement, independently review and verify with QA.
  Includes privacy/security, authentication, data lifecycle/schema/format, backend,
  concurrency, major dependency, infrastructure, CI/test architecture, app-wide state,
  navigation or performance architecture and irreversible behavior.

These instructions explicitly request delegation for the stages above. Root alone
spawns; use named roles from .codex/agents. Keep at most two open child threads plus
root, no nested agents, disjoint write ownership, targeted context. Do not spawn a
Lead to duplicate the root. See Documentation/Engineering/WORKFLOW.md when planning
STANDARD/ARCHITECTURE work, escalating, or selecting/testing role models.

Start substantial work: mode, roles, why, owner input needed. Finish: changes,
roles actually used, validation evidence, decisions, unresolved risks and owner actions.

Owner approval is required before paid services/credits, provider registration,
Xcode Cloud/BrowserStack activation, private builds uploaded to device farms,
production credentials/secrets, signing identities, bundle IDs, App Store/external
TestFlight distribution, destructive production migrations or irreversible/product
privacy tradeoffs. Never infer release or high-risk merge approval from green CI.
Existing explicit authorization counts; routine local work needs no extra permission.

Repository context: one iOS app plus SwiftPM core and Supabase backend, not an App Lab.
Read README.md and relevant Documentation/Architecture files before affected changes.
Preserve README's V4 merge/owner acceptance gate. For testing/CI work read
Documentation/CI/TESTING_STRATEGY.md and TEST_MATRIX.md; these own test-layer details.
Use targeted tests; never arbitrary sleeps, inflated timeouts or retry-until-green.
Repeated flaky patches require reassessment of the test architecture. Do not activate
new providers. Never put personal photos, OCR payloads or secrets in evidence.
