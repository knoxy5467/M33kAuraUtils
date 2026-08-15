# Test, Build, and Harness Architecture Survey & Specification

**Project**: M33kAuraUtils  
**Target WoW Retail Path**: `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils`  
**Date**: 2026-08-14  
**Author**: Specification Miner & Test Explorer Subagent  

---

## 1. Build and Test Execution Pipeline Survey

### 1.1 Root Entry Points & Scripts
The build and test workflow is implemented in pure native Lua and script wrappers, providing cross-platform test automation without requiring external build tools like Make or Maven.

| File | Purpose | Invocation Command |
|---|---|---|
| `build.lua` | Root-level entry point that loads and executes `scripts/run_tests.lua`. | `lua build.lua` |
| `scripts/run_tests.lua` | Master runner managing the 4-phase build/test/deploy lifecycle. | `lua scripts/run_tests.lua` or `luajit scripts/run_tests.lua` |
| `scripts/test.bat` | Windows batch wrapper that detects `lua` or `luajit` in `%PATH%` and executes `run_tests.lua`. | `scripts\test.bat` |
| `scripts/test.ps1` | PowerShell wrapper setting location to project root, refreshing path, and invoking `lua scripts/run_tests.lua`. | `powershell -ExecutionPolicy Bypass -File scripts\test.ps1` |
| `scripts/deploy.lua` | Automated distribution packager & deployer copying addon files to the WoW AddOns folder. | Invoked automatically by `run_tests.lua` on test success. |

### 1.2 Pipeline Execution Lifecycle (4 Steps in `run_tests.lua`)

1. **[STEP 1/4] TOC File & Asset Validation**:
   - Parses `M33kAuraUtils.toc` line by line, stripping comments (`#...`) and metadata (`##...`).
   - Verifies the physical existence on disk for every declared Lua file (`Locales/Locales.lua`, `Spells.lua`, `Database.lua`, `Engine.lua`, `UI.lua`, `Options.lua`, `Injection.lua`, `IntegTest.lua`, `Core.lua`).
   - If any file is missing, outputs `[FAIL]` and exits with code `1`.

2. **[STEP 2/4] Lua Syntax Validation**:
   - Executes `loadfile(filePath)` across all 17 Lua files in the codebase (production files, scripts, and unit test suites).
   - Reports any parse/syntax errors with exact error messages and line numbers.
   - If any syntax error occurs, aborts with exit code `1`.

3. **[STEP 3/4] Unit Test Suite Execution**:
   - Requires `tests/test_harness.lua`.
   - Executes suites via `dofile`:
     - `tests/test_engine.lua` (Blizzard Cooldown Viewer & Aura Engine)
     - `tests/test_database.lua` (Database & Profile Settings)
     - `tests/test_ui.lua` (UI & Main Utility Frame)
     - `tests/test_injection.lua` (Options Injection & Aura Framework Hooks)
     - `tests/test_integ_runner.lua` (In-Client Integ Runner & Slash Command Hooks)
     - `tests/test_secret_access.lua` (Secret Masking & Security Fallbacks)
   - Checks summary counters: `local passed, failed = Harness.GetSummary()`.
   - If `failed > 0`, outputs `❌ Build Status: FAILED` and immediately terminates with `os.exit(1)`.

4. **[STEP 4/4] Distribution Deployment (`deploy.lua`)**:
   - Reads `.env` or system environment variable `WOW_ADDONS_PATH`.
   - Reads `.env` key `WOW_ADDONS_PATH=E:/World of Warcraft/_retail_/Interface/AddOns`.
   - Creates target subdirectories: `.../M33kAuraUtils`, `.../M33kAuraUtils/Locales`, `.../M33kAuraUtils/Media`.
   - Binary copies 11 distribution files:
     - `M33kAuraUtils.toc`
     - `Locales/Locales.lua`
     - `Spells.lua`
     - `Database.lua`
     - `Engine.lua`
     - `UI.lua`
     - `Options.lua`
     - `Injection.lua`
     - `IntegTest.lua`
     - `Core.lua`
     - `Media/logo.jpg`
   - Returns exit code `0` (`✅ Build & Deploy Status: SUCCESS`).

