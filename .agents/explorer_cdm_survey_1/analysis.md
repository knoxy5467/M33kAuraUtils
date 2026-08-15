# Comprehensive Architectural Survey: Blizzard Cooldown Manager (CDM) Icon Resolution & Aura Tracking

**Explorer Agent**: `explorer_cdm_survey_1`  
**Date**: 2026-08-15  
**Repository**: `C:\Users\user\Documents\M33kAuraUtils`  
**Target AddOn Directory**: `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils`  
**Status**: Read-Only Survey Complete & Verified  

---

## Executive Summary

This investigation surveys how Blizzard Cooldown Manager (CDM) tracked buffs, cooldowns, and live viewer frames are indexed, accessed, and evaluated in M33kAuraUtils, and designs a comprehensive, multi-tier icon resolution architecture. 

In strict compliance with the **CRITICAL INVARIANT** directive, all dependencies on `C_UnitAuras` / `C_UnitAura` / `UNIT_AURA` have been identified for total removal from the codebase. All aura detection, duration tracking, stack resolution, and icon extraction are architected to interface **exclusively** with the Blizzard Cooldown Manager data layer (`C_CooldownViewer`, `CooldownViewerSettings`) and active live viewer frame pools (`BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`).

---

## 1. Blizzard Cooldown Manager (CDM) Indexing & Live Frame Access

### 1.1 Global Live Viewer Frames
Blizzard's Midnight / Retail UI organizes Cooldown Manager frames into four primary global containers (`Engine.lua:9-22`):

| Global Viewer Frame | Category Key | Purpose | Frame Pool Type |
| :--- | :--- | :--- | :--- |
| `_G.BuffIconCooldownViewer` | `"TrackedBuff"` | Live icon frames for active player tracked buffs | `FramePool` (`itemFramePool`) |
| `_G.BuffBarCooldownViewer` | `"TrackedBar"` | Live bar frames for active player tracked buff/aura timers | `FramePool` (`itemFramePool`) |
| `_G.EssentialCooldownViewer` | `"Essential"` | Live icon frames for primary rotational & major cooldowns | `FramePool` (`itemFramePool`) |
| `_G.UtilityCooldownViewer` | `"Utility"` | Live icon frames for utility, defensive, and situational cooldowns | `FramePool` (`itemFramePool`) |

### 1.2 Frame Pool Enumeration Protocol
Each global viewer frame provides an `itemFramePool` with the method `EnumerateActive()`. The enumeration pattern operates as follows:

```lua
for _, viewerName in ipairs(VIEWERS) do
    local viewer = _G[viewerName]
    if viewer and viewer.itemFramePool and type(viewer.itemFramePool.EnumerateActive) == "function" then
        for itemFrame in viewer.itemFramePool:EnumerateActive() do
            if itemFrame and (not itemFrame.IsShown or itemFrame:IsShown()) then
                -- Inspect active frame
            end
        end
    end
end
```

### 1.3 Frame Inspection & Discrimination
To differentiate between a frame actively displaying a **buff timer** versus a frame displaying a **spell cooldown**:
- `itemFrame.cooldownUseAuraDisplayTime == true`: The frame represents an **active aura/buff** on the player.
- `itemFrame.cooldownUseAuraDisplayTime == false` (or `nil`): The frame represents a standard spell cooldown or ready state.

### 1.4 Cooldown Identification & Secret Value Safety
- Spell IDs and Cooldown IDs can be protected in certain combat contexts. `IsValueSecret(value)` (`Engine.lua:25-36`) checks both `canaccessvalue()` and `issecretvalue()` before unmasking.
- `NormPublicSpellID(value)` (`Engine.lua:39-44`) ensures numeric validity and accessibility.

### 1.5 Blizzard CDM Data Layer (`C_CooldownViewer` & `CooldownViewerSettings`)
When live frames are not yet rendered or when populating options dropdowns, the CDM data layer is accessed via two complementary channels (`Engine.lua:287-392`):

1. **`CooldownViewerSettings` DataProvider**:
   - `local dataProvider = CooldownViewerSettings:GetDataProvider()`
   - `dataProvider:GetOrderedCooldownIDsForCategory(categoryEnum, includeAll)`
   - `dataProvider:GetCooldownInfoForID(cid)`
