# Handoff Report: Build Pipeline, Test Harness & Icon Resolution Survey

**Agent**: explorer_test_build_survey_1  
**Role**: Specification Miner & Test Explorer  
**Date**: 2026-08-14  
**Handoff Type**: Hard (Task Complete)  

---

## 1. Observation

1. **Build & Test Pipeline Files**:
   - `build.lua` (lines 1-3): invokes `dofile("scripts/run_tests.lua")`.
   - `scripts/run_tests.lua` (lines 1-133): orchestrates 4 sequential phases:
     - `[STEP 1/4]` TOC Validation: parses `M33kAuraUtils.toc` and verifies physical presence of 9 declared files.
     - `[STEP 2/4]` Syntax Check: executes `loadfile` across 17 Lua files.
     - `[STEP 3/4]` Unit Test Execution: executes 6 test suites via `tests/test_harness.lua` (`test_engine.lua`, `test_database.lua`, `test_ui.lua`, `test_injection.lua`, `test_integ_runner.lua`, `test_secret_access.lua`).
     - `[STEP 4/4]` Distribution Deployment: calls `Deployer.Deploy()` in `scripts/deploy.lua`.
   - `scripts/deploy.lua` (lines 47-96): reads `.env` `WOW_ADDONS_PATH=E:/World of Warcraft/_retail_/Interface/AddOns` and copies 11 distribution files to `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils`.
   - `scripts/test.bat` & `scripts/test.ps1`: CLI batch & PowerShell wrappers running `lua scripts/run_tests.lua`.

2. **Test Harness & Mock Environment**:
   - `tests/test_harness.lua` (lines 1-323): mocks `_G.GetTime`, `_G.C_Spell`, `_G.C_CooldownViewer`, `_G.Enum.CooldownViewerCategory`, `_G.BuffIconCooldownViewer`, `_G.BuffBarCooldownViewer`, `_G.EssentialCooldownViewer`, `_G.UtilityCooldownViewer`, `_G.CreateFrame`, `_G.ThisWeeksAuras`, `_G.M33kAuras`, `_G.WeakAuras`, and `_G.OptionsPrivate`.
   - `tests/test_engine.lua` (lines 16-36, 115-124): contains two legacy tests (Test 2 and Test 7) that directly set `_G.C_UnitAuras._auras[188370]` and expect `IsBuffActive` to return true.
   - When running `lua scripts/run_tests.lua`, Test 2 and Test 7 fail:
     `[FAIL] 2. Direct C_UnitAuras match returns true with stacks, duration, name, and ID: tests/test_engine.lua:26: Should return true from C_UnitAuras (Expected true, got false)`
     `[FAIL] 7. Multiple target spell inputs supported (number, string, table): tests/test_engine.lua:118: Direct number input (Expected true, got false)`

3. **In-Client Integration Test Runner**:
   - `IntegTest.lua` (lines 19-175): implements `IntegTest.RunInClientTests()` with 6 steps:
     - Step 1: Blizzard CDM API & Categories
     - Step 2: Blizzard Cooldown Viewer Global Frames
     - Step 3: CDM Tracked Buffs & Bars Enumeration
     - Step 4: CDM Essential & Utility Cooldowns Enumeration
     - Step 5: Aura Framework Detection & Options Injection
     - Step 6: Engine State Evaluation
   - `IntegTest.lua` (lines 180-213): hooks `SlashCmdList["WEAKAURAS"]`, `THISWEEKSAURAS`, and `M33KAURAS` to intercept `/wa integ`, `/twa integ`, `/m33k integ`.

4. **Icon Texture Handling in Engine & Injection**:
   - `Engine.lua` (lines 114-121): `ResolveIconTexture(icon)` currently only checks `icon.Icon:GetTexture()`. It does not yet check `icon.iconTexture`, `icon.texture`, or bar subframes.
   - `Engine.lua` (lines 124-138): `ResolveSpellDisplay(spellID, iconFrame)` queries `Spells.GetSpellInfo` and falls back to `ResolveIconTexture` or `136243`.
   - `Injection.lua` (lines 476-519, 524-563): `SyncAuraState` and `SyncSpellState` push `icon = icon or 136243` to `allStates[""].icon`.

