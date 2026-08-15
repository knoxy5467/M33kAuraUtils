## 2026-08-15T01:13:10Z

You are a Specification Miner & Test Explorer subagent for the M33kAuraUtils project.

Your working directory is: C:\Users\user\Documents\M33kAuraUtils\.agents\explorer_test_build_survey_1
The project repository is: C:\Users\user\Documents\M33kAuraUtils
The original request is at: C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md

Task:
Read ORIGINAL_REQUEST.md and thoroughly explore the M33kAuraUtils codebase to investigate:
1. The build and test execution pipeline (`build.lua`, test runners, CLI invocation, deployment target `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils`).
2. Existing unit test suites, test frameworks, mock Blizzard/WeakAuras APIs, and WoW environment stubs.
3. Existing in-client `/wa integ` test suite implementation, how test steps are registered and executed in WoW/WeakAuras.
4. Exactly what mock objects and test assertions need to be added for:
   - Direct spell icon resolution
   - Override spell icon resolution
   - CDM live viewer frames (icon and bar frames)
   - Fallback icon resolution
   - `SyncAuraState()` / `SyncSpellState()` populating `allStates[""].icon`
   - In-client `/wa integ` test step checking `state.icon` presence and validity on mock active auras.

Write your findings to `analysis.md` and a summary handoff to `handoff.md` in your working directory.
When finished, send a message back to parent with a concise summary and path to your handoff.

## 2026-08-15T01:14:11Z

**Context**: User Directive Update (appended to ORIGINAL_REQUEST.md)
**Content**: CRITICAL INVARIANT: Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase. Our utils must ONLY grab buff and cooldown information directly from Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer). Do not use C_UnitAuras for buff checking, fallback, or icon resolution.
**Action**: Incorporate this invariant into your test & build harness analysis. All mock frameworks, unit tests, and /wa integ steps must verify that C_UnitAuras is never invoked, and that all test assertions run purely against CDM mocks and live frames.
