## 2026-08-15T01:13:10Z
You are an Explorer subagent for the M33kAuraUtils project.

Your working directory is: C:\Users\user\Documents\M33kAuraUtils\.agents\explorer_cdm_survey_1
The project repository is: C:\Users\user\Documents\M33kAuraUtils
The original request is at: C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md

Task:
Read ORIGINAL_REQUEST.md and thoroughly explore the M33kAuraUtils codebase to investigate:
1. How Blizzard Cooldown Manager (CDM) tracked buffs, cooldowns, and live viewer frames are currently accessed, indexed, or referenced.
2. The current implementation of `IsBuffActive()`, `IsSpellUsable()`, and any helper functions for resolving textures/icons.
3. How to extract authentic icon texture paths/fileIDs from:
   - Active CDM live icon and bar frames (`icon.Icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, bar frames)
   - Blizzard CDM data layer (`C_CooldownViewer.GetCooldownViewerCooldownInfo(cid)` spell/override icons)
   - Unit aura data (`C_UnitAuras.GetUnitAuraBySpellID("player", spellID).icon` or `GetAuraDataBySpellName` etc.)
   - Native spell API (`C_Spell.GetSpellInfo(spellID).iconID`, `GetSpellTexture(spellID)`)
   - Fallback mechanisms ensuring no nil or invalid/0 textures are returned.
4. Enumerate exact file paths, line ranges, function signatures, and data flows.

Write your findings to `analysis.md` and a summary handoff to `handoff.md` in your working directory.
When finished, send a message back to parent with a concise summary and path to your handoff.

## 2026-08-15T01:14:08Z
**Context**: User Directive Update (appended to ORIGINAL_REQUEST.md)
**Content**: CRITICAL INVARIANT: Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase. Our utils must ONLY grab buff and cooldown information directly from Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer). Do not use C_UnitAuras for buff checking, fallback, or icon resolution.
**Action**: Incorporate this invariant into your investigation, identify all existing C_UnitAuras usages to be eliminated, and design the CDM-only icon resolution and tracking architecture.