---

## 2. Existing Test Frameworks, Mock Environment & WoW Stubs

### 2.1 Test Harness Structure (`tests/test_harness.lua`)
`tests/test_harness.lua` establishes an in-memory Retail WoW execution sandbox:

- **Time Simulation**:
  - `currentTime = 1000.0`
  - `_G.GetTime()` returns `currentTime`.
  - `Harness.SetTime(t)` and `Harness.AdvanceTime(dt)` provide deterministic time stepping for cooldowns and aura expirations.

- **Blizzard API Stubs**:
  - `C_Spell`: `GetSpellInfo(spellId)`, `GetSpellCharges(spellId)`, `GetSpellCooldown(spellId)`, `IsSpellUsable(spellId)` backed by `_spells`, `_charges`, `_cooldowns`.
  - `C_CooldownViewer`:
    - `GetCooldownViewerCategorySet(category, includeAll)` backed by `_categorySets[1..4]`.
    - `GetCooldownViewerCooldownInfo(cid)` backed by `_cooldowns[cid]`.
  - `Enum.CooldownViewerCategory`: `Essential = 1`, `Utility = 2`, `TrackedBuff = 3`, `TrackedBar = 4`, `Buff = 3`, `Bar = 4`.
  - Global Frame Viewers: `_G.BuffIconCooldownViewer`, `_G.BuffBarCooldownViewer`, `_G.EssentialCooldownViewer`, `_G.UtilityCooldownViewer`. Each provides `itemFramePool:EnumerateActive()` returning active item frames.
  - Secret Access Protections: `_G.canaccessvalue(v)` returns `true`, `_G.issecretvalue(v)` returns `false`.
  - UI Frame Objects: `_G.CreateFrame(type, name, parent)` creates frames with full method stubs (`Show`, `Hide`, `IsShown`, `SetSize`, `GetSize`, `SetPoint`, `ClearAllPoints`, `SetScript`, `GetScript`, `FireScript`, `CreateTexture`, `CreateFontString`).
  - Texture Objects: `CreateTexture` returns mock texture objects supporting `SetTexture(path)`, `GetTexture()`, `SetVertexColor`, `GetVertexColor`, `SetTexCoord`, `SetAllPoints`.

- **Aura Framework Stubs (WeakAuras / ThisWeeksAuras / M33kAuras)**:
  - `CreateMockAuraFramework(name)` creates framework objects supporting:
    - `_auras`, `_states[auraId][triggernum]`
    - `GetTriggerStateForTrigger(auraId, triggernum)`
    - `UpdatedTriggerState(auraId)`
    - `Add(data)`
    - `ClearAndUpdateOptions(auraId)`
    - `RegisterTriggerSystemOptions(systemTypes, func)`
  - Mock `OptionsPrivate`: `GetBuffTriggerOptions(data, triggernum)`, `GetSpellTriggerOptions(data, triggernum)`.

- **Assertion API**:
  - `Harness.BeginSuite(suiteName)`
  - `Harness.RunTest(testName, fn)`
  - `Harness.Assert(cond, message)`
  - `Harness.AssertEquals(actual, expected, message)`
  - `Harness.GetSummary()` -> `passed, failed`
  - `Harness.LoadFullAddon(M33K)` -> loads all addon files in TOC sequence.

### 2.2 Suite Inventory & Current Baseline

