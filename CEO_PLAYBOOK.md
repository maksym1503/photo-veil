# Working with your engineering team

Describe the product outcome in ordinary language. Codex chooses the smallest team;
you do not need to pick models or manually hand work between roles. Start a **new Codex
session in this project** after setup so it loads the project defaults.

You own priorities, UX, budget, releases and consequential product choices. Codex handles
routine engineering. It announces FAST, STANDARD or ARCHITECTURE and tells you whether
it needs a decision. At the end it reports changes, checks, risks and actual agents used.

| What you say | What should happen |
| --- | --- |
| “Make the Gallery title slightly smaller.” | FAST: one agent makes the small change and checks it. No CTO. |
| “Add favorites to Private Gallery.” | STANDARD: Lead inspects storage and defines behavior, implements or delegates, then gets independent review. A new storage format/migration triggers CTO first. |
| “I want users to sync their gallery between devices.” | ARCHITECTURE: CTO inspects existing optional cloud support and compares privacy, cost and conflict behavior before implementation. You decide material product tradeoffs or provider spending. |
| “Faces sometimes disappear after Undo.” | Investigate state and reproduce; normally STANDARD with a focused regression test and independent review. CTO only if the architecture must change. |
| “Integration failed.” | First classify evidence as product, test, infrastructure or unknown. Fix the cause at the right layer; do not keep retrying or stretch timeouts to get green. |
| “Compare ways to make exports faster before changing anything.” | Investigate and report alternatives; CTO if a significant performance architecture decision is needed. No speculative rewrite. |
| “FAST: fix this typo; keep it in one agent.” | Skip management overhead for this isolated task while retaining safety boundaries. |

Expect decisions from you for paid services, external account setup, signing/production
credentials, destructive data changes, releases and material privacy/product tradeoffs.
You do not approve every refactor or test. An architecture note should present a short
recommendation, alternatives and consequences, not a technical essay.

Normally one to three agents work at a time, including the coordinator. Strongest-model
time is reserved for architecture and critical uncertainty. Agents will flag unavailable
models or missing independent review rather than pretending validation happened.

The routing is instruction-driven, not an infallible approval system. Explicitly selected
models can override the project default; new sessions normally use the configured Lead.
[Engineering details](Documentation/Engineering/WORKFLOW.md) and
[validation evidence](Documentation/Engineering/VALIDATION.md) are available when needed.
