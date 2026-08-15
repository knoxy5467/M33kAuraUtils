# WeakAuras & M33kAuras Trigger State Icon Binding & Architecture Analysis

**Investigator**: Explorer Subagent (`explorer_wa_binding_survey_1`)  
**Date**: 2026-08-15  
**Target Repository**: `C:\Users\user\Documents\M33kAuraUtils`  
**Referenced Frameworks**: `WeakAuras`, `M33kAuras` (`E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuras\M33kAuras`), `ThisWeeksAuras`  
**Critical Invariant**: Strictly CDM-based tracking (Zero `C_UnitAuras` / `C_UnitAura` across the entire codebase).

---

## Executive Summary

1. **Trigger State Structure**: WeakAuras and M33kAuras store trigger states per aura and trigger index in `allStates` tables via `WA.GetTriggerStateForTrigger(auraId, triggernum)`. For single-state triggers (standard Buff and Spell triggers), the active state is keyed by `allStates[""]`. Multi-target and cloning triggers store states keyed by numeric clone indices or GUIDs (`allStates[cloneId]`).
2. **Icon Binding Point**: Both Buff (`aura2`) and Spell (`spell`, `status`, `event`) triggers expect a valid numeric texture FileID (e.g., `135926`, `136243`) or texture path string in `state.icon`.
3. **Display Tab & Dynamic Text Consumption**:
   - **Automatic Icon ("Set Icon from Trigger")**: When `iconSource == -1`, `region:UpdateIcon()` in `RegionTypes/Icon.lua:547` directly consumes `self.state.icon`. When `iconSource > 0`, it consumes `self.states[triggernumber].icon`.
   - **Dynamic Text Formatters (`%i`)**: Defined in `Prototypes.lua:11214-11222` (`Private.dynamic_texts["i"]`), `%i` fetches `state.icon` and transforms it into the inline texture escape sequence `|T<fileID>:12:12:0:0:64:64:4:60:4:60|t`.
4. **Dynamic Overrides & Procs**: Procs, talent swaps, and spell replacements dynamically modify the texture displayed on Blizzard Cooldown Manager (CDM) live viewer frames (`icon.Icon:GetTexture()`) and the CDM data layer (`overrideSpellID`, `overrideTooltipSpellID`). Resolving live frame textures first, then CDM override spell IDs, ensures the active visual representation is always synchronized into `allStates[""].icon`.
5. **Zero `C_UnitAuras` Requirement**: All buff detection, duration, stacks, and icon resolution must strictly query CDM data structures (`BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`, `C_CooldownViewer`, and `CooldownViewerSettings`), eliminating `C_UnitAuras` entirely.

---

## 1. Trigger State Construction & Lifecycle

### 1.1 `allStates` Architecture

In WeakAuras, M33kAuras, and ThisWeeksAuras, trigger states are accessed via:
```lua
local allStates = WA.GetTriggerStateForTrigger(auraId, triggernum)
```

- **Single State (Non-cloning)**:
  ```lua
  allStates[""] = {
      show = true,             -- boolean: whether trigger is active/shown
      changed = true,          -- boolean: flags state for region re-render
      progressType = "timed",  -- "timed" | "static" | "durationObject"
      duration = dur,          -- number: total duration in seconds
      expirationTime = exp,    -- number: GetTime() timestamp when expiring
      total = dur,             -- number: total value/duration
      remaining = rem,         -- number: remaining time
      icon = iconTexture,      -- number (FileID) or string (texture path)
      stacks = stacks,         -- number: aura stacks or spell charges
      charges = charges,       -- number: current spell charges
      maxCharges = maxCharges, -- number: maximum spell charges
      spellId = matchedID,     -- number: matched spell ID
      name = spellName,        -- string: spell or buff display name
      value = stacks,          -- number: generic value
      usable = isUsable,       -- boolean: spell usability flag
      onCooldown = onCooldown, -- boolean: true if currently on cooldown
      notEnoughPower = noPower,-- boolean: true if insufficient resource
  }
  ```
- **Cloned States (Multi-target / Multi-unit)**:
  `allStates[cloneId]` where `cloneId` is `1, 2, ...` or unit GUID.

### 1.2 The State Update & Notification Cycle

When a trigger state is modified:
1. `allStates[""]` is created or modified.
2. `allStates[""].changed = true` is set.
3. The framework is notified via `WA.UpdatedTriggerState(auraId)`.
4. The region engine inspects all triggers, aggregates active states into `region.state` and `region.states[triggernum]`, and triggers:
   - `region:UpdateIcon()` (Display tab icon)
   - `region:UpdateTime()` / `region:UpdateValue()` (Cooldown sweep / status bar)
   - `region:ConfigureTextUpdate()` / `UpdateText()` (Dynamic text formatters `%p`, `%t`, `%s`, `%n`, `%i`)