| Suite File | Suite Name | Current Test Count | Description |
|---|---|---|---|
| `tests/test_engine.lua` | Blizzard Cooldown Viewer & Aura Engine Tests | 16 tests | Tests `IsBuffActive`, `IsSpellUsable`, `GetCDMSpellInfo`, `GetSpellCooldownState`, `EnumerateFromCDM`, `EnumerateTrackedBuffsAndBars`, `EnumerateCooldowns`, `EnumerateAll`. |
| `tests/test_database.lua` | Database & Configuration Profile Tests | 2 tests | Tests database initialization, default values, and setting set/get propagation. |
| `tests/test_ui.lua` | UI & Utility Frame Tests | 2 tests | Tests `UI.CreateMainFrame()` sizing and slash command debug toggles. |
| `tests/test_injection.lua` | Cross-Addon Injection & Cooldown Viewer Integration Tests | 12 tests | Tests Buff & Spell options injection, unit=player visibility, linked spell setters, add button, `SyncAuraState`, `SyncSpellState`, and non-spell trigger isolation. |
| `tests/test_integ_runner.lua` | In-Client Integration Test Runner & `/wa integ` Slash Hooks | 5 tests | Tests IntegTest table exposure, `RunInClientTests()` execution, `/m33k integ`, `/wa integ`, and `/twa integ` interception. |
| `tests/test_secret_access.lua` | Secret Access & Environment Security Tests | 3 tests | Tests token masking, secret reading, and mock fallback execution. |
| **Total Baseline** | | **40 tests** | |

---

## 3. In-Client `/wa integ` Test Suite Implementation (`IntegTest.lua`)

### 3.1 Test Runner Mechanism
`IntegTest.lua` implements `M33K.IntegTest.RunInClientTests()` (aliased to `_G.M33kAuraUtils.RunIntegrationTests`).
When invoked:
1. Prints header to chat: `|cFF00B4FF[M33kAuraUtils Integ]|r Starting In-Client Live Integration Tests...`
2. Uses an inner runner `RunStep(name, testFunc)` with `pcall()`.
3. If test function succeeds without error, increments `passed` and logs `|cFF00FF00[PASS]|r <step_name>`.
4. If an error is thrown, increments `failed` and logs `|cFFFF0000[FAIL]|r <step_name>: <error>`.

### 3.2 Current 6 Test Steps

1. **Step 1: Blizzard CDM API & Categories**:
   - Validates `C_CooldownViewer` exists.
   - Validates `C_CooldownViewer.GetCooldownViewerCategorySet` and `C_CooldownViewer.GetCooldownViewerCooldownInfo` are functions.
   - Validates `Enum.CooldownViewerCategory` exists.

2. **Step 2: Blizzard Cooldown Viewer Global Frames**:
   - Checks `_G.BuffIconCooldownViewer`, `_G.BuffBarCooldownViewer`, `_G.EssentialCooldownViewer`, `_G.UtilityCooldownViewer`.
   - Asserts at least one viewer frame is loaded in globals.

3. **Step 3: CDM Tracked Buffs & Bars Enumeration**:
   - Calls `M33K.CooldownViewer.EnumerateTrackedBuffsAndBars(false)` and `(true)`.
   - Validates return table and logs count.

4. **Step 4: CDM Essential & Utility Cooldowns Enumeration**:
   - Calls `M33K.CooldownViewer.EnumerateCooldowns(false)` and `(true)`.
   - Validates return table and logs count.

5. **Step 5: Aura Framework Injection Verification**:
   - Detects `ThisWeeksAuras` / `M33kAuras` / `WeakAuras`.
   - Calls `M33K.Injection.Initialize()`.
   - Checks `OptionsPrivate.GetBuffTriggerOptions` returns `cvPickerBuffsAndBars` and `cvShowAllBuffs`.
   - Checks `OptionsPrivate.GetSpellTriggerOptions` returns `cvPickerCooldowns` and `cvShowAllCooldowns`.

6. **Step 6: Engine State Evaluation**:
   - Invokes `M33K.CooldownViewer.IsSpellUsable(633)` and `M33K.CooldownViewer.IsBuffActive(188370)`.

### 3.3 Slash Command Interceptors
`IntegTest.InitializeSlashHooks()` hooks:
- `SlashCmdList["WEAKAURAS"]` (`/wa integ`, `/weakauras integ`)
- `SlashCmdList["THISWEEKSAURAS"]` (`/twa integ`, `/thisweeksauras integ`)
- `SlashCmdList["M33KAURAS"]` (`/m33k integ`, `/m33kauras integ`)

