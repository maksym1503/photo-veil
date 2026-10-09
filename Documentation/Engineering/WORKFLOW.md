# Engineering workflow

Maksym owns product, UX, priorities, budget, production release and irreversible
choices. The root coordinator owns routing and integration. This is a project-local
Codex instruction layer, not a service or an automatic release system.

## Smallest competent team

| Mode | Sequence | Gate |
| --- | --- | --- |
| FAST | Coordinator → relevant validation | No agents or ADR |
| STANDARD | Root as Lead → direct implementation or scoped Developer → separate Reviewer → validation | CTO only if architecture emerges |
| ARCHITECTURE | CTO → concise ADR → owner decision if required → Lead/Developer → Reviewer → QA → validation | Decision before large implementation |

A new feature can start STANDARD, then escalate if inspection reveals a new storage
format or privacy boundary. Contained persistence behavior using an existing contract
can stay STANDARD. Cloud sync, authentication, backend authorization, data ownership,
concurrency, new major dependencies/providers, CI/test design and app-wide state changes
are ARCHITECTURE. Changes to geometry/rendering *architecture* qualify; an isolated
math bug does not automatically require CTO.

Root acts as Lead; the named engineering_lead role is for a bounded planning or complex
implementation assignment, not an extra management layer. Child roles return assignments
to root rather than spawning. At most two child threads plus root; close completed
threads where supported, or reuse them without violating reviewer independence.
If the client has no close tool and finished threads still consume slots, reuse the
read-only CTO thread for independent review (it must not have implemented), and the
implementation thread for QA with explicit QA instructions. Report these actual roles
and pinned models; do not spawn a third child or describe a reused thread as fresh.
Run dependent steps sequentially. Never let two agents edit the same files. Never run
independent UI xcodebuild sessions concurrently on this host.

Delegate only when independence, complexity or review warrants it. Send objective,
acceptance criteria, owned files, constraints/ADR, relevant evidence and expected output.
Use a fresh targeted context instead of full conversation forks when changing models.
Return concise findings/evidence, not transcripts. A role is a responsibility, not a
requirement to create a new agent for every step. QA can be performed by the coordinator
for STANDARD work; ARCHITECTURE uses the QA role after review.

## Authority and escalation

- Developer → Lead: material scope growth, cross-system work, conflicting architecture,
  significant dependency. Stop affected edits; report evidence and smallest alternatives.
- Lead → CTO: architecture/security/privacy or data lifecycle changes, new provider,
  material cost, or repeated failures suggesting a wrong architecture. After two failed
  symptom fixes, reassess before a third; this is not permission to retry flaky tests.
- CTO → Maksym: paid service, owner registration, production credentials/signing,
  destructive migration, material privacy/product change, irreversible decisions or
  two reasonable product tradeoffs. Present a recommendation and concrete consequences.

Do authorized investigation and reversible preparation before asking for a decision.
Hold only dependent implementation/action. Existing explicit approval satisfies the
relevant gate. No approval is needed for routine technical choices. Root AGENTS.md
contains the owner action boundaries; they apply to all roles and tools.

## Architecture gate

Use Decisions/TEMPLATE.md only for ARCHITECTURE work. Root records CTO's decision;
CTO normally reads and advises, not implements. Status: proposed, accepted or superseded.
Technical decisions within delegated authority can be accepted by Lead after CTO review.
Owner-gated decisions remain proposed until explicit authorization is recorded. Link
superseded decisions. Keep the ADR roughly one page; include do-nothing/build-vs-buy
where viable. No ADR for ordinary features, fixes or every individual task.

## Review and evidence

Reviewer must be a separate agent that did not implement the change. Supply intent,
acceptance criteria, ADR and final diff; reviewer inspects actual code/tests, not only
implementation summaries. Return findings with severity and file references, or explicitly
state no findings plus validation gaps. No review edits. Implementer fixes findings;
reviewer rechecks the changed diff. Architecture drift blocks acceptance pending a decision.

Veil's CI lesson is to detect an architectural mismatch before spending days patching
symptoms. Deterministic PR coverage and real integration/system coverage answer different
questions. CI green is evidence, not the objective. Classify a failure as product,
test, infrastructure or unknown using the original logs/result bundle before acting.
Preserve failures and exact revision evidence. Apply the existing CI strategy, including
its bounded diagnostic rerun policy, without redesigning or enabling providers.
For another app, reuse these principles, not Veil's concrete test plans.

## Models and maintenance

Verified against CLI 0.160.0 account catalog on 2026-10-09 (installed background
app-server reports 0.162.0; versions can differ):

| Role | Model | Default effort | Reason |
| --- | --- | --- | --- |
| CTO | gpt-6-astra | low | Strongest available frontier reasoning; short decisions |
| Root / Engineering Lead | gpt-6.1-sol | medium | Current coding workhorse; coordination and ambiguity |
| Developer | gpt-6-luna | medium | Fast/affordable model for bounded implementation |
| QA | gpt-6-luna | medium | Focused evidence and test selection |
| Reviewer | gpt-6.1-sol | medium | Stronger than ordinary implementation model |

Catalog supports low/medium/high/xhigh/max for all three, plus ultra for Astra/Sol.
Do not use max/ultra automatically. Increase reasoning to high for expensive mistakes.
Luna suitability is task-specific: its smoke test is not proof for arbitrary Swift work.
If scope is ambiguous, delegate complex implementation to engineering_lead (Sol) or let
root implement. If Luna fails a well-scoped attempt, diagnose once, then promote if needed;
never cycle cheaper agents hoping for success. Review must be at least implementation
capability; if Astra implementation is exceptionally necessary, request an independent Astra
review using CTO's read-only role with an explicit review assignment; the reviewer must
not be the Astra implementer.

Named role files pin model and effort and take precedence over spawn overrides. For a
one-task higher-effort review/CTO consultation, use a generic fresh agent with explicit
verified model/effort and the corresponding role instructions; do not pretend an override
changed a pinned role. Log the effective role/model. No redundant strongest-model reread.
There is no verified account price table here; affordability follows catalog descriptions,
not invented dollar or token savings.

To update: run `codex --version` and `codex debug models`, inspect available model IDs and
supported efforts, update .codex/config.toml and relevant agent files, then update this
table. Run `python3 scripts/validate_orchestration.py` and the read-only smoke procedure in
VALIDATION.md. Do not silently substitute an unavailable model; report and choose a
verified suitable replacement. No OpenAI API keys or additional services are needed.

## Limits and bypass

Trusted project configuration applies to new local Codex sessions. This repository is
already trusted on the inspected machine. A selected UI/CLI model or existing session
can override/preserve the root model; instructions cannot switch an active parent model.
Start a new project session to pick up configuration. Higher-priority environment policy
can limit delegation or tools. When named roles aren't exposed, use explicit verified
model/effort plus that role file's instructions if available; disclose the fallback.
Do not claim independence when no separate reviewer can run.

Routing, owner boundaries, no nesting and file ownership are instruction policies, not
security enforcement. The CLI caps open child threads per session, not a universal
cross-process budget; root enforces the total tree limit. Read-only CTO/reviewer sandboxes
restrict filesystem writes, not every external connector. Existing host permissions remain
in force. No hooks, auto-merge, new CI, secrets or global configuration were installed.

For deliberate simple work say: “FAST: fix this typo; keep it in one agent.” This bypasses
ceremony, not owner boundaries or architecture gates. Completion reports distinguish tests
actually run from suggested checks, and list only genuine remaining owner actions.

Sources: [official custom agents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).
Installed diagnostics and the current account catalog take precedence over example names.