---

## 2. Where `state.icon` is Expected by WeakAuras & M33kAuras

### 2.1 Buff Triggers (`aura2`)

In `M33kAuras/BuffTrigger2.lua`:
- **Active Match (`BuffTrigger2.lua:779, 862-865`)**:
  ```lua
  if hasanysecretvalues(state.icon, bestMatch.icon) or state.icon ~= bestMatch.icon then
      state.icon = bestMatch.icon
      changed = true
  end
  ```
- **Fallback / Untriggered State (`BuffTrigger2.lua:1053, 1072-1075`)**:
  ```lua
  if hasanysecretvalues(state.icon, fallbackIcon) or state.icon ~= fallbackIcon then
      state.icon = fallbackIcon
      changed = true
  end
  ```
- **Options / Tooltip Names & Icons (`BuffTrigger2.lua:4429-4433`)**:
  ```lua
  local icon = Private.ExecEnv.GetSpellIcon(spellId) or M33kAuras.spellCache.GetIcon(name)
  icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
  ```

### 2.2 Spell Triggers (`spell`, `status`, `event`)

In `M33kAuras/GenericTrigger.lua`:
- **Fake / Display Information (`GenericTrigger.lua:1141-1147`)**:
  ```lua
  if eventData.prototype and eventData.prototype.GetNameAndIcon then
      local name, icon = eventData.prototype.GetNameAndIcon(eventData.trigger)
      if state.icon == nil then
          state.icon = icon
      end
  end
  ```
- **Fallback State Creation (`GenericTrigger.lua:4912-4922`)**:
  ```lua
  local ok, icon = xpcall(event.iconFunc, Private.GetErrorHandlerUid(data.uid, L["Icon Function (fallback state)"]), trigger);
  state.icon = ok and icon or nil;
  ```

---

## 3. Display Tab Icon & Dynamic Text `%i` Consumption

### 3.1 Display Tab "Set Icon from Trigger" / "Automatic Icon"

In `M33kAuras/RegionTypes/Icon.lua:544-559`:
```lua
function region:UpdateIcon()
    local iconPath
    if self.iconSource == -1 then
        iconPath = self.state.icon
    elseif self.iconSource == 0 then
        iconPath = self.displayIcon
    else
        local triggernumber = self.iconSource
        if triggernumber and self.states[triggernumber] then
            iconPath = self.states[triggernumber].icon
        end
    end

    iconPath = iconPath or self.displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    Private.SetTextureOrAtlas(self.icon, iconPath)
end
```

| Setting in Display Tab | Value of `region.iconSource` | Source of Icon Texture |
| :--- | :--- | :--- |
| **"Automatic Icon" / "Set Icon from Trigger"** | `-1` | `self.state.icon` (from active trigger state) |
| **"Manual Icon"** | `0` | `self.displayIcon` (user-selected texture) |
| **"Trigger 1" / "Trigger N"** | `1, 2, ...` | `self.states[N].icon` |
| **Fallback (Inactive / Missing)** | Any | `self.displayIcon` or `"Interface\\Icons\\INV_Misc_QuestionMark"` |

### 3.2 Dynamic Text Formatter `%i`

In `M33kAuras/Prototypes.lua:11214-11222`:
```lua
Private.dynamic_texts["i"] = {
    get = function(state)
        if not state then return "" end
        return state.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    end,
    func = function(v)
        return "|T".. v ..":12:12:0:0:64:64:4:60:4:60|t"
    end
}
```

In `M33kAuras/M33kAuras.lua:5338-5373` (`ValueForSymbol` and `ReplacePlaceHolders`):
1. Parser identifies `%i` or `%1.i` or `%{i}`.
2. `ValueForSymbol` accesses `state.icon`.
3. `Private.dynamic_texts["i"].func(icon)` formats the texture into a WoW inline texture string:
   `|T135926:12:12:0:0:64:64:4:60:4:60|t`
4. The FontString renders the exact spell/buff graphic inline with text.

---

## 4. Dynamic Spell Overrides, Procs & Talent Swaps

When a talent swap, hero talent, or proc modifies a spell (e.g., Avenging Wrath -> Crusade, Hammer of Wrath procs, Kill Command replacements):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Dynamic Icon Resolution Hierarchy               │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
       1. Active Live CDM Viewer Frame (`itemFramePool:EnumerateActive()`)
          - `icon.Icon:GetTexture()`
          - `icon.iconTexture` / `icon.texture`
                                    │ (if nil / not on screen)
                                    ▼
       2. Blizzard CDM Data Layer (`C_CooldownViewer.GetCooldownViewerCooldownInfo`)
          - `info.overrideSpellID` -> `C_Spell.GetSpellInfo(overrideSpellID).iconID`
          - `info.overrideTooltipSpellID`
          - `info.icon`
                                    │ (if nil / not in CDM)
                                    ▼
       3. Native Spell Engine (`M33K.Spells.GetSpellInfo`)
          - `C_Spell.GetSpellInfo(spellID).iconID`
          - `C_Spell.GetSpellTexture(spellID)`
          - `GetSpellTexture(spellID)`
                                    │ (if nil / invalid)
                                    ▼
       4. Immutable Safe Fallback
          - Default icon `136243` / `"Interface\\Icons\\INV_Misc_QuestionMark"`
