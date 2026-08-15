# BRIEFING — 2026-08-15T01:13:10Z

## Mission
Investigate WeakAuras and M33kAuras trigger state construction, update lifecycle, icon binding expectations (Buff vs Spell triggers, Display Tab "Set Icon from Trigger" / %i formatters), dynamic override handling, and identify exact file paths, functions, and missing properties for full icon binding.

## 🔒 My Identity
- Archetype: Explorer
- Roles: Read-only investigator, Codebase surveyor, Evidence synthesizer
- Working directory: C:\Users\user\Documents\M33kAuraUtils\.agents\explorer_wa_binding_survey_1
- Original parent: bd6e426a-0c9d-464e-b24f-d7ff62513821
- Milestone: Investigation & Analysis

## 🔒 Key Constraints
- Read-only investigation — do NOT implement changes in source code
- Write analysis and findings in working directory (`analysis.md`, `handoff.md`, `progress.md`)
- Provide exact file paths, line numbers, and verifiable code evidence
- Zero C_UnitAuras invariant: All buff and cooldown tracking must derive strictly from CDM data (C_CooldownViewer, CooldownViewerSettings, live frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer) without C_UnitAuras.

## Current Parent
- Conversation ID: bd6e426a-0c9d-464e-b24f-d7ff62513821
- Updated: 2026-08-15T01:14:09Z

## Investigation State
- **Explored paths**: `M33kAuraUtils` (Engine.lua, Injection.lua, Spells.lua, Core.lua, IntegTest.lua, tests/*, wiki/*), `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuras\M33kAuras` (BuffTrigger2.lua, GenericTrigger.lua, RegionTypes/Icon.lua, SubRegionTypes/SubText.lua, Prototypes.lua, M33kAuras.lua).
- **Key findings**:
  1. WeakAuras trigger states are keyed by `allStates[""]` for single triggers; `allStates[cloneId]` for clones.
  2. `state.icon` is consumed by `RegionTypes/Icon.lua` for Display Tab "Automatic Icon" (`iconSource == -1`), and by `Prototypes.lua` / `M33kAuras.lua` for dynamic text `%i` formatters (`|T<fileID>:12:12:0:0:64:64:4:60:4:60|t`).
  3. Legacy `C_UnitAuras` check in `Engine.lua:177-191` must be completely removed to enforce the Zero `C_UnitAuras` invariant.
  4. Live CDM viewer frame textures and CDM override spell IDs must take precedence in `ResolveIconTexture` / `ResolveSpellDisplay` to handle dynamic procs and talent swaps.
  5. Inactive/untriggered states in `SyncAuraState` must preserve resolved icon and name so WA options preview and `%i` formatters do not render question marks.
- **Unexplored areas**: None. Full evidence chain complete.

## Key Decisions Made
- Surveyed M33kAuraUtils and retail WeakAuras/M33kAuras implementations.
- Synthesized exact state binding points and proposed concrete changes in `analysis.md` and `handoff.md`.

## Artifact Index
- `DISPATCH.md` — incoming instructions log
- `BRIEFING.md` — persistent working memory
- `progress.md` — liveness heartbeat
- `analysis.md` — comprehensive investigation report covering all 5 prompt questions
- `handoff.md` — structured 5-component handoff report (Observation, Logic Chain, Caveats, Conclusion, Verification Method)