It intercepts the `integ`, `test`, or `integration` argument, executes `RunInClientTests()`, and bypasses normal WeakAuras options GUI opening. If any other argument is supplied, it falls through to the original handler.

---

## 4. Critical Architectural Invariant: Pure CDM Sources (Zero `C_UnitAuras`)

### 4.1 Directive Enforcement
Per user directive (2026-08-15):
- **Completely eliminate all usage and references to `C_UnitAuras` / `C_UnitAura` across the entire codebase.**
- Buff and cooldown information must come **exclusively** from native Blizzard Cooldown Manager (CDM) sources:
  1. `C_CooldownViewer.GetCooldownViewerCooldownInfo(cid)`
  2. `C_CooldownViewer.GetCooldownViewerCategorySet(category, includeAll)`
  3. `CooldownViewerSettings` DataProvider (`GetOrderedCooldownIDsForCategory`, `GetCooldownInfoForID`)
  4. Live viewer frame pools: `BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`.
  5. Native spell data for metadata: `C_Spell.GetSpellInfo` / `GetSpellTexture`.

### 4.2 Test Failure Root Cause in Baseline
In `tests/test_engine.lua`:
- Test 2 (`Direct C_UnitAuras match returns true with stacks, duration, name, and ID`) and Test 7 (`Multiple target spell inputs supported`) failed because they set `_G.C_UnitAuras._auras[188370]` and expected `IsBuffActive` to query `C_UnitAuras`.
- `Engine.lua` correctly omitted `C_UnitAuras` from `IsBuffActive`, so `IsBuffActive` returned `false`.
- **Action Required**:
  - Update `test_engine.lua` to remove `C_UnitAuras` tests and replace them with pure CDM active frame and category set tests.
  - Update `test_harness.lua` to remove `C_UnitAuras` or ensure attempting to use `C_UnitAuras` inside M33KAuraUtils triggers an error / assertion failure.

---

## 5. Specification of Required Mocks, Test Cases & Assertions

### 5.1 Required Mock Extensions (`tests/test_harness.lua`)

1. **`CooldownViewerSettings` DataProvider Mock**:
   - Provide `_G.CooldownViewerSettings = { GetDataProvider = function() return mockDataProvider end }`.
   - Provide `mockDataProvider:GetOrderedCooldownIDsForCategory(category, includeAll)` and `mockDataProvider:GetCooldownInfoForID(cooldownID)`.
   - Allow mock cooldown info records to have `{ spellID, overrideSpellID, overrideTooltipSpellID, iconID, isKnown, flags, cooldownDuration, cooldownExpirationTime, charges, applications }`.

2. **Live Viewer Frame Texture Variants**:
   - Support `icon.Icon` as a frame/texture table with `:GetTexture()`.
   - Support `icon.iconTexture` (direct string or FileID number).
   - Support `icon.texture` (direct string or FileID number).
   - Support `icon.Icon` as direct string/number.
   - Support Bar frames in `BuffBarCooldownViewer` with `bar.Icon:GetTexture()`, `bar.iconTexture`, and `bar.texture`.

3. **`C_Spell` & Legacy Spell Texture API Mocks**:
   - Ensure `_G.C_Spell.GetSpellInfo(spellId)` returns authentic `iconID`.
   - Ensure `_G.GetSpellTexture(spellId)` is mocked and returns the spell texture fileID.
   - Ensure `_G.GetSpellInfo(spellId)` returns `name, _, icon, castTime, minRange, maxRange, id`.

4. **Negative Mocking for `C_UnitAuras`**:
   - Stub `_G.C_UnitAuras` to either be `nil` or have a trap function that throws an error if called by M33kAuraUtils, verifying that the addon never invokes `C_UnitAuras`.

---

### 5.2 Unit Test Assertions to Add