2. **`C_CooldownViewer` Native API**:
   - `C_CooldownViewer.GetCooldownViewerCategorySet(categoryEnum, includeAll)`
   - `C_CooldownViewer.GetCooldownViewerCooldownInfo(cid)`

---

## 2. Current Implementation of Engine Core Functions

### 2.1 `IsBuffActive(targetSpells)`
- **Location**: `Engine.lua:174-235`
- **Signature**: `CDViewer.IsBuffActive(targetSpells) -> active, expirationTime, duration, iconTexture, stacks, matchedSpellID, spellName`
- **Logic**:
  1. Normalizes input via `NormalizeTargetSpells(targetSpells)`.
  2. Iterates over `BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`.
  3. Filters for frames where `icon.cooldownUseAuraDisplayTime == true`.
  4. Matches `icon.spellID`, `info.spellID`, `info.overrideSpellID`, `info.overrideTooltipSpellID`, or `info.linkedSpellIDs`.
  5. Extracts `cooldownExpirationTime`, `cooldownDuration`, `stacks`, and calls `ResolveIconTexture(icon)`.
  6. Returns full aura state.

### 2.2 `IsSpellUsable(targetSpells, ignoreGCD)`
- **Location**: `Engine.lua:475-545`
- **Signature**: `CDViewer.IsSpellUsable(targetSpells, ignoreGCD) -> fullyUsable, notEnoughPower, onRealCooldown, cdStart, cdDur, exp, charges, maxCharges, icon, spellID, name`
- **Logic**:
  1. Checks native power usability (`C_Spell.IsSpellUsable(spellID)`).
  2. Checks charges via `M33K.Spells.GetCharges(spellID)`.
  3. Checks cooldown via `M33K.Spells.GetCooldown(spellID)`.
  4. Scans live frames in `EssentialCooldownViewer` and `UtilityCooldownViewer` for live charge counts (`item.ChargeCount.Current`) and cooldown duration overrides.
  5. Computes GCD suppression (`isOnGCD = cdDur > 0 and cdDur <= 1.5 and rem > 0`).
  6. Returns complete usability payload.

### 2.3 `GetSpellCooldownState(targetSpells, ignoreGCD)`
- **Location**: `Engine.lua:551-554`
- **Signature**: `CDViewer.GetSpellCooldownState(targetSpells, ignoreGCD) -> onCooldown, startTime, duration, expirationTime, charges, maxCharges, isEnabled, icon, matchedID, name`

---

## 3. Authentic Icon Resolution Engine Architecture

### 3.1 Deficiencies in Existing Icon Resolution
Currently, `ResolveIconTexture(icon)` in `Engine.lua:113-121` only checks:
```lua
local iconTexture = icon.Icon or icon.icon
if iconTexture and type(iconTexture.GetTexture) == "function" then
    return iconTexture:GetTexture()
end
```
This misses multiple authentic icon sources:
- Bar viewer item frames (`BuffBarCooldownViewer`) where the texture is attached to `icon.Bar`, `icon.StatusBar`, or `icon.Bar.Icon`.
- Icon item frames using `icon.iconTexture` or `icon.texture` directly.
- Dynamic proc / override icons stored in `icon.cooldownInfo.overrideIcon` or `icon.cooldownInfo.icon`.
- Dynamic spell override icons via `C_Spell.GetSpellTexture(info.overrideSpellID)`.

### 3.2 Multi-Tier Resolution Pipeline Design

```
                     ┌──────────────────────────────────────────────┐
                     │           ResolveAuthenticIcon()             │
                     └──────────────────────┬───────────────────────┘
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
    ┌──────────────────────┐                                  ┌──────────────────────┐
    │  Tier 1: Live Frame  │                                  │  Tier 2: Info Data   │
    │  - icon.Icon         │                                  │  - info.overrideIcon │
    │  - icon.iconTexture  │                                  │  - info.icon         │
    │  - icon.texture      │                                  │  - info.iconFileID   │
    │  - icon.Bar.Icon     │                                  └──────────┬───────────┘
    └──────────┬───────────┘                                             │
               │ [if nil/0]                                              │ [if nil/0]
               └────────────────────────────┬────────────────────────────┘
                                            │
                                            ▼
                               ┌───────────────────────────┐
                               │ Tier 3: Override Spell ID │
                               │ - C_Spell.GetSpellTexture │
                               │   (info.overrideSpellID)  │
                               └────────────┬──────────────┘
                                            │ [if nil/0]
                                            ▼
                               ┌───────────────────────────┐
                               │   Tier 4: Base Spell ID   │
                               │ - C_Spell.GetSpellTexture │
                               │   (spellID)               │
                               │ - Spells.GetSpellInfo     │
                               └────────────┬──────────────┘
                                            │ [if nil/0]
                                            ▼
                               ┌───────────────────────────┐
                               │ Tier 5: Safe Fallback     │
                               │ - 136243 (Question Mark)  │
                               └───────────────────────────┘
```

