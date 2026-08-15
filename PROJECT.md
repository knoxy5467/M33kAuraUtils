# Project: M33kAuraUtils Icon Texture Extraction & Integration

## Architecture
M33kAuraUtils provides high-performance integration between Blizzard's Cooldown Manager (CDM) and aura frameworks (WeakAuras, ThisWeeksAuras, M33kAuras).
Data Flow:
1. **CDM Live Frames & Data Layer**: `BuffIconCooldownViewer`, `BuffBarCooldownViewer`, `EssentialCooldownViewer`, `UtilityCooldownViewer`, and `C_CooldownViewer.GetCooldownViewerCooldownInfo(cid)`.
2. **Icon Resolution Engine** (`Engine.lua`, `Spells.lua`): Multi-tier resolution (`ResolveAuthenticIcon`, `ResolveSpellDisplay`) extracting authentic texture FileIDs from live frame widgets (`icon.Icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, `icon.Bar.Icon:GetTexture()`), CDM data layer `cooldownInfo` (override icon, base icon), `C_Spell.GetSpellInfo` (override spell ID, base spell ID), and safe fallback (`136243`).
3. **Trigger State Binding** (`Injection.lua`): Injects CDM aura and cooldown tracking into WeakAuras/M33kAuras custom triggers. Populates `allStates[""].icon`, `state.icon`, `name`, `duration`, `expirationTime`, `stacks`, etc., for active and inactive states to drive "Automatic Icon" / "Set Icon from Trigger" and `%i` text formatters.
4. **Zero C_UnitAuras Invariant**: Strict architectural invariant prohibiting any usage of `C_UnitAuras` / `C_UnitAura` across production code, events, and test harnesses. Pure CDM data and frame source of truth.
5. **Testing & In-Client Verification** (`IntegTest.lua`, `tests/`, `build.lua`): Headless test harness with mock CDM frames, 4-tier E2E testing suite, and in-client `/wa integ` Step 7 validation.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F1 | Pure CDM Data & Frame Architecture | Complete purge and elimination of `C_UnitAuras`/`C_UnitAura` and `UNIT_AURA` event references; pure CDM data and live frame tracking | M1 | User Directive / Survey |
| F2 | Multi-Tier Live Frame Icon Resolution | Extract texture from `icon.Icon:GetTexture()`, `icon.iconTexture`, `icon.texture`, and bar subframes (`icon.Bar.Icon:GetTexture()`) | M1 | R1 / Survey |
| F3 | CDM Data Layer & Override Icon Extraction | Extract texture from `C_CooldownViewer.GetCooldownViewerCooldownInfo(cid).overrideIcon`, `cooldownInfo.icon`, and `cooldownInfo.overrideSpellID` | M1 | R1 / Survey |
| F4 | Native Spell API & Robust Fallback | Resolve texture via `C_Spell.GetSpellInfo` and `GetSpellTexture` with guaranteed non-nil, non-zero FileID fallback (`136243`) | M1 | R1 / Survey |
| F5 | IsBuffActive & IsSpellUsable Texture Return | Ensure `IsBuffActive` and `IsSpellUsable` always return valid, non-zero texture FileIDs/strings as their texture return value | M1 | Acceptance Criteria / Survey |
| F6 | WeakAuras/M33kAuras Trigger State Icon Synchronization | Synchronize resolved icon texture into `allStates[""].icon` and `state.icon` in `SyncAuraState` and `SyncSpellState` for active states | M2 | R2 / Survey |
| F7 | Inactive / Untriggered State Icon Preservation | Ensure `allStates[""].icon` and `name` are preserved when `show = false` so Display tab "Automatic Icon" and `%i` retain icon preview | M2 | R2 / Survey |
| F8 | Dynamic Overrides, Procs & Talent Swap Propagation | Detect dynamic texture/spell changes from CDM frames and update `state.icon` with `changed = true` | M2 | R2 / Survey |
| F9 | In-Client /wa integ Step 7 Validation | Implement Step 7 ("7. Trigger State Icon Resolution & Binding") in `IntegTest.lua` validating `state.icon` on mock active auras | M3 | R3 / Survey |
| F10 | Comprehensive Headless Unit Test Matrix | Extend `tests/test_harness.lua`, `tests/test_engine.lua`, `tests/test_injection.lua`, and `tests/test_integ_runner.lua` covering direct, override, frame variants, fallbacks, and state sync | M3 | R3 / Survey |
| F11 | Automated Build Pipeline & Auto-Deployment | Execute `lua build.lua` passing TOC validation, syntax validation, and all unit test suites with 0 failures, auto-deploying to target path | M3 | Acceptance Criteria / Survey |
| F12 | Final E2E Test Pass & Coverage Hardening | Pass 100% of 4-tier E2E test suite and adversarial coverage verification | M4 | Project Acceptance |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| E2E | E2E Testing Track | Independent 4-tier test suite (Tiers 1-4) & `TEST_INFRA.md` -> `TEST_READY.md` | none | PLANNED |
| M1 | CDM Icon Resolution Engine & C_UnitAuras Purge | Features F1, F2, F3, F4, F5 in `Engine.lua`, `Spells.lua`, `Core.lua`, `test_harness.lua` | none | PLANNED |
| M2 | WeakAuras & M33kAuras Trigger State Icon Binding | Features F6, F7, F8 in `Injection.lua` (`SyncAuraState`, `SyncSpellState`) | M1 | PLANNED |
| M3 | In-Client /wa integ Step 7 & Unit Test Integration | Features F9, F10, F11 in `IntegTest.lua`, `tests/`, `build.lua` | M1, M2 | PLANNED |
| M4 | Final Acceptance & Adversarial Hardening | Feature F12: Pass 100% E2E test suite and adversarial stress testing | M3, E2E | PLANNED |

## Interface Contracts
### Engine ↔ Injection
- `M33K.Engine.IsBuffActive(targetAura)`:
  - Returns: `active: boolean, stacks: number, duration: number, expirationTime: number, name: string, icon: number|string, spellID: number`
  - Guarantees: `icon` is never nil or 0; derived exclusively from CDM live frames or `C_CooldownViewer`.
- `M33K.Engine.IsSpellUsable(targetSpell)`:
  - Returns: `usable: boolean, start: number, duration: number, charges: number, maxCharges: number, chargeStart: number, chargeDuration: number, name: string, icon: number|string, spellID: number`
  - Guarantees: `icon` is never nil or 0; derived from live CDM frame pool, `C_CooldownViewer`, or `C_Spell`.
- `M33K.Engine.ResolveAuthenticIcon(iconFrame, spellID, cooldownInfo)`:
  - Returns: `icon: number|string` (valid texture FileID or path).

### Injection ↔ WeakAuras / M33kAuras State Engine
- `M33K.Injection.SyncAuraState(auraId, triggernum, targetAura, stateOverride)`:
  - Populates `allStates[""].icon = resolvedIcon` for both `show = true` and `show = false`.
  - Sets `allStates[""].changed = true` and calls `WA.UpdatedTriggerState(auraId)`.
- `M33K.Injection.SyncSpellState(auraId, triggernum, targetSpell, stateOverride)`:
  - Populates `allStates[""].icon = resolvedIcon` for both `show = true` and `show = false`.
  - Sets `allStates[""].changed = true` and calls `WA.UpdatedTriggerState(auraId)`.

### IntegTest ↔ Test Runner
- `M33K.IntegTest.RunInClientTests()`:
  - Executes 7 sequential steps.
  - Step 7 validates `state.icon` is non-nil and non-zero on active buff and spell states.
  - Returns: `pass: boolean, details: table`.

## Code Layout
- `Core.lua`: Addon initialization, event handling (zero `UNIT_AURA`).
- `Engine.lua`: CDM frame pool scanning, `ResolveAuthenticIcon`, `IsBuffActive`, `IsSpellUsable`.
- `Spells.lua`: Spell database and `C_Spell` texture queries.
- `Injection.lua`: WeakAuras/ThisWeeksAuras/M33kAuras options and trigger state synchronization.
- `IntegTest.lua`: In-client `/wa integ` test runner (Steps 1 to 7).
- `tests/test_harness.lua`: Headless WoW API mock environment (zero `C_UnitAuras`).
- `tests/test_engine.lua`: Unit tests for Engine and CDM resolution.
- `tests/test_injection.lua`: Unit tests for trigger state synchronization.
- `tests/test_integ_runner.lua`: Unit tests executing `IntegTest.RunInClientTests()`.
- `tests/e2e/`: 4-tier E2E testing suite.
- `build.lua`: Native Lua master build runner (`scripts/run_tests.lua`).
- `scripts/deploy.lua`: Auto-deployment to `WOW_ADDONS_PATH`.