#### Feature 1: Direct Spell Icon Resolution (CDM & Native Spell)
- **Scope**: `Engine.lua`, `Spells.lua`
- **Tests to Add**:
  - Test `Spells.GetSpellInfo(spellID)` returns `icon` as authentic non-zero FileID (e.g. 135926 for Consecration, 135875 for Avenging Wrath).
  - Test `CDViewer.GetCDMSpellInfo(spellID)` populates `.icon` with the resolved FileID.
  - Test `CDViewer.IsSpellUsable(spellID)` returns valid icon FileID at return index 9.
  - Test `CDViewer.GetSpellCooldownState(spellID)` returns valid icon FileID at return index 8.
- **Assertions**:
  - `Harness.Assert(type(icon) == "number" or type(icon) == "string", "Icon must be number FileID or texture string")`
  - `Harness.Assert(icon ~= nil and icon ~= 0 and icon ~= "", "Icon must be non-zero and non-empty")`

#### Feature 2: Override Spell Icon Resolution (Dynamic Overrides & Procs)
- **Scope**: `Engine.lua`, `Injection.lua`
- **Tests to Add**:
  - Test cooldown entry with `overrideSpellID` (e.g., Avenging Wrath 31884 -> Crusade 231895 with icon 135876).
  - Verify `CDViewer.IsBuffActive()` matches the active buff and returns the override spell's icon texture.
  - Verify `CDViewer.EnumerateFromCDM()` and `CDViewer.EnumerateAll()` resolve `entry.icon` using the override spell ID/icon.
  - Verify dynamic icon update when override changes during runtime.
- **Assertions**:
  - `Harness.AssertEquals(icon, 135876, "Must resolve override spell icon instead of base spell icon when override is active")`

#### Feature 3: CDM Live Viewer Frames (Icon & Bar Frames)
- **Scope**: `Engine.lua`
- **Tests to Add**:
  - Frame with `.Icon:GetTexture()` returning FileID.
  - Frame with `.iconTexture` property.
  - Frame with `.texture` property.
  - Bar frame in `BuffBarCooldownViewer` with `.Icon:GetTexture()`.
  - Live frame where `cooldownInfo` is missing/nil, verifying texture is extracted directly from live frame object.
- **Assertions**:
  - `Harness.AssertEquals(icon, 135926, "Icon must be extracted from live frame texture methods/properties")`

#### Feature 4: Fallback Icon Resolution
- **Scope**: `Engine.lua`, `Spells.lua`
- **Tests to Add**:
  - Query with unknown/invalid spell ID (e.g. `99999999`).
  - Query with `nil` or empty string input.
  - Query when `C_Spell.GetSpellInfo` returns `nil` and live frame has no texture.
- **Assertions**:
  - `Harness.Assert(icon ~= nil, "Fallback icon must never be nil")`
  - `Harness.Assert(icon == 136243 or type(icon) == "number", "Fallback must return valid fallback FileID 136243")`
  - `Harness.Assert(icon ~= 0 and icon ~= "", "Fallback must never return 0 or empty string")`

#### Feature 5: `SyncAuraState()` and `SyncSpellState()` Populating `allStates[""].icon`
- **Scope**: `Injection.lua`
- **Tests to Add**:
  - Test `Injection.SyncAuraState(auraId, triggernum, targetSpells)` sets `allStates[""].icon` to the resolved texture.
  - Test `Injection.SyncSpellState(auraId, triggernum, targetSpells, ignoreGCD)` sets `allStates[""].icon` to the resolved texture.
  - Test across all supported frameworks (`ThisWeeksAuras`, `M33kAuras`, `WeakAuras`).
  - Verify compatibility with WeakAuras Display Tab "Set Icon from Trigger" / "Automatic Icon" and `%i` text substitution formatters.
- **Assertions**:
  - `Harness.Assert(state.icon ~= nil, "allStates[''].icon must exist")`
  - `Harness.Assert(state.icon ~= 0 and state.icon ~= "", "allStates[''].icon must be non-zero non-empty")`
  - `Harness.AssertEquals(state.icon, expectedIcon, "allStates[''].icon must match resolved authentic texture")`

