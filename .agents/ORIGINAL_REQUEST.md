# Original User Request

## Initial Request — 2026-08-14T18:12:35-07:00

Extract and integrate rich icon texture information from Blizzard Cooldown Manager (CDM) tracked buffs, cooldowns, and live viewer frames so that WeakAuras, ThisWeeksAuras, and M33kAuras can automatically display the exact spell/buff icons on displays, dynamic text (%i), and icon bindings across all trigger states.

Working directory: C:\Users\user\Documents\M33kAuraUtils
Target WoW AddOns Path: E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils
Integrity mode: development

## Requirements

### R1. Comprehensive Icon Resolution Engine
Extract and resolve authentic icon texture paths/fileIDs from all available Blizzard sources:
- Active CDM live icon and bar frames (icon.Icon:GetTexture(), icon.iconTexture, icon.texture).
- Blizzard CDM data layer (C_CooldownViewer.GetCooldownViewerCooldownInfo(cid) spell/override icons).
- Unit aura data (C_UnitAuras.GetUnitAuraBySpellID("player", spellID).icon).
- Native spell API (C_Spell.GetSpellInfo(spellID).iconID and GetSpellTexture(spellID)).
Ensure fallback never returns nil or corrupted textures.

### R2. WeakAuras & M33kAuras Trigger State Icon Binding
Synchronize resolved icon textures into all trigger states for both Buff (aura2) and Spell (spell/status) triggers:
- Pass state.icon as valid FileID / Texture string into WA.GetTriggerStateForTrigger(auraId, triggernum)[""].
- Ensure display tab "Set Icon from Trigger" / "Automatic Icon" and dynamic text substitutions (%i) accurately render the spell/buff icon.
- Support icon updates when procs or overrides dynamically change the active spell icon.

### R3. Automated & In-Client Verification
- Implement unit tests verifying icon resolution for direct spells, override spells, CDM live viewer frames, and fallback cases.
- Add an in-client test step to /wa integ that checks state.icon presence and validity on mock active auras.

## Acceptance Criteria

### Icon Resolution & State Synchronization
- [ ] IsBuffActive() and IsSpellUsable() always return valid, non-zero icon FileIDs/textures for known spells.
- [ ] SyncAuraState() and SyncSpellState() populate allStates[""].icon with the resolved texture.
- [ ] Display tab icon bindings and %i text formatters in WeakAuras/M33kAuras correctly display the buff/cooldown icon.
- [ ] lua build.lua passes all unit and integration tests with 0 failures and auto-deploys to %WOW_ADDONS_PATH%/M33kAuraUtils.
- [ ] In-client /wa integ suite validates icon resolution step with [PASS].

## Follow-up — 2026-08-15T01:13:53Z

IMPORTANT DIRECTIVE UPDATE FROM USER:
Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase.
Our utils must ONLY grab buff and cooldown information directly from the Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer).
Do not use C_UnitAuras for buff checking, fallback, or icon resolution. All aura tracking and icon resolution must come strictly from the Blizzard CDM data and viewer frames.

