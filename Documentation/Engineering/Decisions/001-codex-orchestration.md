# ADR-001: Project-local Codex engineering roles

Status: accepted · Date: 2026-10-09
CTO: gpt-6-astra, low · Decision authority: Engineering Lead within requested setup

- **Problem:** catch costly architecture mistakes early without a management swarm.
- **Constraints:** installed Codex 0.160.0, existing account, no API/new services,
  no product/CI redesign, preserve local signing changes and existing owner gates.
- **Alternatives:** instructions alone (no model-specific roles); project-local native
  agents (selected); custom runner/service (unnecessary maintenance/cost).
- **Decision and why:** concise root routing, five native TOML roles, Sol coordinator,
  Luna bounded implementation/QA, Astra architecture, Sol independent review.
  Root alone dispatches. FAST stays solo. Architecture decisions precede implementation.
- **Risks:** instruction compliance is not enforcement; active/UI model overrides;
  availability changes; confusion between per-session thread limits and total agents.
- **Cost / operations:** existing Codex usage only; cap two open children, no nested
  spawning; targeted context and economical effort. No paid infrastructure.
- **Reversibility:** remove project configuration/instructions; no runtime/data migration.
- **Testing:** strict local parser, role discovery, model catalog checks, read-only
  FAST/STANDARD/ARCHITECTURE simulations and unchanged product/signing fingerprint.
- **Assumptions:** trusted project; new local sessions load defaults; Luna competence
  assessed per task; named roles may need explicit fallback in other clients.
- **CEO approval required:** no additional approval; this setup was explicitly requested
  and does not change product, spending or release behavior.
- **CTO review:** approved before implementation with root-only spawning, independent
  review, proportional QA, preserved Veil merge gates and honest runtime validation.