---

### 5.3 In-Client Integration Test Step 7 Specification (`IntegTest.lua`)

Add **Step 7: Trigger State Icon Resolution & Binding** to `IntegTest.RunInClientTests()`:

```lua
-- Step 7: Trigger State Icon Resolution & Binding
RunStep("7. Trigger State Icon Resolution & Binding", function()
    local fw = _G.ThisWeeksAuras or _G.M33kAuras or _G.WeakAuras
    if not fw then
        error("No Aura Framework found to verify trigger state icon", 2)
    end

    -- 1. Test Buff Trigger State Icon Synchronization
    local testBuffAuraId = "IntegTestBuffIconAura"
    local testSpellId = 188370 -- Consecration / known buff
    M33K.Injection.SyncAuraState(testBuffAuraId, 1, { [testSpellId] = true })

    local buffStates = fw.GetTriggerStateForTrigger(testBuffAuraId, 1)
    if not buffStates or not buffStates[""] then
        error("Trigger state table for buff aura was not created", 2)
    end
    local buffState = buffStates[""]
    if buffState.show then
        if not buffState.icon or buffState.icon == 0 or buffState.icon == "" then
            error(string.format("Buff trigger state.icon is invalid: %s", tostring(buffState.icon)), 2)
        end
    end

    -- 2. Test Spell Trigger State Icon Synchronization
    local testSpellAuraId = "IntegTestSpellIconAura"
    local testCDSpellId = 31884 -- Avenging Wrath / known cooldown
    M33K.Injection.SyncSpellState(testSpellAuraId, 1, { [testCDSpellId] = true }, false)

    local spellStates = fw.GetTriggerStateForTrigger(testSpellAuraId, 1)
    if not spellStates or not spellStates[""] then
        error("Trigger state table for spell aura was not created", 2)
    end
    local spellState = spellStates[""]
    if not spellState.icon or spellState.icon == 0 or spellState.icon == "" then
        error(string.format("Spell trigger state.icon is invalid: %s", tostring(spellState.icon)), 2)
    end

    return true
end)
```

In `tests/test_integ_runner.lua`, update Test 2 to assert `passed == 7, failed == 0`.

---

## 6. Discovered Features & Edge Cases Summary

### Features Discovered
| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|---|---|---|---|---|---|---|
| 1 | Build Pipeline | TOC Validator | Validates all declared files in `.toc` exist before executing builds. | `M33kAuraUtils.toc` | Boolean / Console logs | `os.exit(1)` on missing file | `scripts/run_tests.lua` |
| 2 | Build Pipeline | Syntax Checker | Verifies Lua syntax using `loadfile` on all codebase files. | 17 Lua file paths | Syntax validation status | `os.exit(1)` with syntax error msg | `scripts/run_tests.lua` |
| 3 | Build Pipeline | Distribution Deployer | Copies verified distribution files to `%WOW_ADDONS_PATH%/M33kAuraUtils`. | `.env` path & dist file list | Deployed files in WoW AddOns | Warns and skips if path undefined | `scripts/deploy.lua` |
| 4 | Test Harness | Time & Environment Mock | Sandboxes time stepping, frames, textures, CDM APIs, and aura frameworks. | Test scenario configuration | Mocked WoW environment | Throws on assertion failure | `tests/test_harness.lua` |
| 5 | Icon Resolution | Direct Spell Icon | Extracts authentic icon FileID from `C_Spell.GetSpellInfo` / `GetSpellTexture`. | `spellID` (number/string) | `iconID` (number FileID) | Falls back to 136243 | `Engine.lua`, `Spells.lua` |
| 6 | Icon Resolution | Override Spell Icon | Extracts override icon from CDM cooldownInfo or override spell data. | `cid` / `overrideSpellID` | Override `iconID` | Falls back to base spell icon | `Engine.lua` |
| 7 | Icon Resolution | Live Viewer Frame Icon | Extracts texture from `.Icon:GetTexture()`, `.iconTexture`, `.texture` across icon/bar frames. | `icon` / `bar` frame object | Texture path or FileID | Falls back to spell display lookup | `Engine.lua` |
| 8 | Icon Resolution | Safe Fallback Icon | Guarantees non-nil, non-zero icon for unknown spells and missing frames. | Unknown ID / nil | `136243` | Never returns nil, 0, or `""` | `Engine.lua`, `Spells.lua` |
| 9 | State Sync | Aura State Icon Binding | Pushes resolved icon into `allStates[""].icon` on buff trigger sync. | `auraId`, `triggernum`, target spells | Populated `allStates[""].icon` | Defaults to 136243 | `Injection.lua` |
| 10 | State Sync | Spell State Icon Binding | Pushes resolved icon into `allStates[""].icon` on spell usable / CD sync. | `auraId`, `triggernum`, target spells | Populated `allStates[""].icon` | Defaults to 136243 | `Injection.lua` |
| 11 | In-Client Integ | Slash Command Hook | Intercepts `/wa integ`, `/twa integ`, `/m33k integ` to run in-client tests. | Slash command msg string | Chat output test results | Runs original handler if not integ | `IntegTest.lua` |
| 12 | In-Client Integ | Icon State Verification Step | Step 7 in `/wa integ` validating `state.icon` presence and validity on active auras. | In-client aura framework | `[PASS] 7. Trigger State Icon Resolution` | Throws error on invalid icon | `IntegTest.lua` |

