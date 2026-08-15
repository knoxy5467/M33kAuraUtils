## 2026-08-15T01:13:10Z

You are an Explorer subagent for the M33kAuraUtils project.

Your working directory is: C:\Users\user\Documents\M33kAuraUtils\.agents\explorer_wa_binding_survey_1
The project repository is: C:\Users\user\Documents\M33kAuraUtils
The original request is at: C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md

Task:
Read ORIGINAL_REQUEST.md and thoroughly explore the M33kAuraUtils codebase to investigate:
1. How WeakAuras and M33kAuras trigger states are constructed and updated (`SyncAuraState()`, `SyncSpellState()`, `allStates`, `allStates[""]`, `allStates[cloneId]`).
2. Where `state.icon` is expected by WeakAuras for Buff (aura2) and Spell (spell/status) triggers.
3. How WeakAuras Display Tab "Set Icon from Trigger" / "Automatic Icon" and dynamic text formatters (`%i`) consume `state.icon` or icon FileIDs.
4. How dynamic spell overrides / procs / talent swaps that change active spell icons should be detected and propagated to trigger states.
5. Exact file paths, functions, tables, and missing properties needed to fully bind resolved icons to trigger states.

Write your findings to `analysis.md` and a summary handoff to `handoff.md` in your working directory.
When finished, send a message back to parent with a concise summary and path to your handoff.

## 2026-08-15T01:14:09Z

**Context**: User Directive Update (appended to ORIGINAL_REQUEST.md)
**Content**: CRITICAL INVARIANT: Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase. Our utils must ONLY grab buff and cooldown information directly from Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer). Do not use C_UnitAuras for buff checking, fallback, or icon resolution.
**Action**: Incorporate this invariant into your investigation of WeakAuras trigger states (`SyncAuraState`, `SyncSpellState`, `allStates[""].icon`). Ensure aura trigger state synchronization relies purely on CDM data and live viewer frames without C_UnitAuras.
