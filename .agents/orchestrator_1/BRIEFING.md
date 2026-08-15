# BRIEFING — 2026-08-14T18:13:15-07:00

## Mission
Extract and integrate rich icon texture information from Blizzard Cooldown Manager (CDM) tracked buffs, cooldowns, and live viewer frames so that WeakAuras, ThisWeeksAuras, and M33kAuras can automatically display exact spell/buff icons on displays, dynamic text (%i), and icon bindings across all trigger states.

## 🔒 My Identity
- Archetype: orchestrator
- Roles: orchestrator, user_liaison, human_reporter, successor
- Working directory: C:\Users\user\Documents\M33kAuraUtils\.agents\orchestrator_1
- Original parent: top-level
- Original parent conversation ID: 0a1e7606-c673-4f06-8dfa-99e24984125f

## 🔒 My Workflow
- **Pattern**: Project Pattern (Dual Track: Implementation Track + E2E Testing Track)
- **Scope document**: C:\Users\user\Documents\M33kAuraUtils\PROJECT.md
1. **Decompose**: Survey codebase with 3 parallel Explorers to extract full feature inventory and dependencies, then decompose into 3-7 coherent milestones with explicit interface contracts and code ownership.
2. **Dispatch & Execute**:
   - **Survey Phase**: Spawn 3 Explorers (`teamwork_preview_explorer` / `teamwork_preview_spec_miner`) to investigate codebase, CDM mechanisms, existing trigger state handling, test harness, and requirements.
   - **Parallel Tracks**:
     - E2E Testing Track: Spawn E2E test writer / subagent to build 4-tier test suite and `TEST_INFRA.md` -> `TEST_READY.md`.
     - Implementation Track: Sequential milestones (Icon Resolution Engine -> WA/M33k Trigger State Icon Binding -> Verification & Build Integration) running Explorer -> Worker -> Reviewer (x2) -> Challenger (x2) -> Forensic Auditor -> Gate.
3. **On failure** (in this order):
   - Retry: nudge stuck agent or re-send task
   - Replace: spawn fresh agent with partial progress
   - Skip: proceed without (only if non-critical; auditor is NEVER skipped)
   - Redistribute: split stuck agent's remaining work
   - Redesign: re-partition decomposition
4. **Succession**: Self-succeed at 16 spawns after all running subagents complete.
- **Work items**:
  1. Survey & Architecture Mapping [in-progress]
  2. E2E Testing Suite Track [pending]
  3. Milestone 1: Comprehensive Icon Resolution Engine [pending]
  4. Milestone 2: WeakAuras & M33kAuras Trigger State Icon Binding [pending]
  5. Milestone 3: Automated & In-Client Verification & Build Integration [pending]
  6. Milestone 4: Final Acceptance & E2E Pass [pending]
- **Current phase**: 0 (Survey)
- **Current focus**: Survey & Architecture Mapping (3 parallel Explorers)

## 🔒 Key Constraints
- DISPATCH-ONLY orchestrator: NEVER write source code directly, NEVER run build/test commands directly. Delegate ALL work.
- NEVER investigate or explore code directly — dispatch Explorers.
- Only edit metadata files (.md) in .agents/ folder.
- DO NOT CHEAT: zero tolerance for hardcoded test results, facade mocks, or dummy implementations.
- Binary veto on Forensic Auditor integrity violations.
- Never reuse subagents after handoff — always spawn fresh.
- MANDATORY ARCHITECTURAL INVARIANT (User Directive 2026-08-15): Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase. Utils must ONLY grab buff and cooldown information directly from Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer). Do not use C_UnitAuras for buff checking, fallback, or icon resolution.


## Current Parent
- Conversation ID: 0a1e7606-c673-4f06-8dfa-99e24984125f
- Updated: 2026-08-14T18:12:50-07:00

## Key Decisions Made
- Selected Project Pattern with Dual Track (Implementation Track + E2E Testing Track).
- Initial survey phase with 3 Explorers covering: (1) CDM live frames & data layer APIs, (2) WeakAuras/M33kAuras trigger states & %i formatting, (3) existing test suite, build.lua, and /wa integ framework.

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| explorer_cdm_survey_1 | teamwork_preview_explorer | Survey CDM data layer & live viewer frames | in-progress | c62f0027-2173-4d47-94a6-7a3a23b8aae8 |
| explorer_wa_binding_survey_1 | teamwork_preview_explorer | Survey WA trigger states & %i bindings | in-progress | e195e19e-a88c-4b09-8cc7-441ddb4c4b0b |
| explorer_test_build_survey_1 | teamwork_preview_spec_miner | Survey test runners, build.lua, /wa integ | in-progress | 5270c326-aa44-48a3-bcff-1460cade04d7 |

## Succession Status
- Succession required: no
- Spawn count: 3 / 16
- Pending subagents: c62f0027-2173-4d47-94a6-7a3a23b8aae8, e195e19e-a88c-4b09-8cc7-441ddb4c4b0b, 5270c326-aa44-48a3-bcff-1460cade04d7
- Predecessor: none
- Successor: not yet spawned

## Active Timers
- Heartbeat cron: task-11
- Safety timer: none
- On succession: kill all timers before spawning successor
- On context truncation: run `manage_task(Action="list")` — re-create if missing

## Artifact Index
- `C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md` — Authoritative user requirements
- `C:\Users\user\Documents\M33kAuraUtils\.agents\orchestrator_1\DISPATCH.md` — Dispatch log
- `C:\Users\user\Documents\M33kAuraUtils\.agents\orchestrator_1\BRIEFING.md` — Situational awareness working memory
- `C:\Users\user\Documents\M33kAuraUtils\.agents\orchestrator_1\progress.md` — Liveness and step checkpoint
- `C:\Users\user\Documents\M33kAuraUtils\PROJECT.md` — Global architecture, feature inventory, milestones [TBD]