### Edge Cases Discovered
| # | Feature | Input | Observed Behavior |
|---|---|---|---|
| 1 | `IsBuffActive` | `C_UnitAuras` mock data set | Returns `false` because `Engine.lua` strictly queries CDM data only, per invariant. |
| 2 | `ResolveIconTexture` | Frame has only `.iconTexture` or `.texture` | Currently returns `nil` unless `.Icon:GetTexture()` is a function; needs enhancement for full property coverage. |
| 3 | `ResolveIconTexture` | Bar frame in `BuffBarCooldownViewer` | Bar frame texture hierarchy may differ from icon frame; needs multi-property resolution. |
| 4 | `ResolveSpellDisplay` | Spell ID is 0, negative, or secret value | Secret checker filters invalid IDs; returns fallback name and icon `136243`. |
| 5 | `SyncAuraState` | `ThisWeeksAuras` is absent but `M33kAuras` is present | Iterates all detected frameworks; successfully populates `M33kAuras.GetTriggerStateForTrigger`. |
| 6 | `/wa integ` | Empty or non-integ argument (e.g. `/wa` or `/wa show`) | Interceptor passes call through to original WeakAuras options GUI handler without interference. |
| 7 | `run_tests.lua` | Missing TOC referenced file | Step 1 detects missing file immediately and aborts before running tests or deploy. |
| 8 | `deploy.lua` | `WOW_ADDONS_PATH` missing from `.env` and environment | Skips deployment gracefully with notice rather than failing build. |

---

## 7. Next Steps & Recommendations for Implementation
1. **Enhance `tests/test_harness.lua`**:
   - Add `CooldownViewerSettings` mock.
   - Add multi-property frame texture mocks (`.iconTexture`, `.texture`, `.Icon:GetTexture()`).
   - Remove/trap `C_UnitAuras` to enforce pure CDM source invariant.
2. **Update `tests/test_engine.lua`**:
   - Replace tests 2 & 7 with pure CDM buff tests.
   - Add dedicated icon resolution tests for direct spells, override spells, CDM frames, and fallback cases.
3. **Update `tests/test_injection.lua`**:
   - Add explicit assertions that `state.icon` is a non-zero, non-nil authentic texture for both Buff and Spell states.
4. **Update `IntegTest.lua` & `tests/test_integ_runner.lua`**:
   - Add Step 7 ("7. Trigger State Icon Resolution & Binding") in `IntegTest.lua`.
   - Update `test_integ_runner.lua` to verify all 7 steps pass.
