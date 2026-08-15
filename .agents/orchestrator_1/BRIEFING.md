# BRIEFING — 2026-08-14T18:16:15-07:00

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
   - **Survey Phase**: Completed (Explorers 1, 2, 3).
   - **Parallel Tracks**:
     - E2E Testing Track: E2E Test Writer building 4-tier test suite, `TEST_INFRA.md`, and `TEST_READY.md`.
     - Implementation Track: Milestone 1 (CDM Icon Resolution Engine & C_UnitAuras Purge) in progress.
3. **On failure** (in this order):
   - Retry: nudge stuck agent or re-send task
   - Replace: spawn fresh agent with partial progress
   - Skip: proceed without (only if non-critical; auditor is NEVER skipped)
   - Redistribute: split stuck agent's remaining work
   - Redesign: re-partition decomposition
4. **Succession**: Self-succeed at 16 spawns after all running subagents complete.
- **Work items**:
  1. Survey & Architecture Mapping [done]
  2. E2E Testing Suite Track [in-progress]
  3. Milestone 1: Comprehensive Icon Resolution Engine & C_UnitAuras Purge [in-progress]
  4. Milestone 2: WeakAuras & M33kAuras Trigger State Icon Binding [pending]
  5. Milestone 3: Automated & In-Client Verification & Build Integration [pending]
  6. Milestone 4: Final Acceptance & E2E Pass [pending]
- **Current phase**: 1 (Dual Track Dispatch)
- **Current focus**: Milestone 1 Explorer Reports & E2E Test Suite Creation

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
- Initial survey phase completed; PROJECT.md created with complete Feature Inventory (F1-F12) and 4 milestones + E2E track.
- Dispatched E2E Test Writer and 3 M1 Explorers in parallel.

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| explorer_cdm_survey_1 | teamwork_preview_explorer | Survey CDM data layer & live viewer frames | completed | c62f0027-2173-4d47-94a6-7a3a23b8aae8 |
| explorer_wa_binding_survey_1 | teamwork_preview_explorer | Survey WA trigger states & %i bindings | completed | e195e19e-a88c-4b09-8cc7-441ddb4c4b0b |
| explorer_test_build_survey_1 | teamwork_preview_spec_miner | Survey test runners, build.lua, /wa integ | completed | 5270c326-aa44-48a3-bcff-1460cade04d7 |
| test_writer_e2e_1 | teamwork_preview_test_writer | 4-tier E2E test suite & TEST_READY.md | in-progress | 33abe4f7-7e43-4c3c-93d4-b9889f06b54c |
| explorer_m1_engine_1 | teamwork_preview_explorer | M1 Engine ResolveAuthenticIcon design | in-progress | 1201b136-717a-4168-a989-7dcd8aad9357 |
| explorer_m1_engine_2 | teamwork_preview_explorer | M1 IsBuffActive/IsSpellUsable icon returns | in-progress | 5c9a355b-92cb-4518-80a6-1a417397a564 |
| explorer_m1_engine_3 | teamwork_preview_explorer | M1 mock harness & unit test specifications | in-progress | 5c217c32-cc0e-421f-9cba-df73bd8c257b |

## Succession Status
- Succession required: no
- Spawn count: 7 / 16
- Pending subagents: 33abe4f7-7e43-4c3c-93d4-b9889f06b54c, 1201b136-717a-4168-a989-7dcd8aad9357, 5c9a355b-92cb-4518-80a6-1a417397a564, 5c217c32-cc0e-421f-9cba-df73bd8c257b
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
- `C:\Users\user\Documents\M33kAuraUtils\PROJECT.md` — Global architecture, feature inventory, milestones