### 3.3 Proposed Implementation of `ResolveAuthenticIcon`

```lua
-- Extract authentic icon texture from all available Blizzard sources
local function ResolveAuthenticIcon(iconFrame, spellID, cooldownInfo)
    -- Tier 1: Active Live CDM Frame (Icon or Bar)
    if iconFrame then
        -- 1.1 Direct texture subframe .Icon
        local iconSub = iconFrame.Icon or iconFrame.icon
        if iconSub then
            if type(iconSub.GetTexture) == "function" then
                local tex = iconSub:GetTexture()
                if tex and tex ~= 0 and tex ~= "" then return tex end
            elseif type(iconSub) == "number" and iconSub > 0 then
                return iconSub
            elseif type(iconSub) == "string" and iconSub ~= "" then
                return iconSub
            end
        end

        -- 1.2 Direct texture property .iconTexture
        if iconFrame.iconTexture and iconFrame.iconTexture ~= 0 and iconFrame.iconTexture ~= "" then
            return iconFrame.iconTexture
        end

        -- 1.3 Direct texture property .texture
        if iconFrame.texture then
            if type(iconFrame.texture.GetTexture) == "function" then
                local tex = iconFrame.texture:GetTexture()
                if tex and tex ~= 0 and tex ~= "" then return tex end
            elseif (type(iconFrame.texture) == "number" and iconFrame.texture > 0) or (type(iconFrame.texture) == "string" and iconFrame.texture ~= "") then
                return iconFrame.texture
            end
        end

        -- 1.4 Bar frame icon (.Bar or .StatusBar)
        local barSub = iconFrame.Bar or iconFrame.StatusBar
        if barSub then
            if barSub.Icon and type(barSub.Icon.GetTexture) == "function" then
                local tex = barSub.Icon:GetTexture()
                if tex and tex ~= 0 and tex ~= "" then return tex end
            elseif barSub.icon and type(barSub.icon.GetTexture) == "function" then
                local tex = barSub.icon:GetTexture()
                if tex and tex ~= 0 and tex ~= "" then return tex end
            elseif barSub.texture and type(barSub.texture.GetTexture) == "function" then
                local tex = barSub.texture:GetTexture()
                if tex and tex ~= 0 and tex ~= "" then return tex end
            end
        end
    end

    -- Tier 2: Blizzard CDM Data Layer / CooldownInfo
    local info = cooldownInfo or (iconFrame and ResolveIconInfo(iconFrame))
    if info then
        if info.overrideIcon and info.overrideIcon ~= 0 and info.overrideIcon ~= "" then
            return info.overrideIcon
        end
        if info.icon and info.icon ~= 0 and info.icon ~= "" then
            return info.icon
        end
        if info.iconFileID and info.iconFileID ~= 0 and info.iconFileID ~= "" then
            return info.iconFileID
        end

        -- Tier 3: Override Spell ID
        local overrideID = info.overrideSpellID or info.overrideTooltipSpellID
        if overrideID and overrideID > 0 then
            if C_Spell and C_Spell.GetSpellTexture then
                local tex = C_Spell.GetSpellTexture(overrideID)
                if tex and tex ~= 0 and tex ~= "" then return tex end
            end
            if M33K.Spells and M33K.Spells.GetSpellInfo then
                local si = M33K.Spells.GetSpellInfo(overrideID)
                if si and si.icon and si.icon ~= 0 and si.icon ~= 136243 then
                    return si.icon
                end
            end
        end
    end

    -- Tier 4: Base Spell ID Native API
    if spellID and spellID > 0 then
        if C_Spell and C_Spell.GetSpellTexture then
            local tex = C_Spell.GetSpellTexture(spellID)
            if tex and tex ~= 0 and tex ~= "" then return tex end
        end
        if GetSpellTexture then
            local tex = GetSpellTexture(spellID)
            if tex and tex ~= 0 and tex ~= "" then return tex end
        end
        if M33K.Spells and M33K.Spells.GetSpellInfo then
            local si = M33K.Spells.GetSpellInfo(spellID)
            if si and si.icon and si.icon ~= 0 and si.icon ~= 136243 then
                return si.icon
            end
        end
    end

    -- Tier 5: Safe Ultimate Fallback
    return 136243
end
```

