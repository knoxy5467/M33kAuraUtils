# Architecture & State Machine

M33kAuraUtils solves the fundamental limitation of standard WoW buff tracking when dealing with ground-placed spells.

---

## The Dual-State Tracking Problem

When a player casts a ground area-of-effect spell (such as Consecration):
1. **Ground Lifetime:** The visual zone exists on the terrain for a fixed duration (e.g., 12 seconds).
2. **Player In-Zone Aura:** While physically standing inside the zone, the player receives an aura (e.g., Spell ID 188370). Stepping out removes this aura immediately (or after a brief server tick).

### Why Standard Buff Trackers Fail
- A standard buff tracker monitors only `C_UnitAuras.GetPlayerAuraBySpellID`.
- When the player steps out of the zone to dodge a mechanic, the buff disappears. The tracker displays the aura as "Expired/Missing", even though 9 seconds remain on the ground.
- When the player steps back into the zone, the tracker suddenly reappears with the remaining time, creating jarring visual flickering and inaccurate uptime tracking.

---

## State Machine Diagram

```
                 SPELL_CAST_SUCCESS
             ┌─────────────────────────┐
             │                         ▼
      ┌──────────────┐          ┌──────────────┐
      │   EXPIRED    │          │ACTIVE_INSIDE │
      │  (State: 0)  │          │  (State: 1)  │
      └──────────────┘          └──────────────┘
             ▲                         │
             │                   Step  │  Step
    Ground   │                    Out  │  Back In
    Duration │                         ▼
    Expires  │                  ┌──────────────┐
             │                  │ACTIVE_OUTSIDE│
             └──────────────────│  (State: 2)  │
                                └──────────────┘
```

---

## State Definitions

| State Constant | Value | Description | Visual Output |
| :--- | :--- | :--- | :--- |
| `STATE_EXPIRED` | `0` | No active ground zone placed or duration has elapsed. | Dimmed icon / Hidden |
| `STATE_ACTIVE_INSIDE` | `1` | Ground zone is active AND player is inside the buff radius. | Green color, active countdown timer |
| `STATE_ACTIVE_OUTSIDE` | `2` | Ground zone is active, BUT player is standing OUTSIDE. | Red warning tint, active countdown timer |

---

## Frame Architecture & Event Pipeline

M33kAuraUtils utilizes two dedicated frames:
- **`M33kAuraUtilsEventFrame`**: Lightweight event listener frame registering core engine events (`ADDON_LOADED`, `PLAYER_LOGIN`, `COMBAT_LOG_EVENT_UNFILTERED`, `UNIT_AURA`, `PLAYER_ENTERING_WORLD`).
- **`M33kAuraUtilsMainFrame`**: Movable visual tracker UI frame managing the icon, cooldown sweep, text countdown, status bar, and unlock backdrop.

### Event Processing Pipeline:
1. **`COMBAT_LOG_EVENT_UNFILTERED`:**
   - Detects `SPELL_CAST_SUCCESS` from `playerGUID`.
   - Matches cast spell ID against known ground spells (built-in or custom).
   - Computes: `groundExpirationTime = GetTime() + spellData.defaultDuration`.
2. **`UNIT_AURA` (unit == "player"):**
   - Queries `C_UnitAuras.GetPlayerAuraBySpellID(spellData.buffSpellId)`.
   - Flags `isStandingInside = true/false`.
3. **`OnUpdate` Dispatcher (`M33kAuraUtilsMainFrame`):**
   - Computes exact remaining time: `remaining = max(0, groundExpirationTime - GetTime())`.
   - Updates UI timer text, bar progress, and dynamic alpha/color transitions smoothly each frame.