5. **Critical User Invariant (2026-08-15)**:
   - "Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase. Our utils must ONLY grab buff and cooldown information directly from Blizzard Cooldown Manager (CDM) data... Do not use C_UnitAuras for buff checking, fallback, or icon resolution."

---

## 2. Logic Chain

1. **Build & Test Pipeline Health**:
   - Observation 1 proves the native Lua build pipeline (`build.lua` -> `run_tests.lua` -> `deploy.lua`) is fully operational on Windows, requiring only `lua` or `luajit` in PATH.
   - Step 1 and Step 2 validation pass completely (0 missing TOC files, 0 syntax errors across 17 files).
   - Step 4 deployment cleanly copies all 11 distribution files to `E:\World of Warcraft\_retail_\Interface\AddOns\M33kAuraUtils`.

2. **Root Cause of Baseline Test Failures**:
   - From Observation 2 and Observation 5, Tests 2 and 7 in `test_engine.lua` were written for a legacy model that checked `C_UnitAuras`.
   - `Engine.lua` intentionally strictly checks CDM frames and data. Thus, `IsBuffActive` correctly returns `false` when only `C_UnitAuras` is mocked.
   - Therefore, to satisfy the user invariant, `C_UnitAuras` must be removed from `test_engine.lua` and `test_harness.lua`, and replaced with pure CDM active frame and category set tests.

3. **Icon Resolution Test & Mock Requirements**:
   - From Observation 4 and R1/R2 in `ORIGINAL_REQUEST.md`, rich icon resolution requires:
     - Direct spells: `C_Spell.GetSpellInfo(id).iconID` and `GetSpellTexture(id)`.
     - Override spells: `C_CooldownViewer.GetCooldownViewerCooldownInfo(cid).overrideSpellID` / override icon.
     - Live viewer frames: supporting `.Icon:GetTexture()`, `.iconTexture`, `.texture`, and Bar frame variants.
     - Fallback: guaranteeing non-nil, non-zero FileID (136243).
     - State binding: `allStates[""].icon` populated with valid FileID / texture string in `SyncAuraState` and `SyncSpellState`.

4. **In-Client Integration Test Extension**:
   - From Observation 3 and R3 in `ORIGINAL_REQUEST.md`, `IntegTest.lua` must add Step 7 ("7. Trigger State Icon Resolution & Binding") checking `state.icon` validity on mock active buff and spell auras.
   - `tests/test_integ_runner.lua` must be updated to assert all 7 steps pass.

---

## 3. Caveats

- **No Production Code Edited**: In accordance with the Explorer archetype rules, no production code (`Engine.lua`, `Injection.lua`, `IntegTest.lua`) or test suites were modified during this turn. All changes have been specified in `analysis.md` for implementation by the Dev Ralph Loop / Lead.
- **Client WoW Runtime**: In-client execution of `/wa integ` was simulated and verified via `tests/test_integ_runner.lua` inside the mock environment. Real client verification occurs when launching World of Warcraft Retail.

---

## 4. Conclusion

1. The build pipeline (`build.lua`), TOC validator, syntax checker, and deployment script (`deploy.lua`) are completely functional.
2. The mock harness (`test_harness.lua`) provides a robust foundation but needs minor extensions:
   - Trapping / removing `C_UnitAuras`.
   - Adding `CooldownViewerSettings` DataProvider mock.
   - Supporting multi-property frame textures (`.iconTexture`, `.texture`, `.Icon:GetTexture()`).
3. Concrete test specifications have been authored in `analysis.md` covering:
   - 4 Icon Resolution test categories (Direct, Override, Live Frames, Fallback).
   - Trigger state `state.icon` binding assertions in `test_injection.lua`.
   - Step 7 in `IntegTest.lua` and `test_integ_runner.lua` updating integration step count from 6 to 7.

---

## 5. Verification Method

To verify these findings and reproduce the pipeline survey:

1. **Run Full Build & Test Runner**:
   ```powershell
   lua build.lua
   ```
   *Expected Current Output*: Step 1 (TOC) OK, Step 2 (Syntax) OK, Step 3 runs 6 suites and reports 38 Passed, 2 Failed (due to legacy `C_UnitAuras` tests in `test_engine.lua`).

2. **Inspect Survey Analysis**:
   - View `analysis.md` in `.agents/explorer_test_build_survey_1/analysis.md` for full test specifications, mock structures, and step 7 implementation details.