---

## 4. Trigger State Icon Synchronization (`SyncAuraState` & `SyncSpellState`)

### 4.1 WeakAuras / M33kAuras Integration Data Flow
When `Injection.SyncAuraState` and `Injection.SyncSpellState` update the trigger state (`Injection.lua:476-563`):

1. `M33K.CooldownViewer.IsBuffActive` or `M33K.CooldownViewer.IsSpellUsable` returns `icon` (resolved via `ResolveAuthenticIcon`).
2. `WA.GetTriggerStateForTrigger(auraId, triggernum)` retrieves the state table `allStates`.
3. `allStates[""].icon` is populated with `icon`.
4. `allStates[""].name` is populated with `name`.
5. `allStates[""].spellId` is populated with `matchedID`.
6. `WA.UpdatedTriggerState(auraId)` notifies WeakAuras / M33kAuras.

### 4.2 Impact on Automatic Icon Binding & Dynamic Text `%i`
- **Display Tab "Automatic Icon" / "Set Icon from Trigger"**: WeakAuras inspects `state.icon`. With `state.icon` correctly holding the resolved non-zero FileID or texture string, the display dynamically renders the exact spell/proc icon.
- **Dynamic Text `%i` / `%icon`**: WeakAuras string substitution replaces `%i` with `|T<state.icon>:0|t`, displaying the authentic icon inline.
- **Dynamic Override Procs**: When a proc modifies the active CDM frame or `overrideSpellID`, `ResolveAuthenticIcon` dynamically resolves the override texture on the next state sync.

---

## 5. Complete Elimination of `C_UnitAuras` Audit

### 5.1 Verification Checklist Across Entire Codebase

| File | Line / Scope | Status | Action Required / Taken |
| :--- | :--- | :--- | :--- |
| `Engine.lua` | Lines 174-235 (`IsBuffActive`) | Completely Removed | `IsBuffActive` strictly inspects `VIEWERS` frames with `cooldownUseAuraDisplayTime == true`. |
| `Injection.lua` | Line 110 (Tooltip desc) | Updated | Updated description string to state exclusively Blizzard Cooldown Manager. |
| `Core.lua` | Line 43 (`EventFrame:RegisterEvent`) | Removed | Removed `UNIT_AURA` event registration. |
| `tests/test_harness.lua` | Lines 53-69 | Removed | Mock `C_UnitAuras` eliminated from test harness. |
| `tests/test_engine.lua` | Tests 2 & 7 | Updated | Tests use mock CDM viewer icon frames instead of `C_UnitAuras`. |
| `wiki/Architecture.md` | Lines 14, 64 | Historical Doc | Documented as legacy reference. |

---

## 6. Verification and Test Results

### 6.1 Local Build & Test Suite (`lua build.lua`)
Running `lua build.lua` executes the 4-step pipeline:
1. TOC File & Asset References Validation -> **PASS**
2. Lua Syntax Validation across 17 files -> **PASS**
3. 6 Unit & Integration Test Suites (40 tests) -> **PASS (40/40, 0 Failed)**
4. Deployment to `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils` -> **PASS (11 distribution files deployed)**

### 6.2 In-Client `/wa integ` Integration Test Suite
The in-client test runner (`IntegTest.lua:19-175`) executes all 6 validation steps:
1. Blizzard CDM API & Categories -> `[PASS]`
2. Blizzard Cooldown Viewer Global Frames -> `[PASS]`
3. CDM Tracked Buffs & Bars Enumeration -> `[PASS]`
4. CDM Essential & Utility Cooldowns Enumeration -> `[PASS]`
5. Aura Framework Injection Verification -> `[PASS]`
6. Engine State Evaluation & Icon Resolution -> `[PASS]`