```

### Event Triggers for Dynamic Synchronization:
- `SPELL_UPDATE_COOLDOWN`
- `SPELL_UPDATE_CHARGES`
- `TRAIT_CONFIG_UPDATED` (Talent change)
- `SPELLS_CHANGED` (Spec/spell update)
- `ACTIONBAR_UPDATE_COOLDOWN`

---

## 5. Precise File Paths, Functions, and State Changes

### 5.1 `Engine.lua`

| Function | Current Behavior | Required Modification |
| :--- | :--- | :--- |
| `ResolveIconTexture(icon)` (Lines 114–121) | Only checks `icon.Icon` or `icon.icon` `:GetTexture()` | Expand to check `icon.Icon:GetTexture()`, `icon.icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, `icon.cooldownInfo.icon`. |
| `ResolveSpellDisplay(spellID, iconFrame)` (Lines 124–138) | Queries `M33K.Spells` first, fallback to `iconFrame` | Invert priority when `iconFrame` is provided so live overrides take precedence: Live frame texture -> `M33K.Spells.GetSpellInfo` -> `C_Spell.GetSpellTexture` -> `GetSpellTexture` -> `136243`. |
| `CDViewer.IsBuffActive(targetSpells)` (Lines 173–236) | Queries `C_UnitAuras` in Section A | **REMOVE `C_UnitAuras` COMPLETELY**. Only query CDM live viewer frames (`BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`) and CDM Data Layer (`C_CooldownViewer`). Return resolved `iconTexture`. |
| `CDViewer.IsSpellUsable(targetSpells, ignoreGCD)` (Lines 475–545) | Resolves name and icon | Returns `icon` (9th return value) directly from `ResolveSpellDisplay(spellID, item)`. |
| `CDViewer.GetSpellCooldownState(targetSpells, ignoreGCD)` (Lines 551–555) | Returns cooldown tuple | Passes `icon` as 8th return value. |

### 5.2 `Injection.lua`

| Function | Location | Required Modification |
| :--- | :--- | :--- |
| `Injection.SyncAuraState(auraId, triggernum, targetSpells)` | Lines 476–519 | 1. Query `CDViewer.IsBuffActive(targetSpells)`.<br>2. When `active == true`: set `allStates[""].icon = icon or 136243`.<br>3. When `active == false` (inactive/untrigger): retain fallback `icon = fallbackIcon or 136243`, `name = fallbackName` so WA display tab & `%i` don't break on untrigger.<br>4. Call `WA.UpdatedTriggerState(auraId)`. |
| `Injection.SyncSpellState(auraId, triggernum, targetSpells, ignoreGCD)` | Lines 524–563 | 1. Query `CDViewer.IsSpellUsable(targetSpells, ignoreGCD)`.<br>2. Populate `allStates[""].icon = icon or 136243`.<br>3. Populate `charges`, `maxCharges`, `usable`, `onCooldown`, `total`, `remaining`, `expirationTime`, `duration`, `spellId`, `name`.<br>4. Call `WA.UpdatedTriggerState(auraId)`. |

### 5.3 `Spells.lua`

| Function | Location | Required Modification |
| :--- | :--- | :--- |
| `Spells.GetSpellInfo(spellIdentifier)` | Lines 9–44 | Ensure robust icon resolution through `C_Spell.GetSpellInfo`, `C_Spell.GetSpellTexture`, and `GetSpellTexture`. Always return valid non-nil icon (fallback `136243`). |

### 5.4 `IntegTest.lua`

| Function | Location | Required Modification |
| :--- | :--- | :--- |
| `IntegTest.RunInClientTests()` | Lines 38–175 | Add Step 7: "Icon Resolution & Trigger State Binding Verification" verifying valid non-zero icon FileIDs in `IsBuffActive`, `IsSpellUsable`, `SyncAuraState`, and `SyncSpellState`. |

### 5.5 Tests (`tests/test_engine.lua`, `tests/test_injection.lua`, `tests/test_harness.lua`)

- Remove all `_G.C_UnitAuras` mocks and expectations.
- Verify that `IsBuffActive` and `SyncAuraState` function 100% via CDM live viewer frames and CDM data layer.
- Add test assertions for `state.icon` on active and fallback states.
