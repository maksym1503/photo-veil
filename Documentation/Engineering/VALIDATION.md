# Orchestration validation

Inspection date: 2026-10-09. CLI: **0.160.0**; background app-server: **0.162.0**.
Single Git repository: iOS app, SwiftPM core and Supabase backend. No pre-existing
repository/ancestor AGENTS.md, project .codex or project skills were found. Existing
engineering/CI documentation was retained. Personal Codex configuration was not changed.

## Configuration evidence

- `python3 scripts/validate_orchestration.py --schema /tmp/veil-config-schema.json`:
  official schema validation passed for project config and all five role config layers;
  role manifest fields were checked separately against the documented standalone format.
- `codex --strict-config doctor --json`: installed parser passed, effective project model
  was `gpt-6.1-sol`. Unrelated diagnostic: macOS desktop security assessment unavailable.
- `codex debug models`: refreshed account catalog contains Astra, Sol and Luna with
  all configured efforts. These are account catalog IDs, not invented API aliases.
- A local stdio app-server `config/read` returned project model Sol and enabled agents
  with `max_concurrent_threads_per_session = 2` and Luna/medium child defaults.
- `codex debug prompt-input`: root AGENTS.md appeared in model-visible instructions.
- Python validator compiled successfully; no product build needed for this change.

The public schema is current documentation, not a version-pinned local schema. Installed
strict parsing and live role calls supplement it. The validator requires Python 3.11+
or Python with `tomli` (already available on the inspected machine). Optional `--schema`
also needs `jsonschema`, already available here. It makes no model turn; catalog/doctor
may contact existing Codex endpoints. No new dependency was installed.

## Read-only live simulations

Each used `codex exec --strict-config --ephemeral -s read-only --json`, existing account
authentication and the actual project instructions. No simulated feature was implemented.

| Scenario | Observed result |
| --- | --- |
| FAST: smaller Gallery title | Root only; zero collaboration events, no CTO/ADR; proposed visual/accessibility checks; no routine owner gate. |
| STANDARD: session-only favorites filter, assuming an existing favorites contract | Named Developer (Luna/medium) produced plan; separate Reviewer (Sol/medium) found hidden deletion-selection and observable-update gaps. Root amended proposed acceptance criteria. No CTO. |
| ARCHITECTURE: sync through a paid provider | Named CTO (Astra/low) returned alternatives and a proposed decision before any implementation; QA (Luna/medium) confirmed the spending, registration and privacy/product owner gate. No provider action or implementation followed. |

The ARCHITECTURE coordinator reported all five named roles available, and used fresh
targeted context for CTO then QA. The client exposes interruption but no close tool:
children completed sequentially and were interrupted; actual thread closure was not
verified. WORKFLOW.md documents slot reuse without sacrificing reviewer independence.
Engineering Lead was discovered; a separate Lead child was intentionally not invoked
because root already performs that role.

STANDARD's existing-contract premise is deliberately hypothetical: code inspection found
no favorites field. Real favorites work must inspect storage and escalate if it changes
the format. A plan review does not prove feature implementation or Swift capability.

Raw local smoke outputs were written under `/tmp/veil-{fast,standard,architecture}-*`;
they are temporary diagnostics, not tracked transcripts. JSONL exposed collaboration wait
activity and coordinator role reports, not a complete child-spawn/model audit trail.
Do not interpret these simulations as exhaustive concurrency or enforcement testing.

## Repeat after changing model mapping or upgrading Codex

1. Run `python3 scripts/validate_orchestration.py`. For optional public-schema checking,
   download https://learn.chatgpt.com/docs/config-schema.json to a temporary path and
   pass it with `--schema`.
2. In a fresh read-only Codex session, ask: “Routing simulation only: make Gallery title
   smaller. No edits/tests. Report actual roles.” Confirm FAST stays solo.
3. Ask: “Read-only STANDARD simulation: session-only favorites filtering assuming an
   existing contract. Delegate a bounded plan to Developer, then separate Reviewer.
   No edits/builds.” Confirm independent critique and no CTO without architecture change.
4. Ask: “Read-only ARCHITECTURE simulation: cross-device sync using a paid provider.
   CTO first, then QA audit of routing. No implementation, account setup or spending.”
   Confirm decision precedes work and owner gate blocks dependent actions.
5. Check actual role/model reports and tool activity, effective project config, Git diff
   and preservation of existing local changes. Do not run all smokes for routine work.

Filesystem read-only mode does not itself prevent external connector side effects;
these tests also explicitly prohibited external actions. Owner gates and no-nesting
remain instruction policies. No universal hard budget or approval enforcement is claimed.

## Change isolation

Only orchestration configuration, instructions, documentation and its validation script
were added. No product source, existing CI or test plans were edited. The pre-existing
`PhotoVeil.xcodeproj/project.pbxproj` local signing change was preserved byte-for-byte:
SHA-256 `93d9651bc99b0cc783f5d178cbe40e571357d0d6f55c766a015da7c82026a375`.
No commit, merge, provider activation or release was performed. Product tests were not
run because no product behavior changed. Read-only smoke Git status calls emitted
macOS xcrun cache-denial warnings; they still returned status and did not run app tests.

Independent Sol/medium review of the actual orchestration files found no correctness or
authority issues. Its request to record the completed ARCHITECTURE outcome was resolved
and rechecked. Final evidence audit confirmed the stated limitations and signing hash;
the reviewer did not independently rerun model smokes or inspect their temporary logs.
