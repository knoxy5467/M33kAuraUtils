# Dispatch Log

## 2026-08-15T01:12:50Z

You are the Project Orchestrator for the M33kAuraUtils icon texture extraction and integration project.

Your working directory is: C:\Users\user\Documents\M33kAuraUtils\.agents\orchestrator_1
The project repository is: C:\Users\user\Documents\M33kAuraUtils
The original user request is documented at: C:\Users\user\Documents\M33kAuraUtils\.agents\ORIGINAL_REQUEST.md

Task Summary:
Extract and integrate rich icon texture information from Blizzard Cooldown Manager (CDM) tracked buffs, cooldowns, and live viewer frames so that WeakAuras, ThisWeeksAuras, and M33kAuras can automatically display the exact spell/buff icons on displays, dynamic text (%i), and icon bindings across all trigger states.

Key Requirements:
R1. Comprehensive Icon Resolution Engine (live frames, CDM data layer, unit aura data, native spell API, fallback).
R2. WeakAuras & M33kAuras Trigger State Icon Binding (state.icon in trigger states, display tab & %i formatters, dynamic overrides).
R3. Automated & In-Client Verification (unit tests, /wa integ step).
Acceptance Criteria:
- IsBuffActive() and IsSpellUsable() return valid, non-zero icon FileIDs/textures.
- SyncAuraState() and SyncSpellState() populate allStates[""].icon.
- Display tab bindings and %i work.
- `lua build.lua` passes all unit and integration tests with 0 failures and auto-deploys to target path.
- In-client /wa integ suite validates icon resolution step with [PASS].

## 2026-08-15T01:14:00Z

IMPORTANT DIRECTIVE UPDATE FROM USER (Appended to .agents/ORIGINAL_REQUEST.md):
Completely rip out and remove all references to C_UnitAuras / C_UnitAura across the entire codebase.
Our utils must ONLY grab buff and cooldown information directly from the Blizzard Cooldown Manager (CDM) data (C_CooldownViewer, CooldownViewerSettings, and live viewer frames BuffIconCooldownViewer, BuffBarCooldownViewer, EssentialCooldownViewer, UtilityCooldownViewer).
Do not use C_UnitAuras for buff checking, fallback, or icon resolution. All aura tracking and icon resolution must come strictly from the Blizzard CDM data and viewer frames.

