# Handoff Report: WeakAuras & M33kAuras Trigger State Icon Binding Survey

**Agent**: `explorer_wa_binding_survey_1`  
**Parent Agent**: `bd6e426a-0c9d-464e-b24f-d7ff62513821`  
**Date**: 2026-08-15  
**Working Directory**: `C:\Users\user\Documents\M33kAuraUtils\.agents\explorer_wa_binding_survey_1`

---

## 1. Observation

1. **WeakAuras / M33kAuras Trigger State Structure (`allStates`)**:
   - In `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuras\M33kAuras\BuffTrigger2.lua:4463-4481` and `GenericTrigger.lua:1157-1183`, trigger states are stored per aura and triggernumber via `WA.GetTriggerStateForTrigger(id, triggernum)`.
   - Single-target / non-cloning triggers store their active state at `allStates[""]`. Clones store at `allStates[cloneId]`.
   - State updating requires setting `allStates[""].changed = true` and calling `WA.UpdatedTriggerState(auraId)` (e.g. `BuffTrigger2.lua:853-865`, `Injection.lua:513-516, 557-560`).

2. **`state.icon` Expectation & Fallbacks**:
   - In `BuffTrigger2.lua:779`, `bestMatch.icon` is assigned to `state.icon`. In `BuffTrigger2.lua:1053, 1073`, `fallbackIcon` is assigned to `state.icon`.
   - In `GenericTrigger.lua:1146`, `state.icon = icon` is assigned from `prototype.GetNameAndIcon(trigger)`. In `GenericTrigger.lua:4914, 4922`, `state.icon` is assigned from `iconFunc(trigger)`.
   - The value is expected to be a numeric texture `FileID` (e.g., `135926`, `136243`) or a string texture path.

3. **Display Tab & Dynamic Text Formatting Consumption**:
   - In `M33kAuras/RegionTypes/Icon.lua:546-558`, `region:UpdateIcon()` reads:
     - `iconSource == -1` ("Set Icon from Trigger" / "Automatic Icon"): `iconPath = self.state.icon`.
     - `iconSource > 0`: `iconPath = self.states[iconSource].icon`.
     - `iconSource == 0`: `iconPath = self.displayIcon`.
     - Calls `Private.SetTextureOrAtlas(self.icon, iconPath)`.
   - In `M33kAuras/Prototypes.lua:11214-11222`, `Private.dynamic_texts["i"]` defines:
     ```lua
     get = function(state) return state.icon or "Interface\\Icons\\INV_Misc_QuestionMark" end,
     func = function(v) return "|T".. v ..":12:12:0:0:64:64:4:60:4:60|t" end
     ```
   - In `M33kAuras/M33kAuras.lua:5345-5371`, `ReplacePlaceHolders()` and `ValueForSymbol()` evaluate `%i`, converting `state.icon` directly into inline font string textures.

4. **Dynamic Overrides and Live CDM Frames**:
   - In `M33kAuraUtils/Engine.lua:114-138`, `ResolveIconTexture(icon)` currently only checks `icon.Icon:GetTexture()` or `icon.icon:GetTexture()`.
   - In `Engine.lua:177-191`, `IsBuffActive` still contains a legacy check against `C_UnitAuras.GetUnitAuraBySpellID`, violating the Zero `C_UnitAuras` invariant.
   - In `Engine.lua:480-541`, `IsSpellUsable` resolves `name` and `icon` via `ResolveSpellDisplay(spellID, nil)` but does not pass live item frame overrides to `ResolveSpellDisplay`.

---

## 2. Logic Chain

1. **Premise**: WeakAuras Display Tab "Automatic Icon" and dynamic text `%i` formatters rely exclusively on `state.icon` within `allStates[""]` or `allStates[cloneId]`.
2. **From Observation 3**: If `state.icon` is nil or invalid, `RegionTypes/Icon.lua` falls back to `INV_Misc_QuestionMark`, and `%i` renders a question mark texture.
3. **From Observation 1 & 4**: `Injection.SyncAuraState` and `Injection.SyncSpellState` push state into `allStates[""]`. When a buff is untriggered/inactive (`show = false`), `SyncAuraState` currently sets `allStates[""] = { show = false, changed = true }` without populating `icon` or `name`. This wipes the icon on untrigger, causing Display tab icon and `%i` to lose the icon preview before the buff is applied.
4. **From Observation 4 & Dispatch Invariant**: `Engine.lua` must remove `C_UnitAuras` entirely and rely 100% on CDM live viewer frames (`BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`) and CDM data layer (`C_CooldownViewer`).
5. **From Observation 4**: `ResolveSpellDisplay(spellID, iconFrame)` and `ResolveIconTexture(iconFrame)` must prioritize live item frame textures (`icon.Icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, `icon.cooldownInfo.icon`) so dynamic talent swaps, procs, and spell replacements immediately propagate into `state.icon`.

---

## 3. Caveats

- In pure mock/headless test environments, `C_Spell.GetSpellInfo` and `C_CooldownViewer` depend on mock tables. The mock harness in `tests/test_harness.lua` must provide realistic FileIDs (e.g. `136243` fallback, non-zero IDs for known spells) and must have all `C_UnitAuras` references removed.
- In-client `/wa integ` runs in real retail client where live viewer frames may only exist if Blizzard Cooldown Manager frames are initialized by the UI. CDM Data Layer (`C_CooldownViewer`) serves as reliable fallback when frames are hidden.

---

## 4. Conclusion

1. **State Binding**: `SyncAuraState` and `SyncSpellState` in `Injection.lua` must populate `allStates[""].icon` (and `name`, `spellId`, `progressType`, `duration`, `expirationTime`, `stacks`, `charges`, `maxCharges`) on both active and inactive states.
2. **CDM-Only Buff Engine**: Remove Section A (`C_UnitAuras`) from `Engine.lua:177-191`. All buff detection must derive strictly from CDM live frames (`BuffIconCooldownViewer`, `BuffBarCooldownViewer`) and `C_CooldownViewer`.
3. **Rich Icon Resolution**: Update `ResolveIconTexture()` and `ResolveSpellDisplay()` in `Engine.lua` to extract textures from `icon.Icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, `info.overrideSpellID`, and `C_Spell.GetSpellInfo(id).iconID`.
4. **Verification**: Add icon validation step to `IntegTest.lua` (`/wa integ`) and comprehensive unit tests to `tests/test_engine.lua` and `tests/test_injection.lua`.

---

## 5. Verification Method

To independently verify all findings and test proposals:
1. **Lua Master Build & Test Suite**:
   ```powershell
   lua build.lua
   ```
   Or:
   ```powershell
   lua scripts/run_tests.lua
   ```
2. **Individual Test Suites**:
   ```powershell
   lua tests/test_engine.lua
   lua tests/test_injection.lua
   lua tests/test_integ_runner.lua
   ```
3. **Key Files for Implementation**:
   - `Engine.lua`: Lines 114–138 (`ResolveIconTexture`, `ResolveSpellDisplay`), Lines 173–236 (`IsBuffActive` - remove `C_UnitAuras`), Lines 475–555 (`IsSpellUsable`, `GetSpellCooldownState`).
   - `Injection.lua`: Lines 476–563 (`SyncAuraState`, `SyncSpellState`).
   - `Spells.lua`: Lines 9–44 (`GetSpellInfo`).
   - `IntegTest.lua`: Lines 38–175 (`RunInClientTests`).
   - `tests/test_harness.lua`, `tests/test_engine.lua`, `tests/test_injection.lua`.
